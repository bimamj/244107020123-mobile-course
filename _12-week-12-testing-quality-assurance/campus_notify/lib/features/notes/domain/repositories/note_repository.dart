import '../../../../core/failures.dart';
import '../entities/note.dart';

/// Contract owned by the domain; the data layer implements it (DIP).
abstract interface class NoteRepository {
  Future<({List<Note> notes, Failure? failure})> fetchNotes();
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  });
}
