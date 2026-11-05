import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:campus_notify/features/chat_assistant/data/models/chat_message_model.dart';

abstract interface class ChatLocalDataSource {
  Future<void> saveMessage(ChatMessageModel message);
  Future<void> updateMessage(ChatMessageModel message);
  Future<void> deleteMessage(String id);
  Future<ChatMessageModel?> getMessageById(String id);
  Future<List<ChatMessageModel>> getAllMessages();
  Future<void> clearAllMessages();

  Future<String?> getCachedResponse(String queryKey);
  Future<void> cacheResponse({
    required String queryKey,
    required String prompt,
    required String response,
  });

  Future<int> getTodayUsage(String dateKey);
  Future<void> incrementTodayUsage(String dateKey);
}

/// In-memory implementation used on Flutter Web or during tests
/// where native SQLite / FFI is unavailable.
class InMemoryChatLocalDataSource implements ChatLocalDataSource {
  final List<ChatMessageModel> _messages = [];
  final Map<String, String> _cache = {};
  final Map<String, int> _usage = {};

  @override
  Future<void> saveMessage(ChatMessageModel message) async {
    final idx = _messages.indexWhere((m) => m.id == message.id);
    if (idx >= 0) {
      _messages[idx] = message;
    } else {
      _messages.add(message);
    }
  }

  @override
  Future<void> updateMessage(ChatMessageModel message) async {
    await saveMessage(message);
  }

  @override
  Future<void> deleteMessage(String id) async {
    _messages.removeWhere((m) => m.id == id);
  }

  @override
  Future<ChatMessageModel?> getMessageById(String id) async {
    return _messages.cast<ChatMessageModel?>().firstWhere(
          (m) => m?.id == id,
          orElse: () => null,
        );
  }

  @override
  Future<List<ChatMessageModel>> getAllMessages() async => List.of(_messages);

  @override
  Future<void> clearAllMessages() async => _messages.clear();

  @override
  Future<String?> getCachedResponse(String queryKey) async => _cache[queryKey];

  @override
  Future<void> cacheResponse({
    required String queryKey,
    required String prompt,
    required String response,
  }) async {
    _cache[queryKey] = response;
  }

  @override
  Future<int> getTodayUsage(String dateKey) async => _usage[dateKey] ?? 0;

  @override
  Future<void> incrementTodayUsage(String dateKey) async {
    _usage[dateKey] = (_usage[dateKey] ?? 0) + 1;
  }
}

class SqfliteChatLocalDataSource implements ChatLocalDataSource {
  SqfliteChatLocalDataSource({Database? db}) : _injectedDb = db;

  final Database? _injectedDb;
  Future<Database>? _dbFuture;
  final _inMemoryFallback = InMemoryChatLocalDataSource();

  static const messagesTable = 'chat_messages';
  static const cacheTable = 'ai_cache';
  static const usageTable = 'daily_usage';

  Future<Database> _getDb() {
    if (_injectedDb != null) return Future.value(_injectedDb);
    return _dbFuture ??= _open();
  }

  Future<Database> _open() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final dir = await getDatabasesPath();
    return openDatabase(
      p.join(dir, 'chat_assistant.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $messagesTable (
            id TEXT PRIMARY KEY,
            text TEXT NOT NULL,
            sender TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            status TEXT NOT NULL,
            error_message TEXT,
            is_from_cache INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE $cacheTable (
            query_key TEXT PRIMARY KEY,
            prompt TEXT NOT NULL,
            response TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE $usageTable (
            usage_date TEXT PRIMARY KEY,
            count INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  @override
  Future<void> saveMessage(ChatMessageModel message) async {
    if (kIsWeb) return _inMemoryFallback.saveMessage(message);
    final db = await _getDb();
    await db.insert(
      messagesTable,
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateMessage(ChatMessageModel message) async {
    if (kIsWeb) return _inMemoryFallback.updateMessage(message);
    final db = await _getDb();
    await db.update(
      messagesTable,
      message.toMap(),
      where: 'id = ?',
      whereArgs: [message.id],
    );
  }

  @override
  Future<void> deleteMessage(String id) async {
    if (kIsWeb) return _inMemoryFallback.deleteMessage(id);
    final db = await _getDb();
    await db.delete(messagesTable, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<ChatMessageModel?> getMessageById(String id) async {
    if (kIsWeb) return _inMemoryFallback.getMessageById(id);
    final db = await _getDb();
    final rows = await db.query(
      messagesTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ChatMessageModel.fromMap(rows.first);
  }

  @override
  Future<List<ChatMessageModel>> getAllMessages() async {
    if (kIsWeb) return _inMemoryFallback.getAllMessages();
    final db = await _getDb();
    final rows = await db.query(
      messagesTable,
      orderBy: 'timestamp ASC',
    );
    return rows.map(ChatMessageModel.fromMap).toList();
  }

  @override
  Future<void> clearAllMessages() async {
    if (kIsWeb) return _inMemoryFallback.clearAllMessages();
    final db = await _getDb();
    await db.delete(messagesTable);
  }

  @override
  Future<String?> getCachedResponse(String queryKey) async {
    if (kIsWeb) return _inMemoryFallback.getCachedResponse(queryKey);
    final db = await _getDb();
    final rows = await db.query(
      cacheTable,
      columns: ['response'],
      where: 'query_key = ?',
      whereArgs: [queryKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['response'] as String?;
  }

  @override
  Future<void> cacheResponse({
    required String queryKey,
    required String prompt,
    required String response,
  }) async {
    if (kIsWeb) {
      return _inMemoryFallback.cacheResponse(
        queryKey: queryKey,
        prompt: prompt,
        response: response,
      );
    }
    final db = await _getDb();
    await db.insert(
      cacheTable,
      {
        'query_key': queryKey,
        'prompt': prompt,
        'response': response,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<int> getTodayUsage(String dateKey) async {
    if (kIsWeb) return _inMemoryFallback.getTodayUsage(dateKey);
    final db = await _getDb();
    final rows = await db.query(
      usageTable,
      columns: ['count'],
      where: 'usage_date = ?',
      whereArgs: [dateKey],
      limit: 1,
    );
    if (rows.isEmpty) return 0;
    return rows.first['count'] as int? ?? 0;
  }

  @override
  Future<void> incrementTodayUsage(String dateKey) async {
    if (kIsWeb) return _inMemoryFallback.incrementTodayUsage(dateKey);
    final db = await _getDb();
    await db.rawInsert('''
      INSERT INTO $usageTable (usage_date, count)
      VALUES (?, 1)
      ON CONFLICT(usage_date) DO UPDATE SET count = count + 1
    ''', [dateKey]);
  }
}
