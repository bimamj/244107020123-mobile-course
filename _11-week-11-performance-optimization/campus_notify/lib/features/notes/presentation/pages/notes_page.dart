import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/failures.dart';
import '../../../../core/widgets/error_view.dart';
import '../providers/notes_providers.dart';
import '../widgets/add_note_dialog.dart';
import '../widgets/notes_list.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  Future<void> _addNote(BuildContext context, WidgetRef ref) async {
    final input = await AddNoteDialog.show(context);
    if (input == null) return;
    final failure = await ref
        .read(notesProvider.notifier)
        .add(title: input.title, body: input.body);
    if (failure != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Optimization: Filter subscription with select so NotesPage does not rebuild on every keystroke
    final isQueryEmpty = ref.watch(notesSearchQueryProvider.select((q) => q.trim().isEmpty));
    final state = ref.watch(filteredNotesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Notes')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add note',
        onPressed: () => _addNote(context, ref),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          const _NotesSearchHeader(),
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorView(
                message: e is Failure ? e.message : '$e',
                onRetry: () => ref.invalidate(notesProvider),
              ),
              data: (notes) => notes.isEmpty
                  ? NotesEmptyState(isSearchEmpty: isQueryEmpty)
                  : RepaintBoundary(child: NotesList(notes)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Extracted search header widget with const styling
class _NotesSearchHeader extends ConsumerWidget {
  const _NotesSearchHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        key: const Key('notes_search_field'),
        decoration: const InputDecoration(
          hintText: 'Search notes by title...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: (v) =>
            ref.read(notesSearchQueryProvider.notifier).setQuery(v),
      ),
    );
  }
}

/// Extracted empty state widget with const constructors
class NotesEmptyState extends StatelessWidget {
  const NotesEmptyState({super.key, required this.isSearchEmpty});

  final bool isSearchEmpty;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSearchEmpty ? Icons.note_alt_outlined : Icons.search_off,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 8),
          Text(
            isSearchEmpty ? 'No notes yet.' : 'No notes found.',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
