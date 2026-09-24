import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'pages/post_list_page.dart';
// import 'pages/paged_post_page.dart';
import 'pages/comment_list_page.dart';
// import 'pages/post_detail_page.dart';
// import 'package:go_router/go_router.dart';

// final _router = GoRouter(
//   routes: [
//     GoRoute(
//       path: '/',
//       builder: (context, state) => const PostListPage(), // Your list page
//     ),
//     GoRoute(
//       path: '/post/:id',
//       builder: (context, state) {
//         final id = int.parse(state.pathParameters['id']!);
//         return PostDetailPage(id: id);
//       },
//     ),
//   ],
// );

void main() => runApp(const ProviderScope(child: MyApp()));

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Week 4 - REST API',
        theme: ThemeData(
            colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: const CommentListPage(postId: 1), // Change this to PostListPage() or PagedPostPage() to test other pages
      );
}