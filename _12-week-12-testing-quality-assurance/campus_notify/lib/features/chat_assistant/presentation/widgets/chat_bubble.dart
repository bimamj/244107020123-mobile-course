import 'package:flutter/material.dart';
import 'package:campus_notify/features/chat_assistant/domain/entities/chat_message.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message, this.onRetry});

  final ChatMessage message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.sender == MessageSender.user;
    final isFailed = message.status == MessageStatus.failed;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: isFailed
                  ? Colors.red.shade100
                  : theme.colorScheme.primaryContainer,
              child: Icon(
                isFailed ? Icons.error_outline : Icons.smart_toy_outlined,
                size: 18,
                color: isFailed
                    ? Colors.red.shade800
                    : theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary
                    : isFailed
                    ? Colors.red.shade50
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isFailed
                    ? Border.all(color: Colors.red.shade200, width: 1)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isUser
                          ? theme.colorScheme.onPrimary
                          : isFailed
                          ? Colors.red.shade900
                          : theme.colorScheme.onSurface,
                      fontSize: 14.5,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.isFromCache) ...[
                        Icon(
                          Icons.bolt,
                          size: 13,
                          color: isUser
                              ? theme.colorScheme.onPrimary.withValues(
                                  alpha: 0.7,
                                )
                              : Colors.amber.shade800,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'From cache',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isUser
                                ? theme.colorScheme.onPrimary.withValues(
                                    alpha: 0.7,
                                  )
                                : Colors.amber.shade900,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (isFailed && onRetry != null) ...[
                        InkWell(
                          onTap: onRetry,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.refresh,
                                size: 14,
                                color: Colors.red.shade700,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Tap to retry',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary.withValues(
                alpha: 0.15,
              ),
              child: Icon(
                Icons.person,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
