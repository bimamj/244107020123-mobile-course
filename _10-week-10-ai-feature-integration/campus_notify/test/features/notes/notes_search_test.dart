import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/presentation/pages/notes_page.dart';
import 'package:campus_notify/features/notes/presentation/providers/notes_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeNotesNotifier extends NotesNotifier {
  FakeNotesNotifier(this._notes);
  final List<Note> _notes;

  @override
  Future<List<Note>> build() async => _notes;
}

void main() {
  final sampleNotes = [
    Note(id: 1, title: 'Flutter Riverpod', body: 'State mgmt', updatedAt: DateTime(2026), dirty: false),
    Note(id: 2, title: 'SQLite Database', body: 'Offline cache', updatedAt: DateTime(2026), dirty: false),
  ];

  Widget buildSubject({List<Note> notes = const []}) {
    return ProviderScope(
      overrides: [
        notesProvider.overrideWith(() => FakeNotesNotifier(notes)),
      ],
      child: const MaterialApp(home: NotesPage()),
    );
  }

  testWidgets('filters notes by title case-insensitively', (tester) async {
    await tester.pumpWidget(buildSubject(notes: sampleNotes));
    await tester.pumpAndSettle();

    expect(find.text('Flutter Riverpod'), findsOneWidget);
    expect(find.text('SQLite Database'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('notes_search_field')), 'riverpod');
    await tester.pumpAndSettle();

    expect(find.text('Flutter Riverpod'), findsOneWidget);
    expect(find.text('SQLite Database'), findsNothing);
  });

  testWidgets('shows empty search state when no notes match query', (tester) async {
    await tester.pumpWidget(buildSubject(notes: sampleNotes));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('notes_search_field')), 'Unknown');
    await tester.pumpAndSettle();

    expect(find.text('No notes found.'), findsOneWidget);
    expect(find.byIcon(Icons.search_off), findsOneWidget);
  });

  testWidgets('shows empty state when notes list has no notes', (tester) async {
    await tester.pumpWidget(buildSubject(notes: []));
    await tester.pumpAndSettle();

    expect(find.text('No notes yet.'), findsOneWidget);
    expect(find.byIcon(Icons.note_alt_outlined), findsOneWidget);
  });
}
