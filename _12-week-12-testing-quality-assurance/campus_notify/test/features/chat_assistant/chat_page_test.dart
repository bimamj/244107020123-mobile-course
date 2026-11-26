import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/chat_assistant/domain/entities/chat_message.dart';
import 'package:campus_notify/features/chat_assistant/presentation/pages/chat_page.dart';
import 'package:campus_notify/features/chat_assistant/presentation/providers/chat_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeChatNotifier extends ChatMessagesNotifier {
  FakeChatNotifier(this._initial);
  final List<ChatMessage> _initial;
  bool shouldFail = false;

  @override
  Future<List<ChatMessage>> build() async => _initial;

  @override
  Future<Failure?> sendMessage(String text) async {
    if (shouldFail) {
      return const NetworkFailure('Unable to reach Campus AI service.');
    }
    final userMsg = ChatMessage(
      id: 'u_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );
    final aiMsg = ChatMessage(
      id: 'a_${DateTime.now().millisecondsSinceEpoch}',
      text: 'Echo: $text',
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
    );
    state = AsyncData([...state.value ?? [], userMsg, aiMsg]);
    return null;
  }
}

class FakeQuotaNotifier extends DailyQuotaNotifier {
  @override
  Future<({int used, int max})> build() async => (used: 3, max: 10);
}

void main() {
  Widget buildSubject({List<ChatMessage> messages = const []}) {
    return ProviderScope(
      overrides: [
        chatMessagesProvider.overrideWith(() => FakeChatNotifier(messages)),
        dailyQuotaProvider.overrideWith(() => FakeQuotaNotifier()),
      ],
      child: const MaterialApp(home: ChatPage()),
    );
  }

  testWidgets('renders empty state with suggestion chips', (tester) async {
    await tester.pumpWidget(buildSubject(messages: []));
    await tester.pumpAndSettle();

    expect(find.text('Campus AI Assistant'), findsOneWidget);
    expect(find.text('How can I help you today?'), findsOneWidget);
    expect(find.text('Daily Quota: 3/10 used'), findsOneWidget);
    expect(find.text('How do I check announcements?'), findsOneWidget);
  });

  testWidgets('renders user and AI messages and handles cached indicator', (
    tester,
  ) async {
    final messages = [
      ChatMessage(
        id: '1',
        text: 'Where are notes saved?',
        sender: MessageSender.user,
        timestamp: DateTime.now(),
      ),
      ChatMessage(
        id: '2',
        text: 'Notes are saved locally on your phone in SQLite.',
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
        isFromCache: true,
      ),
    ];

    await tester.pumpWidget(buildSubject(messages: messages));
    await tester.pumpAndSettle();

    expect(find.text('Where are notes saved?'), findsOneWidget);
    expect(
      find.text('Notes are saved locally on your phone in SQLite.'),
      findsOneWidget,
    );
    expect(find.text('From cache'), findsOneWidget);
  });

  testWidgets('renders retry button when message status is failed', (
    tester,
  ) async {
    final messages = [
      ChatMessage(
        id: '1',
        text: 'Connection dropped. Tap to retry.',
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
        status: MessageStatus.failed,
        errorMessage: 'Connection dropped.',
      ),
    ];

    await tester.pumpWidget(buildSubject(messages: messages));
    await tester.pumpAndSettle();

    expect(find.text('Connection dropped. Tap to retry.'), findsOneWidget);
    expect(find.text('Tap to retry'), findsOneWidget);
  });
}
