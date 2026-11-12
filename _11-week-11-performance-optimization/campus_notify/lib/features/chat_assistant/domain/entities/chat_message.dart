enum MessageSender { user, ai }

enum MessageStatus { sending, sent, failed, cached }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.errorMessage,
    this.isFromCache = false,
  });

  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final MessageStatus status;
  final String? errorMessage;
  final bool isFromCache;

  ChatMessage copyWith({
    String? id,
    String? text,
    MessageSender? sender,
    DateTime? timestamp,
    MessageStatus? status,
    String? errorMessage,
    bool? isFromCache,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          text == other.text &&
          sender == other.sender &&
          status == other.status &&
          errorMessage == other.errorMessage &&
          isFromCache == other.isFromCache;

  @override
  int get hashCode =>
      id.hashCode ^
      text.hashCode ^
      sender.hashCode ^
      status.hashCode ^
      errorMessage.hashCode ^
      isFromCache.hashCode;
}
