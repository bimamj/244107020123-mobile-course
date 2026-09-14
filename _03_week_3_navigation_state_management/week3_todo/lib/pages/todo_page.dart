// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../providers/todo_provider.dart';

// class TodoPage extends ConsumerWidget {
//   const TodoPage({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final todos = ref.watch(todoListProvider);

//     return Scaffold(
//       appBar: AppBar(title: const Text('ToDo Riverpod')),
//       body: todos.isEmpty
//           ? const Center(child: Text('Belum ada tugas'))
//           : ListView.builder(
//               itemCount: todos.length,
//               itemBuilder: (context, index) => ListTile(
//                 leading: Checkbox(
//                   value: todos[index].done,
//                   onChanged: (_) =>
//                       ref.read(todoListProvider.notifier).toggle(index),
//                 ),
//                 title: Text(
//                   todos[index].title,
//                   style: TextStyle(
//                       decoration: todos[index].done
//                           ? TextDecoration.lineThrough
//                           : null),
//                 ),
//                 trailing: IconButton(
//                   icon: const Icon(Icons.delete),
//                   onPressed: () =>
//                       ref.read(todoListProvider.notifier).remove(index),
//                 ),
//               ),
//             ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => _showAddDialog(context, ref),
//         child: const Icon(Icons.add),
//       ),
//     );
//   }

//   void _showAddDialog(BuildContext context, WidgetRef ref) {
//     final controller = TextEditingController();
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Tugas baru'),
//         content: TextField(controller: controller, autofocus: true),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Batal'),
//           ),
//           FilledButton(
//             onPressed: () {
//               if (controller.text.trim().isNotEmpty) {
//                 ref
//                     .read(todoListProvider.notifier)
//                     .add(controller.text.trim());
//               }
//               Navigator.pop(context);
//             },
//             child: const Text('Tambah'),
//           ),
//         ],
//       ),
//     );
//   }
// }

// lib/pages/todo_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/todo_provider.dart';

class TodoPage extends ConsumerWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(filteredTodoListProvider);
    final isFiltered = ref.watch(filterUncompletedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ToDo Riverpod'),
        actions: [
          Row(
            children: [
              const Text('Hide Done'),
              Switch(
                value: isFiltered,
                onChanged: (val) =>
                    ref.read(filterUncompletedProvider.notifier).setFilter(val),
              ),
            ],
          ),
        ],
      ),
      body: todos.isEmpty
          ? const Center(child: Text('Belum ada tugas'))
          : ListView.builder(
              itemCount: todos.length,
              itemBuilder: (context, index) => ListTile(
                leading: Checkbox(
                  value: todos[index].done,
                  onChanged: (_) => ref
                      .read(todoListProvider.notifier)
                      .toggle(
                        todos[index].id,
                      ), // Changed index to todos[index].id
                ),
                title: Text(
                  todos[index].title,
                  style: TextStyle(
                    decoration: todos[index].done
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => ref
                      .read(todoListProvider.notifier)
                      .remove(
                        todos[index].id,
                      ), // Changed index to todos[index].id
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tugas baru'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                controller.clear(); // Clears text so it won't duplicate in the widget tree during dismissal
                ref.read(todoListProvider.notifier).add(text);
              }
              Navigator.pop(context);
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }
}
