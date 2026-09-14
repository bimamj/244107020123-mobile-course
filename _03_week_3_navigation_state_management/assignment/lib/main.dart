// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'pages/todo_list_page.dart';
import 'pages/stats_page.dart';

void main() => runApp(const ProviderScope(child: AsyncTodoApp()));

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return Scaffold(
          body: child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: state.uri.path == '/stats' ? 1 : 0,
            onDestinationSelected: (index) {
              if (index == 0) context.go('/');
              if (index == 1) context.go('/stats');
            },
            destinations: const [
              NavigationDestination(icon: Icon(Icons.list), label: 'Tasks'),
              NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Stats'),
            ],
          ),
        );
      },
      routes: [
        GoRoute(path: '/', builder: (context, state) => const TodoListPage()),
        GoRoute(path: '/stats', builder: (context, state) => const StatsPage()),
      ],
    ),
  ],
);

class AsyncTodoApp extends StatelessWidget {
  const AsyncTodoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        routerConfig: _router,
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      );
}