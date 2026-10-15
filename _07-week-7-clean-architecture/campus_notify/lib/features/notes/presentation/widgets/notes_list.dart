import 'package:flutter/material.dart';

import '../../domain/entities/note.dart';

class NotesList extends StatelessWidget {
  const NotesList(this.notes, {super.key});

  final List<Note> notes;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: notes.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final note = notes[index];
        return ListTile(
          leading: const Icon(Icons.sticky_note_2_outlined),
          title: Text(note.title),
          subtitle: note.body.isEmpty
              ? null
              : Text(note.body, maxLines: 2, overflow: TextOverflow.ellipsis),
          trailing: note.dirty
              ? const Tooltip(
                  message: 'Not synced yet',
                  child: Icon(Icons.cloud_upload_outlined, size: 18),
                )
              : null,
        );
      },
    );
  }
}
