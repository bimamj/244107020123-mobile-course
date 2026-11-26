import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'core/messaging/fcm_push_notification_service.dart';
import 'core/messaging/push_notification_service.dart';
import 'core/providers.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize desktop SQLite FFI on Windows / Linux desktop
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  PushNotificationService pushService;
  try {
    await Firebase.initializeApp();
    final fcmService = FcmPushNotificationService();
    fcmService.registerBackgroundHandler();

    unawaited(
      fcmService.initialize(
        onToken: (token) async {
          debugPrint('FCM Token berhasil didapat: $token');
        },
      ),
    );
    pushService = fcmService;
  } catch (e) {
    debugPrint(
      'Firebase not available ($e). Falling back to NoopPushNotificationService.',
    );
    pushService = const NoopPushNotificationService();
  }

  runApp(
    ProviderScope(
      overrides: [
        pushNotificationServiceProvider.overrideWithValue(pushService),
        tokenRefresherProvider.overrideWith(
          (ref) => ref.watch(authRemoteDataSourceProvider),
        ),
      ],
      child: const MyApp(),
    ),
  );
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
      ref.read(pushNotificationServiceProvider).attachNavigator(router.go);
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
