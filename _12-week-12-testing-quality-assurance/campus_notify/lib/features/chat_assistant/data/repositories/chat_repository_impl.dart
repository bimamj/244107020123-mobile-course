import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/chat_assistant/data/datasources/chat_local_data_source.dart';
import 'package:campus_notify/features/chat_assistant/data/datasources/chat_remote_data_source.dart';
import 'package:campus_notify/features/chat_assistant/data/models/chat_message_model.dart';
import 'package:campus_notify/features/chat_assistant/domain/entities/chat_message.dart';
import 'package:campus_notify/features/chat_assistant/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({
    required ChatLocalDataSource localDataSource,
    required ChatRemoteDataSource remoteDataSource,
    this.maxDailyRequests = 10,
  }) : _local = localDataSource,
       _remote = remoteDataSource;

  final ChatLocalDataSource _local;
  final ChatRemoteDataSource _remote;
  final int maxDailyRequests;

  String _todayDateKey() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _normalizePrompt(String text) {
    return text.trim().toLowerCase().replaceAll(RegExp(r'[\?\.\!\s]+$'), '');
  }

  @override
  Future<List<ChatMessage>> getMessages() async {
    return _local.getAllMessages();
  }

  @override
  Future<({int used, int max})> getDailyQuota() async {
    final used = await _local.getTodayUsage(_todayDateKey());
    return (used: used, max: maxDailyRequests);
  }

  @override
  Future<void> clearHistory() async {
    await _local.clearAllMessages();
  }

  @override
  Future<({ChatMessage? message, Failure? failure})> sendMessage(
    String text,
  ) async {
    final userMsgId = 'msg_${DateTime.now().millisecondsSinceEpoch}';
    final userMsg = ChatMessageModel(
      id: userMsgId,
      text: text,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );
    await _local.saveMessage(userMsg);
    return _answer(text);
  }

  /// Produces the AI reply for [text] (cache -> quota -> remote API) and
  /// stores it. The user's question must already be saved.
  Future<({ChatMessage? message, Failure? failure})> _answer(
    String text,
  ) async {
    final normalizedKey = _normalizePrompt(text);

    // 1. Check local cache first
    final cachedResponse = await _local.getCachedResponse(normalizedKey);
    if (cachedResponse != null) {
      final aiMsg = ChatMessageModel(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        text: cachedResponse,
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
        status: MessageStatus.cached,
        isFromCache: true,
      );
      await _local.saveMessage(aiMsg);
      return (message: aiMsg, failure: null);
    }

    // 2. Check daily quota limit
    final todayKey = _todayDateKey();
    final usedToday = await _local.getTodayUsage(todayKey);
    if (usedToday >= maxDailyRequests) {
      const failureMsg =
          'Daily AI request limit reached. Please try again tomorrow, or browse cached answers.';
      final failedAiMsg = ChatMessageModel(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        text: failureMsg,
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
        status: MessageStatus.failed,
        errorMessage: failureMsg,
      );
      await _local.saveMessage(failedAiMsg);
      return (message: null, failure: const ValidationFailure(failureMsg));
    }

    // 3. Call remote AI API
    try {
      final responseText = await _remote.askAI(text);

      // Cache successful response and increment daily counter
      await _local.cacheResponse(
        queryKey: normalizedKey,
        prompt: text,
        response: responseText,
      );
      await _local.incrementTodayUsage(todayKey);

      final aiMsg = ChatMessageModel(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        text: responseText,
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
      );
      await _local.saveMessage(aiMsg);
      return (message: aiMsg, failure: null);
    } on Failure catch (f) {
      final failedAiMsg = ChatMessageModel(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        text: f.message,
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
        status: MessageStatus.failed,
        errorMessage: f.message,
      );
      await _local.saveMessage(failedAiMsg);
      return (message: null, failure: f);
    } catch (_) {
      const offlineMsg =
          'Unable to reach Campus AI service. Offline mode activated. Tap to retry.';
      final failedAiMsg = ChatMessageModel(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        text: offlineMsg,
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
        status: MessageStatus.failed,
        errorMessage: offlineMsg,
      );
      await _local.saveMessage(failedAiMsg);
      return (message: null, failure: const NetworkFailure(offlineMsg));
    }
  }

  @override
  Future<({ChatMessage? message, Failure? failure})> retryMessage(
    String messageId,
  ) async {
    final history = await _local.getAllMessages();
    final failedIndex = history.indexWhere((m) => m.id == messageId);
    if (failedIndex < 0) {
      return (
        message: null,
        failure: const NotFoundFailure('Message not found.'),
      );
    }

    // The question is the closest user message before the failed AI reply.
    String? question;
    for (var i = failedIndex; i >= 0; i--) {
      if (history[i].sender == MessageSender.user) {
        question = history[i].text;
        break;
      }
    }
    if (question == null) {
      return (
        message: null,
        failure: const NotFoundFailure('Original question not found.'),
      );
    }

    // Remove the failed bubble, then ask again without duplicating the question.
    await _local.deleteMessage(messageId);
    return _answer(question);
  }
}
