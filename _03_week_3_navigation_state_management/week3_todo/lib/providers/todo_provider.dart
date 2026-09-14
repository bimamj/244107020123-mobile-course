// import 'package:flutter_riverpod/flutter_riverpod.dart';

// class Todo {
//   Todo(this.title, {this.done = false});
//   final String title;
//   final bool done;

//   Todo copyWith({String? title, bool? done}) =>
//       Todo(title ?? this.title, done: done ?? this.done);
// }

// class TodoListNotifier extends Notifier<List<Todo>> {
//   @override
//   List<Todo> build() => const [];

//   void add(String title) => state = [...state, Todo(title)];

//   void toggle(int index) {
//     final todos = [...state];
//     todos[index] = todos[index].copyWith(done: !todos[index].done);
//     state = todos;
//   }

//   void remove(int index) => state = [...state]..removeAt(index);
// }

// final todoListProvider =
//     NotifierProvider<TodoListNotifier, List<Todo>>(TodoListNotifier.new);

// providers/todo_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Todo {
  Todo({String? id, required this.title, this.done = false})
      : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();
  
  final String id;
  final String title;
  final bool done;

  Todo copyWith({String? id, String? title, bool? done}) =>
      Todo(id: id ?? this.id, title: title ?? this.title, done: done ?? this.done);
}

class TodoListNotifier extends Notifier<List<Todo>> {
  @override
  List<Todo> build() => const [];

  void add(String title) => state = [...state, Todo(title: title)];

  void toggle(String id) {
    state = [
      for (final todo in state)
        if (todo.id == id) todo.copyWith(done: !todo.done) else todo
    ];
  }

  void remove(String id) {
    state = state.where((todo) => todo.id != id).toList();
  }
}

final todoListProvider =
    NotifierProvider<TodoListNotifier, List<Todo>>(TodoListNotifier.new);

// State untuk mengatur toggle filter UI
class FilterNotifier extends Notifier<bool> {
  @override
  bool build() => false; // Initial state: false (show all todos)

  void setFilter(bool value) => state = value;
  void toggle() => state = !state;
}

final filterUncompletedProvider =
    NotifierProvider<FilterNotifier, bool>(FilterNotifier.new);

// Provider turunan 1: Logika Filter (Hanya tampilkan yang belum selesai jika aktif)
final filteredTodoListProvider = Provider<List<Todo>>((ref) {
  final todos = ref.watch(todoListProvider);
  final showUncompleted = ref.watch(filterUncompletedProvider);

  if (showUncompleted) {
    return todos.where((todo) => !todo.done).toList();
  }
  return todos;
});

// Provider turunan 2: Logika Statistik
final todoStatsProvider = Provider<Map<String, int>>((ref) {
  final todos = ref.watch(todoListProvider);
  final completed = todos.where((t) => t.done).length;
  return {
    'total': todos.length,
    'completed': completed,
    'uncompleted': todos.length - completed,
  };
});