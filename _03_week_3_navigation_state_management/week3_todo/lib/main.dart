// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'pages/todo_page.dart';

// void main() => runApp(const ProviderScope(child: MyApp()));

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context) => MaterialApp(
//         title: 'Week 3 - ToDo',
//         theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
//         home: const TodoPage(),
//       );
// }

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'pages/todo_page.dart';
import 'pages/stats_page.dart';

void main() => runApp(const ProviderScope(child: MyApp()));

// Konfigurasi GoRouter dengan ShellRoute
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
        GoRoute(
          path: '/',
          builder: (context, state) => const TodoPage(),
        ),
        GoRoute(
          path: '/stats',
          builder: (context, state) => const StatsPage(),
        ),
      ],
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) => MaterialApp.router(
        routerConfig: _router,
        title: 'Week 3 - ToDo',
        theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      );
}