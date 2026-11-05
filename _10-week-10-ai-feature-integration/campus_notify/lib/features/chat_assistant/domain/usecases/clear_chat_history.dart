import 'package:campus_notify/features/chat_assistant/domain/repositories/chat_repository.dart';

class ClearChatHistory {
  const ClearChatHistory(this._repository);
  final ChatRepository _repository;

  Future<void> call() => _repository.clearHistory();
}
