import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/todo_provider.dart';

class TodoListPage extends ConsumerWidget {
  const TodoListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTodos = ref.watch(asyncTodoListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Async ToDo')),
      body: asyncTodos.when(
        // Loading
        loading: () => const Center(child: CircularProgressIndicator()),
        
        // Error
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(error.toString(), style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(asyncTodoListProvider), // Refresh data
                child: const Text('Coba Lagi'),
              )
            ],
          ),
        ),
        
        // Sukses (Data)
        data: (todos) => todos.isEmpty
            ? const Center(child: Text('Belum ada tugas'))
            : ListView.builder(
                itemCount: todos.length,
                itemBuilder: (context, index) {
                  final todo = todos[index];
                  return ListTile(
                    leading: Checkbox(
                      value: todo.done,
                      onChanged: (_) => ref.read(asyncTodoListProvider.notifier).toggle(todo.id),
                    ),
                    title: Text(todo.title, style: TextStyle(decoration: todo.done ? TextDecoration.lineThrough : null)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => ref.read(asyncTodoListProvider.notifier).remove(todo.id),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        // Disable button whn loadin
        onPressed: asyncTodos.isLoading ? null : () => _showAddDialog(context, ref),
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
        content: TextField(
          controller: controller, 
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Ketik "error" untuk test gagal'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                controller.clear();
                ref.read(asyncTodoListProvider.notifier).add(text);
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