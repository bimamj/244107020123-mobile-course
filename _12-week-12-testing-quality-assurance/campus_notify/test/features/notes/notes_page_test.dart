import 'dart:async';

import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/domain/repositories/note_repository.dart';
import 'package:campus_notify/features/notes/presentation/pages/notes_page.dart';
import 'package:campus_notify/features/notes/presentation/providers/notes_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeNoteRepository implements NoteRepository {
  FakeNoteRepository({
    List<Note> initialNotes = const [],
    this.failFetch = false,
    this.failAdd = false,
    this.fetchCompleter,
  }) : _notes = List<Note>.of(initialNotes);

  final List<Note> _notes;
  bool failFetch;
  bool failAdd;
  Completer<void>? fetchCompleter;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    if (fetchCompleter != null && !fetchCompleter!.isCompleted) {
      await fetchCompleter!.future;
    }
    if (failFetch) {
      return (
        notes: const <Note>[],
        failure: const LocalFailure('Failed to load notes'),
      );
    }
    return (notes: List<Note>.of(_notes), failure: null);
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    if (failAdd) {
      return (note: null, failure: const LocalFailure('Failed to save note'));
    }
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
  Widget buildSubject(NoteRepository repository) {
    return ProviderScope(
      overrides: [noteRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: NotesPage()),
    );
  }

  group('NotesPage', () {
    testWidgets('displays initial title, search field, FAB, and empty state', (
      tester,
    ) async {
      final repo = FakeNoteRepository();
      await tester.pumpWidget(buildSubject(repo));
      await tester.pumpAndSettle();

      expect(find.text('My Notes'), findsOneWidget);
      expect(find.byKey(const Key('notes_search_field')), findsOneWidget);
      expect(find.byKey(const Key('add_note_fab')), findsOneWidget);
      expect(find.text('No notes yet.'), findsOneWidget);
    });

    testWidgets('shows loading indicator while fetching notes', (tester) async {
      final completer = Completer<void>();
      final repo = FakeNoteRepository(fetchCompleter: completer);

      await tester.pumpWidget(buildSubject(repo));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('No notes yet.'), findsOneWidget);
    });

    testWidgets('shows error view and retries successfully', (tester) async {
      final repo = FakeNoteRepository(
        initialNotes: [
          Note(
            id: 1,
            title: 'Exam Prep',
            body: 'Week 12',
            updatedAt: DateTime(2026),
          ),
        ],
        failFetch: true,
      );

      await tester.pumpWidget(buildSubject(repo));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load notes'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      repo.failFetch = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Exam Prep'), findsOneWidget);
    });

    testWidgets('adds a new note through the dialog and displays it', (
      tester,
    ) async {
      final repo = FakeNoteRepository();
      await tester.pumpWidget(buildSubject(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add_note_fab')));
      await tester.pumpAndSettle();

      expect(find.text('New Note'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('note_title_field')),
        'Read Testing Docs',
      );
      await tester.enterText(
        find.byKey(const Key('note_body_field')),
        'Unit, widget, integration',
      );
      await tester.tap(find.byKey(const Key('save_note_button')));
      await tester.pumpAndSettle();

      expect(find.text('Read Testing Docs'), findsOneWidget);
      expect(find.text('Unit, widget, integration'), findsOneWidget);
    });

    testWidgets('shows validation SnackBar when submitting an empty title', (
      tester,
    ) async {
      final repo = FakeNoteRepository();
      await tester.pumpWidget(buildSubject(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add_note_fab')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('note_title_field')), '   ');
      await tester.tap(find.byKey(const Key('save_note_button')));
      await tester.pumpAndSettle();

      expect(find.text('Title is required'), findsOneWidget);
      expect(find.text('No notes yet.'), findsOneWidget);
    });

    testWidgets('shows error SnackBar when repository fails to save note', (
      tester,
    ) async {
      final repo = FakeNoteRepository(failAdd: true);
      await tester.pumpWidget(buildSubject(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add_note_fab')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('note_title_field')),
        'Valid Title',
      );
      await tester.tap(find.byKey(const Key('save_note_button')));
      await tester.pumpAndSettle();

      expect(find.text('Failed to save note'), findsOneWidget);
      expect(find.text('No notes yet.'), findsOneWidget);
    });
  });
}
