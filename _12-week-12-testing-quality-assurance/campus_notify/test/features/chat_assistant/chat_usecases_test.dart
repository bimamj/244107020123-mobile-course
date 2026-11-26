import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/chat_assistant/data/datasources/chat_local_data_source.dart';
import 'package:campus_notify/features/chat_assistant/data/datasources/chat_remote_data_source.dart';
import 'package:campus_notify/features/chat_assistant/data/models/chat_message_model.dart';
import 'package:campus_notify/features/chat_assistant/data/repositories/chat_repository_impl.dart';
import 'package:campus_notify/features/chat_assistant/domain/entities/chat_message.dart';
import 'package:campus_notify/features/chat_assistant/domain/usecases/send_chat_message.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeChatLocalDataSource implements ChatLocalDataSource {
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

class FakeChatRemoteDataSource implements ChatRemoteDataSource {
  int remoteCallCount = 0;
  bool shouldThrowNetworkError = false;
  String reply = 'AI answer from cloud';

  @override
  Future<String> askAI(String prompt) async {
    remoteCallCount++;
    if (shouldThrowNetworkError) {
      throw const NetworkFailure('Server connection timed out');
    }
    return reply;
  }
}

void main() {
  late FakeChatLocalDataSource local;
  late FakeChatRemoteDataSource remote;
  late ChatRepositoryImpl repo;
  late SendChatMessage sendUseCase;

  setUp(() {
    local = FakeChatLocalDataSource();
    remote = FakeChatRemoteDataSource();
    repo = ChatRepositoryImpl(
      localDataSource: local,
      remoteDataSource: remote,
      maxDailyRequests: 2, // low quota for testing
    );
    sendUseCase = SendChatMessage(repository: repo);
  });

  group('SendChatMessage & Cache Behavior', () {
    test('calls remote AI on fresh question and caches the response', () async {
      final res = await sendUseCase('How do I join student clubs?');

      expect(res.failure, isNull);
      expect(res.message?.text, 'AI answer from cloud');
      expect(res.message?.isFromCache, isFalse);
      expect(remote.remoteCallCount, 1);

      // Verify cached in local DB
      final quota = await repo.getDailyQuota();
      expect(quota.used, 1);
    });

    test('serves repeated question from cache without calling remote API or consuming quota', () async {
      // First call
      await sendUseCase('How do I join student clubs?');
      expect(remote.remoteCallCount, 1);

      // Second call (identical or with trailing punctuation)
      final secondRes = await sendUseCase('How do I join student clubs???');

      expect(secondRes.failure, isNull);
      expect(secondRes.message?.text, 'AI answer from cloud');
      expect(secondRes.message?.isFromCache, isTrue);

      // Remote API was NOT called again
      expect(remote.remoteCallCount, 1);

      // Quota was NOT incremented again
      final quota = await repo.getDailyQuota();
      expect(quota.used, 1);
    });
  });

  group('Daily Quota Limit', () {
    test('enforces daily quota limit when requests exceed threshold', () async {
      // 1st request
      await sendUseCase('Question 1');
      // 2nd request (reaches max quota of 2)
      await sendUseCase('Question 2');

      // 3rd request should be blocked
      final blocked = await sendUseCase('Question 3');
      expect(blocked.failure, isA<ValidationFailure>());
      expect(
        blocked.failure?.message,
        contains('Daily AI request limit reached'),
      );
      expect(remote.remoteCallCount, 2);
    });
  });

  group('Error Handling & Offline Mode', () {
    test('handles remote failure gracefully by marking status failed and returning Failure', () async {
      remote.shouldThrowNetworkError = true;

      final result = await sendUseCase('Will network fail?');

      expect(result.failure, isA<NetworkFailure>());
      expect(result.message, isNull);

      final history = await repo.getMessages();
      expect(history.any((m) => m.status == MessageStatus.failed), isTrue);
    });

    test('retries previously failed message successfully', () async {
      remote.shouldThrowNetworkError = true;
      await sendUseCase('Can I retry?');

      final history = await repo.getMessages();
      final failedAi = history.firstWhere(
        (m) => m.status == MessageStatus.failed,
      );

      // Fix network and retry
      remote.shouldThrowNetworkError = false;
      final retryResult = await repo.retryMessage(failedAi.id);

      expect(retryResult.failure, isNull);
      expect(retryResult.message?.status, MessageStatus.sent);
    });
  });
}
