import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/todo_provider.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(todoStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistik Tugas')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Total Tugas: ${stats['total']}', style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 16),
            Text('Selesai: ${stats['completed']}', style: const TextStyle(fontSize: 20, color: Colors.teal)),
            const SizedBox(height: 8),
            Text('Belum Selesai: ${stats['uncompleted']}', style: const TextStyle(fontSize: 20, color: Colors.orange)),
          ],
        ),
      ),
    );
  }
}