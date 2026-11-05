import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/domain/repositories/note_repository.dart';
import 'package:campus_notify/features/notes/domain/usecases/add_note.dart';
import 'package:campus_notify/features/notes/domain/usecases/get_notes.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory fake: possible only because use cases depend on the
/// NoteRepository ABSTRACTION (DIP / LSP).
class FakeNoteRepository implements NoteRepository {
  final List<Note> _notes = [];
  bool failNext = false;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    if (failNext) return (notes: const <Note>[], failure: const LocalFailure('db down'));
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
    _notes.add(note);
    return (note: note, failure: null);
  }
}

void main() {
  late FakeNoteRepository repo;

  setUp(() => repo = FakeNoteRepository());

  group('AddNote', () {
    test('rejects an empty title without touching the repository', () async {
      final result = await AddNote(repo)(title: '   ');
      expect(result.note, isNull);
      expect(result.failure, isA<ValidationFailure>());
      expect((await repo.fetchNotes()).notes, isEmpty);
    });

    test('trims input and saves the note', () async {
      final result = await AddNote(repo)(title: '  Quiz  ', body: ' ch.3 ');
      expect(result.failure, isNull);
      expect(result.note?.title, 'Quiz');
      expect(result.note?.body, 'ch.3');
    });
  });

  group('GetNotes', () {
    test('returns stored notes', () async {
      await AddNote(repo)(title: 'A');
      final result = await GetNotes(repo)();
      expect(result.notes.map((n) => n.title), ['A']);
    });

    test('propagates repository failures', () async {
      repo.failNext = true;
      final result = await GetNotes(repo)();
      expect(result.failure, isA<LocalFailure>());
    });
  });
}
