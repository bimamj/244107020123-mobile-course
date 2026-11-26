import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/chat_assistant/domain/entities/chat_message.dart';

abstract interface class ChatRepository {
  /// Sends a user question to AI (or returns from local cache).
  Future<({ChatMessage? message, Failure? failure})> sendMessage(String text);

  /// Retrieves full local conversation history.
  Future<List<ChatMessage>> getMessages();

  /// Gets daily usage quota: count of external AI requests made today and maximum allowed.
  Future<({int used, int max})> getDailyQuota();

  /// Clears user conversation history.
  Future<void> clearHistory();

  /// Retries sending a previously failed message.
  Future<({ChatMessage? message, Failure? failure})> retryMessage(
    String messageId,
  );
}
