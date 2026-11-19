import 'package:campus_notify/features/chat_assistant/domain/entities/chat_message.dart';
import 'package:campus_notify/features/chat_assistant/domain/repositories/chat_repository.dart';

class GetChatHistory {
  const GetChatHistory(this._repository);
  final ChatRepository _repository;

  Future<List<ChatMessage>> call() => _repository.getMessages();
}
