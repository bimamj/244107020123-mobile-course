import '../../../../core/failures.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';

/// Use case: add a note. Owns the "title is required" business rule.
class AddNote {
  const AddNote(this._repository);
  final NoteRepository _repository;

  static const maxTitleLength = 100;

  Future<({Note? note, Failure? failure})> call({
    required String title,
    String body = '',
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      return (note: null, failure: const ValidationFailure('Title is required'));
    }
    if (trimmedTitle.length > maxTitleLength) {
      return (
        note: null,
        failure: const ValidationFailure(
            'Title must be at most $maxTitleLength characters'),
      );
    }
    return _repository.addNote(title: trimmedTitle, body: body.trim());
  }
}
