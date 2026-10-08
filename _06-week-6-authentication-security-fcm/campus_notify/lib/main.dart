import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/announcement_page.dart';
import '../providers/auth_provider.dart';
import 'messaging/push_service.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final initialAuthState = ref.read(authStateProvider).value ?? false;
  final authStateNotifier = ValueNotifier<bool>(initialAuthState);

  ref.listen<AsyncValue<bool>>(
    authStateProvider,
    (_, next) {
      authStateNotifier.value = next.value ?? false;
    },
  );

  ref.onDispose(() => authStateNotifier.dispose());

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authStateNotifier, 
    redirect: (context, state) {
      final loggedIn = authStateNotifier.value;
      final goingLogin = state.matchedLocation == '/login';

      if (!loggedIn && !goingLogin) return '/login';
      if (loggedIn && goingLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/', builder: (_, __) => const HomePage()),
      GoRoute(
        path: '/announcement/:id',
        builder: (_, s) => AnnouncementPage(id: s.pathParameters['id'] ?? ''),
      ),
    ],
  );
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Daftarkan background handler sebelum runApp
  registerBackgroundHandler();

  // Jangan di-await agar tidak memblokir runApp (menghindari stuck di splash screen)
  initPushServices();

  runApp(const ProviderScope(child: MyApp()));
}

// Fungsi bantuan untuk menjalankan inisialisasi secara asinkron
Future<void> initPushServices() async {
  try {
    await requestNotificationPermission();
    await initLocalNotifications();
    await initFcmToken(onToken: (token) async {
      debugPrint('FCM Token berhasil didapat: $token');
    });
  } catch (e) {
    debugPrint('Gagal inisialisasi push service: $e');
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = ref.read(routerProvider);
      void go(String route) => router.go(route);
      
      listenForeground(go);
      handleTerminated(go);
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Campus Notify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF4F7DC9),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}