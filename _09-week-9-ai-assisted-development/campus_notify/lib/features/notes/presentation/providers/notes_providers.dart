import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/failures.dart';
import '../../data/datasources/notes_database.dart';
import '../../data/repositories/note_repository_impl.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/usecases/add_note.dart';
import '../../domain/usecases/get_notes.dart';

// Data layer: the database opener is injected (easy to fake in tests)
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepositoryImpl(openDb: openNotesDb);
});

// Domain layer: the use cases receive an abstraction, not an impl
final getNotesProvider = Provider<GetNotes>((ref) {
  return GetNotes(ref.watch(noteRepositoryProvider));
});

final addNoteProvider = Provider<AddNote>((ref) {
  return AddNote(ref.watch(noteRepositoryProvider));
});

// Presentation layer: state for the UI
final notesSearchQueryProvider =
    NotifierProvider<NotesSearchQueryNotifier, String>(
        NotesSearchQueryNotifier.new);

class NotesSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final filteredNotesProvider = Provider<AsyncValue<List<Note>>>((ref) {
  final query = ref.watch(notesSearchQueryProvider).trim().toLowerCase();
  return ref.watch(notesProvider).whenData(
        (notes) => query.isEmpty
            ? notes
            : notes.where((n) => n.title.toLowerCase().contains(query)).toList(),
      );
});

final notesProvider =
    AsyncNotifierProvider<NotesNotifier, List<Note>>(NotesNotifier.new);

class NotesNotifier extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() async {
    final result = await ref.watch(getNotesProvider).call();
    final failure = result.failure;
    if (failure != null) throw failure;
    return result.notes;
  }

  /// Returns a [Failure] for the UI to display, or `null` on success.
  Future<Failure?> add({required String title, String body = ''}) async {
    final result =
        await ref.read(addNoteProvider).call(title: title, body: body);
    final note = result.note;
    if (result.failure != null || note == null) {
      return result.failure ?? const LocalFailure('Unknown error');
    }
    state = AsyncData([note, ...?state.value]);
    return null;
  }
}
