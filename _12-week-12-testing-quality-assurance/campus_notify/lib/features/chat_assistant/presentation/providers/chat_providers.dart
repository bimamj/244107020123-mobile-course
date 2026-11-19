import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/core/providers.dart';
import 'package:campus_notify/features/chat_assistant/data/datasources/chat_local_data_source.dart';
import 'package:campus_notify/features/chat_assistant/data/datasources/chat_remote_data_source.dart';
import 'package:campus_notify/features/chat_assistant/data/repositories/chat_repository_impl.dart';
import 'package:campus_notify/features/chat_assistant/domain/entities/chat_message.dart';
import 'package:campus_notify/features/chat_assistant/domain/repositories/chat_repository.dart';
import 'package:campus_notify/features/chat_assistant/domain/services/sensitive_data_filter.dart';
import 'package:campus_notify/features/chat_assistant/domain/usecases/clear_chat_history.dart';
import 'package:campus_notify/features/chat_assistant/domain/usecases/get_chat_history.dart';
import 'package:campus_notify/features/chat_assistant/domain/usecases/get_daily_quota.dart';
import 'package:campus_notify/features/chat_assistant/domain/usecases/send_chat_message.dart';

const kDefaultAiApiKey = 'API_KEY_HERE'; 

// --- Data layer providers ---
final chatLocalDataSourceProvider = Provider<ChatLocalDataSource>((ref) {
  if (kIsWeb) {
    return InMemoryChatLocalDataSource();
  }
  return SqfliteChatLocalDataSource();
});

final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  final aiKeyStorage = ref.watch(aiKeyStorageProvider);

  // Ensure latest API key is saved into encrypted flutter_secure_storage
  aiKeyStorage.saveApiKey(kDefaultAiApiKey);

  // Uses its own Dio client (not apiClientProvider) so the campus session
  // token is never attached to requests sent to Google.
  return GeminiChatRemoteDataSource(
    aiKeyStorage: aiKeyStorage,
    apiKey: kDefaultAiApiKey,
  );
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(
    localDataSource: ref.watch(chatLocalDataSourceProvider),
    remoteDataSource: ref.watch(chatRemoteDataSourceProvider),
    maxDailyRequests: 10,
  );
});

// --- UseCase providers ---
final sensitiveDataFilterProvider = Provider<SensitiveDataFilter>((ref) {
  return const SensitiveDataFilter();
});

final sendChatMessageUseCaseProvider = Provider<SendChatMessage>((ref) {
  return SendChatMessage(
    repository: ref.watch(chatRepositoryProvider),
    filter: ref.watch(sensitiveDataFilterProvider),
  );
});

final getChatHistoryUseCaseProvider = Provider<GetChatHistory>((ref) {
  return GetChatHistory(ref.watch(chatRepositoryProvider));
});

final clearChatHistoryUseCaseProvider = Provider<ClearChatHistory>((ref) {
  return ClearChatHistory(ref.watch(chatRepositoryProvider));
});

final getDailyQuotaUseCaseProvider = Provider<GetDailyQuota>((ref) {
  return GetDailyQuota(ref.watch(chatRepositoryProvider));
});

// --- Presentation State Notifiers ---
class DailyQuotaNotifier extends AsyncNotifier<({int used, int max})> {
  @override
  Future<({int used, int max})> build() async {
    return ref.watch(getDailyQuotaUseCaseProvider)();
  }

  Future<void> refreshQuota() async {
    final quota = await ref.read(getDailyQuotaUseCaseProvider)();
    state = AsyncData(quota);
  }
}

final dailyQuotaProvider =
    AsyncNotifierProvider<DailyQuotaNotifier, ({int used, int max})>(
  DailyQuotaNotifier.new,
);

class ChatMessagesNotifier extends AsyncNotifier<List<ChatMessage>> {
  @override
  Future<List<ChatMessage>> build() async {
    return ref.watch(getChatHistoryUseCaseProvider)();
  }

  Future<Failure?> sendMessage(String text) async {
    final useCase = ref.read(sendChatMessageUseCaseProvider);

    // Optimistically add user message to state while processing
    final tempUserMsg = ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );

    final currentMessages = state.value ?? [];
    state = AsyncData([...currentMessages, tempUserMsg]);

    final result = await useCase(text);

    // Refresh history from local database to ensure consistent IDs and statuses
    final updatedList = await ref.read(getChatHistoryUseCaseProvider)();
    state = AsyncData(updatedList);

    // Refresh quota tracker
    ref.read(dailyQuotaProvider.notifier).refreshQuota();

    return result.failure;
  }

  Future<Failure?> retryMessage(String messageId) async {
    final repo = ref.read(chatRepositoryProvider);
    final result = await repo.retryMessage(messageId);

    final updatedList = await ref.read(getChatHistoryUseCaseProvider)();
    state = AsyncData(updatedList);
    ref.read(dailyQuotaProvider.notifier).refreshQuota();

    return result.failure;
  }

  Future<void> clearHistory() async {
    await ref.read(clearChatHistoryUseCaseProvider)();
    state = const AsyncData([]);
  }
}

final chatMessagesProvider =
    AsyncNotifierProvider<ChatMessagesNotifier, List<ChatMessage>>(
  ChatMessagesNotifier.new,
);


