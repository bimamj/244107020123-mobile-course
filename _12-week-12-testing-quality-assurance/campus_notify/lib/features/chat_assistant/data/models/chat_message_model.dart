import 'package:campus_notify/features/chat_assistant/domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.text,
    required super.sender,
    required super.timestamp,
    super.status = MessageStatus.sent,
    super.errorMessage,
    super.isFromCache = false,
  });

  factory ChatMessageModel.fromEntity(ChatMessage entity) {
    return ChatMessageModel(
      id: entity.id,
      text: entity.text,
      sender: entity.sender,
      timestamp: entity.timestamp,
      status: entity.status,
      errorMessage: entity.errorMessage,
      isFromCache: entity.isFromCache,
    );
  }

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      id: map['id'] as String,
      text: map['text'] as String,
      sender: (map['sender'] as String) == 'ai'
          ? MessageSender.ai
          : MessageSender.user,
      timestamp: DateTime.parse(map['timestamp'] as String),
      status: _statusFromString(map['status'] as String? ?? 'sent'),
      errorMessage: map['error_message'] as String?,
      isFromCache: (map['is_from_cache'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'sender': sender == MessageSender.ai ? 'ai' : 'user',
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'error_message': errorMessage,
      'is_from_cache': isFromCache ? 1 : 0,
    };
  }

  static MessageStatus _statusFromString(String name) {
    return switch (name) {
      'sending' => MessageStatus.sending,
      'failed' => MessageStatus.failed,
      'cached' => MessageStatus.cached,
      _ => MessageStatus.sent,
    };
  }
}
