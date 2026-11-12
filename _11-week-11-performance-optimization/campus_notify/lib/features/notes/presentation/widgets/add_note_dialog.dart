import 'package:flutter/material.dart';

class AddNoteDialog extends StatefulWidget {
  const AddNoteDialog({super.key});

  static Future<({String title, String body})?> show(BuildContext context) {
    return showDialog<({String title, String body})>(
      context: context,
      builder: (_) => const AddNoteDialog(),
    );
  }

  @override
  State<AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<AddNoteDialog> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Note'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyController,
            decoration: const InputDecoration(labelText: 'Body'),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            (title: _titleController.text, body: _bodyController.text),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
