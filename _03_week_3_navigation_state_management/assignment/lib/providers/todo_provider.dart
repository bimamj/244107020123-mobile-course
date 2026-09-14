import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Todo {
  Todo({required this.id, required this.title, this.done = false});
  final String id;
  final String title;
  final bool done;

  Todo copyWith({String? id, String? title, bool? done}) =>
      Todo(id: id ?? this.id, title: title ?? this.title, done: done ?? this.done);
}

class AsyncTodoListNotifier extends AsyncNotifier<List<Todo>> {
  @override
  Future<List<Todo>> build() async {
    // Simulasi fetch API
    await Future.delayed(const Duration(seconds: 2));
    return [
      Todo(id: '1', title: 'Belajar Riverpod AsyncNotifier'),
      Todo(id: '2', title: 'Setup GoRouter Navigation'),
    ];
  }

  Future<void> add(String title) async {
    // Simpan list yang ada sebelum pindah ke loading state
    final currentList = state.value ?? [];
    
    // Tipe data eksplisit mencegah error casting 'dynamic'
    state = const AsyncValue<List<Todo>>.loading();
    
    state = await AsyncValue.guard(() async {
      await Future.delayed(const Duration(seconds: 1)); 
      
      if (title.toLowerCase() == 'error') {
        throw Exception('Gagal menghubungi server!');
      }

      final newTodo = Todo(
        id: DateTime.now().millisecondsSinceEpoch.toString(), 
        title: title
      );
      
      return [...currentList, newTodo];
    });
  }

  void toggle(String id) {
    final currentList = state.value ?? [];
    
    // Optimistic Update instan tanpa loading
    state = AsyncValue<List<Todo>>.data([
      for (final todo in currentList)
        if (todo.id == id) todo.copyWith(done: !todo.done) else todo
    ]);
  }

  void remove(String id) {
    final currentList = state.value ?? [];
    
    state = AsyncValue<List<Todo>>.data(
      currentList.where((t) => t.id != id).toList()
    );
  }
}

final asyncTodoListProvider = AsyncNotifierProvider<AsyncTodoListNotifier, List<Todo>>(AsyncTodoListNotifier.new);

final todoStatsProvider = Provider<Map<String, int>>((ref) {
  final asyncTodos = ref.watch(asyncTodoListProvider);
  return asyncTodos.maybeWhen(
    data: (todos) {
      final completed = todos.where((t) => t.done).length;
      return {'total': todos.length, 'completed': completed, 'uncompleted': todos.length - completed};
    },
    orElse: () => {'total': 0, 'completed': 0, 'uncompleted': 0},
  );
});