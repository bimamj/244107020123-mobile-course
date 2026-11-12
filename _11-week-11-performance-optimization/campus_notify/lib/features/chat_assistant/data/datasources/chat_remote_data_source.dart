import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/core/storage/ai_key_storage.dart';

abstract interface class ChatRemoteDataSource {
  Future<String> askAI(String prompt);
}

class GeminiChatRemoteDataSource implements ChatRemoteDataSource {
  GeminiChatRemoteDataSource({
    Dio? client,
    this.aiKeyStorage,
    this.apiKey,
    this.baseUrl = 'https://generativelanguage.googleapis.com/v1beta',
  }) : _client = client ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 45),
            ));

  /// Dedicated client: must NOT be the app's campus API client, otherwise the
  /// user's campus session token would be attached to requests sent to Google.
  final Dio _client;
  final AiKeyStorage? aiKeyStorage;
  final String? apiKey;
  final String baseUrl;

  /// Current Gemini models, in order of preference.
  static const _preferredModels = [
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-flash-latest',
    'gemini-2.5-flash-lite',
  ];

  /// Model picked for this key, remembered so ListModels is called only once.
  String? _resolvedModel;

  static const _systemPrompt =
      'You are a helpful campus assistant for the Campus Notify mobile app. '
      'Answer concisely and informatively for university students and staff.';

  Future<String?> _resolveApiKey() async {
    final storedKey = await aiKeyStorage?.readApiKey();
    if (storedKey != null && storedKey.trim().isNotEmpty) {
      return storedKey.trim();
    }
    if (apiKey != null && apiKey!.trim().isNotEmpty) {
      return apiKey!.trim();
    }
    return null;
  }

  Options _headers(String key) => Options(headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': key,
      });

  @override
  Future<String> askAI(String prompt) async {
    final key = await _resolveApiKey();

    if (key == null || key.isEmpty) {
      // No key configured: answer from the built-in campus knowledge base.
      await Future.delayed(const Duration(milliseconds: 600));
      return _generateCampusAssistantResponse(prompt);
    }

    final candidates = <String>[
      if (_resolvedModel != null) _resolvedModel!,
      ...await _discoverModels(key),
      ..._preferredModels,
    ].toSet().toList();

    DioException? lastNotFound;
    for (final model in candidates) {
      try {
        final text = await _generate(model, prompt, key);
        _resolvedModel = model;
        return text;
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          debugPrint('Gemini model $model not available for this key, trying next.');
          lastNotFound = e;
          if (_resolvedModel == model) _resolvedModel = null;
          continue;
        }
        throw _mapError(e);
      }
    }

    throw AuthFailure(
      'No Gemini model is available for this API key '
      '(${_serverMessage(lastNotFound) ?? "404"}). '
      'Create a key at aistudio.google.com/app/apikey.',
    );
  }

  Future<String> _generate(String model, String prompt, String key) async {
    final response = await _client.post(
      '$baseUrl/models/$model:generateContent',
      options: _headers(key),
      data: {
        'systemInstruction': {
          'parts': [
            {'text': _systemPrompt}
          ]
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt}
            ]
          }
        ],
      },
    );

    final candidates = response.data['candidates'] as List?;
    if (candidates != null && candidates.isNotEmpty) {
      final parts = candidates.first['content']?['parts'] as List?;
      final text = parts
          ?.map((p) => p['text'])
          .whereType<String>()
          .join()
          .trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return 'The AI could not generate an answer for that question.';
  }

  /// Asks Google which models this key may use (ModelService.ListModels).
  /// Returns preferred flash models first. Returns an empty list if listing
  /// is not possible, so the caller can still try the default model names.
  Future<List<String>> _discoverModels(String key) async {
    if (_resolvedModel != null) return const [];
    try {
      final res = await _client.get('$baseUrl/models', options: _headers(key));
      final models = (res.data['models'] as List?) ?? const [];
      final usable = <String>[
        for (final m in models)
          if (((m['supportedGenerationMethods'] as List?) ?? const [])
              .contains('generateContent'))
            (m['name'] as String).replaceFirst('models/', ''),
      ];
      final preferred =
          _preferredModels.where(usable.contains).toList();
      final otherFlash = usable
          .where((m) => m.contains('flash') && !preferred.contains(m))
          .toList();
      return [...preferred, ...otherFlash];
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 400 || status == 401 || status == 403) throw _mapError(e);
      if (e.response == null) throw _mapError(e); // no network at all
      return const [];
    }
  }

  String? _serverMessage(DioException? e) {
    final data = e?.response?.data;
    if (data is Map) return data['error']?['message']?.toString();
    return null;
  }

  Failure _mapError(DioException e) {
    final status = e.response?.statusCode;
    final message = _serverMessage(e);
    debugPrint('Gemini API error: status=$status, message=$message');

    if (status == 400 || status == 401 || status == 403) {
      return AuthFailure('AI key problem ($status): ${message ?? "API key rejected."}');
    }
    if (status == 429) {
      return const NetworkFailure(
        'AI usage limit reached. Please wait a moment and try again.',
      );
    }
    if (e.response == null) {
      return const NetworkFailure(
        'No connection to the AI service. Offline mode: saved answers are still available.',
      );
    }
    return NetworkFailure(
      'The AI service is having problems ($status). Please try again later.',
    );
  }

  String _generateCampusAssistantResponse(String prompt) {
    final lower = prompt.toLowerCase();
    if (lower.contains('announcement') || lower.contains('notif')) {
      return 'You can check latest university announcements in the Home tab. High-priority broadcasts will also trigger push notifications on your device.';
    }
    if (lower.contains('note') || lower.contains('catatan')) {
      return 'You can create, search, and manage your course notes locally in the "My Notes" section. All notes are saved on your device using SQLite.';
    }
    if (lower.contains('exam') || lower.contains('jadwal') || lower.contains('schedule')) {
      return 'Midterm and final exam schedules are published through official faculty announcements. Be sure to check the announcement details regularly.';
    }
    if (lower.contains('wifi') || lower.contains('internet')) {
      return 'Campus Wi-Fi requires your student credentials (SSID: Campus-Student). If you experience connection drops, report it to the IT Helpdesk.';
    }
    if (lower.contains('library') || lower.contains('perpustakaan')) {
      return 'The Central Campus Library is open Monday to Friday, 08:00 - 18:00. You can borrow up to 3 books simultaneously using your digital Student ID.';
    }
    return 'Campus AI Assistant: I received your question: "$prompt". I am here to help you with campus information, announcements, academic guidelines, and your personal notes.';
  }
}
