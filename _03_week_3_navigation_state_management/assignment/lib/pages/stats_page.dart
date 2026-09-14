import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/todo_provider.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(todoStatsProvider);
    final asyncTodos = ref.watch(asyncTodoListProvider); // Pantau loading state juga

    return Scaffold(
      appBar: AppBar(title: const Text('Statistik')),
      body: asyncTodos.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Total: ${stats['total']}', style: const TextStyle(fontSize: 24)),
              Text('Selesai: ${stats['completed']}', style: const TextStyle(fontSize: 20, color: Colors.teal)),
              Text('Tertunda: ${stats['uncompleted']}', style: const TextStyle(fontSize: 20, color: Colors.orange)),
            ],
          ),
        ),
    );
  }
}