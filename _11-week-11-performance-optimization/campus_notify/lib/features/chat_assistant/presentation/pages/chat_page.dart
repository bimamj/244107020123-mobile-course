import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/core/providers.dart';
import 'package:campus_notify/features/chat_assistant/domain/entities/chat_message.dart';
import 'package:campus_notify/features/chat_assistant/presentation/providers/chat_providers.dart';
import 'package:campus_notify/features/chat_assistant/presentation/widgets/chat_bubble.dart';
import 'package:campus_notify/features/chat_assistant/presentation/widgets/chat_input_bar.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _scrollController = ScrollController();
  bool _isSending = false;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend(String text) async {
    setState(() => _isSending = true);
    _scrollToBottom();

    final failure =
        await ref.read(chatMessagesProvider.notifier).sendMessage(text);

    if (mounted) {
      setState(() => _isSending = false);
      _scrollToBottom();

      if (failure != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: failure is ValidationFailure
                ? Colors.orange.shade800
                : Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            action: failure is NetworkFailure
                ? SnackBarAction(
                    label: 'Retry',
                    textColor: Colors.white,
                    onPressed: () => _handleSend(text),
                  )
                : null,
          ),
        );
      }
    }
  }

  Future<void> _handleRetry(ChatMessage msg) async {
    setState(() => _isSending = true);
    final failure =
        await ref.read(chatMessagesProvider.notifier).retryMessage(msg.id);

    if (mounted) {
      setState(() => _isSending = false);
      _scrollToBottom();

      if (failure != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmClearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Chat History?'),
        content: const Text(
          'This will delete all saved conversation messages from your device. Cached knowledge will remain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(chatMessagesProvider.notifier).clearHistory();
    }
  }

  /// Manages API Key with proper lifecycle and memory leak prevention
  Future<void> _manageApiKey() async {
    final aiKeyStorage = ref.read(aiKeyStorageProvider);
    final currentKey = (await aiKeyStorage.readApiKey()) ?? '';
    final controller = TextEditingController(text: currentKey);

    if (!mounted) {
      controller.dispose();
      return;
    }

    try {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('AI API Key Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your API key is stored securely in encrypted flutter_secure_storage.',
                style: TextStyle(fontSize: 12.5, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Google Gemini API Key',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final newKey = controller.text.trim();
                await aiKeyStorage.saveApiKey(newKey);
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('API Key saved to secure storage.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    } finally {
      // Prevent memory leak: always dispose controller on dialog dismiss
      controller.dispose();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Campus AI Assistant',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            _ChatQuotaSubtitle(),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.key_outlined),
            tooltip: 'API Key Settings',
            onPressed: _manageApiKey,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear History',
            onPressed: _confirmClearHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          // Optimization: Extracted const privacy tip banner
          const ChatPrivacyBanner(),

          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Failed to load messages: $err',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return ChatEmptyState(onSuggestionTap: _handleSend);
                }

                return RepaintBoundary(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return ChatBubble(
                        key: ValueKey(msg.id),
                        message: msg,
                        onRetry: msg.status == MessageStatus.failed
                            ? () => _handleRetry(msg)
                            : null,
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // Optimization: RepaintBoundary on active text input to isolate cursor repaints
          RepaintBoundary(
            child: ChatInputBar(
              onSend: _handleSend,
              isLoading: _isSending,
            ),
          ),
        ],
      ),
    );
  }
}

/// Extracted widget to isolate quota rebuilds from the entire chat page
class _ChatQuotaSubtitle extends ConsumerWidget {
  const _ChatQuotaSubtitle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final quotaAsync = ref.watch(dailyQuotaProvider);

    return quotaAsync.when(
      data: (quota) => Text(
        'Daily Quota: ${quota.used}/${quota.max} used',
        style: TextStyle(
          fontSize: 11,
          color: quota.used >= quota.max
              ? Colors.red
              : theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Extracted static privacy banner with const constructor
class ChatPrivacyBanner extends StatelessWidget {
  const ChatPrivacyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
      child: Row(
        children: [
          Icon(
            Icons.shield_outlined,
            size: 15,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sensitive data is sanitized. Repeated queries use local cache.',
              style: TextStyle(
                fontSize: 11.5,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Extracted empty state widget
class ChatEmptyState extends StatelessWidget {
  const ChatEmptyState({super.key, required this.onSuggestionTap});

  final ValueChanged<String> onSuggestionTap;

  static const List<String> _suggestions = [
    'How do I check announcements?',
    'Where are my notes stored?',
    'Campus Wi-Fi guide',
    'Library opening hours',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.smart_toy_outlined,
                size: 38,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'How can I help you today?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask any questions about campus announcements, schedules, or study notes.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _suggestions.map((s) {
                return ActionChip(
                  label: Text(s, style: const TextStyle(fontSize: 12.5)),
                  onPressed: () => onSuggestionTap(s),
                  avatar: const Icon(Icons.help_outline, size: 14),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
