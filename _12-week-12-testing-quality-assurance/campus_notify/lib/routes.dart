import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/announcements/presentation/pages/announcement_page.dart';
import 'features/announcements/presentation/pages/home_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/chat_assistant/presentation/pages/chat_page.dart';
import 'features/notes/presentation/pages/notes_page.dart';

/// Route constants: a single source of truth for paths.
abstract final class AppRoutes {
  static const home = '/';
  static const login = '/login';
  static const notes = '/notes';
  static const chat = '/chat';
  static const announcement = '/announcement/:id';

  static String announcementDetail(String id) => '/announcement/$id';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authListenable = ValueNotifier<bool>(
    ref.read(authStateProvider).value ?? false,
  );

  ref.listen<AsyncValue<bool>>(
    authStateProvider,
    (_, next) => authListenable.value = next.value ?? false,
  );

  ref.onDispose(authListenable.dispose);

  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: authListenable,
    redirect: (context, state) {
      final loggedIn = authListenable.value;
      final goingLogin = state.matchedLocation == AppRoutes.login;

      if (!loggedIn && !goingLogin) return AppRoutes.login;
      if (loggedIn && goingLogin) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginPage()),
      GoRoute(path: AppRoutes.home, builder: (_, _) => const HomePage()),
      GoRoute(path: AppRoutes.notes, builder: (_, _) => const NotesPage()),
      GoRoute(path: AppRoutes.chat, builder: (_, _) => const ChatPage()),
      GoRoute(
        path: AppRoutes.announcement,
        builder: (_, s) => AnnouncementPage(id: s.pathParameters['id'] ?? ''),
      ),
    ],
  );
});
