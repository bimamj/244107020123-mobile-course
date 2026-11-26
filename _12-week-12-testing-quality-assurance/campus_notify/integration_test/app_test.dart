import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/core/messaging/push_notification_service.dart';
import 'package:campus_notify/core/providers.dart';
import 'package:campus_notify/core/storage/token_storage.dart';
import 'package:campus_notify/features/auth/presentation/providers/auth_providers.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/domain/repositories/note_repository.dart';
import 'package:campus_notify/features/notes/presentation/providers/notes_providers.dart';
import 'package:campus_notify/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

class _InMemoryTokenStorage implements TokenStorage {
  String? _access;
  String? _refresh;

  @override
  Future<void> clear() async {
    _access = null;
    _refresh = null;
  }

  @override
  Future<String?> readAccess() async => _access;

  @override
  Future<String?> readRefresh() async => _refresh;

  @override
  Future<void> save({required String access, required String refresh}) async {
    _access = access;
    _refresh = refresh;
  }
}

class _InMemoryNoteRepository implements NoteRepository {
  final List<Note> _notes = [];

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    return (notes: List<Note>.of(_notes), failure: null);
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    final note = Note(
      id: _notes.length + 1,
      title: title,
      body: body,
      updatedAt: DateTime(2026),
      dirty: true,
    );
    _notes.insert(0, note);
    return (note: note, failure: null);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('user logs in, navigates to notes, adds and searches a note', (
    tester,
  ) async {
    final tokenStorage = _InMemoryTokenStorage();
    final noteRepo = _InMemoryNoteRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pushNotificationServiceProvider.overrideWithValue(
            const NoopPushNotificationService(),
          ),
          tokenStorageProvider.overrideWithValue(tokenStorage),
          tokenRefresherProvider.overrideWith(
            (ref) => ref.watch(authRemoteDataSourceProvider),
          ),
          noteRepositoryProvider.overrideWithValue(noteRepo),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Login flow
    expect(find.text('Login'), findsWidgets);
    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      'student@polinema.ac.id',
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      'password123',
    );
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    // 2. Home screen -> navigate to My Notes
    expect(find.text('Home'), findsOneWidget);
    await tester.tap(find.byKey(const Key('home_notes_button')));
    await tester.pumpAndSettle();

    // 3. Notes screen -> add a note
    expect(find.text('My Notes'), findsOneWidget);
    await tester.tap(find.byKey(const Key('add_note_fab')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('note_title_field')),
      'Week 12 QA Lab',
    );
    await tester.enterText(
      find.byKey(const Key('note_body_field')),
      'Complete unit, widget, and integration tests',
    );
    await tester.tap(find.byKey(const Key('save_note_button')));
    await tester.pumpAndSettle();

    expect(find.text('Week 12 QA Lab'), findsOneWidget);
    expect(
      find.text('Complete unit, widget, and integration tests'),
      findsOneWidget,
    );

    // 4. Filter notes with search
    await tester.enterText(
      find.byKey(const Key('notes_search_field')),
      'Week 12',
    );
    await tester.pumpAndSettle();
    expect(find.text('Week 12 QA Lab'), findsOneWidget);
  });
}
