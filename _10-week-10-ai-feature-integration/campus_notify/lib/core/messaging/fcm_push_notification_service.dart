import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'push_notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {

}

/// [PushNotificationService] implemented with Firebase Cloud Messaging

class FcmPushNotificationService implements PushNotificationService {
  FcmPushNotificationService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
    this.topic = 'pengumuman-kampus',
  })  : _messagingOverride = messaging,
        _local = localNotifications ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging? _messagingOverride;
  final FlutterLocalNotificationsPlugin _local;
  final String topic;

  RouteNavigator? _navigate;
  String? _pendingDeepLink;

  FirebaseMessaging? get _messaging {
    if (_messagingOverride != null) return _messagingOverride;
    try {
      return FirebaseMessaging.instance;
    } catch (e) {
      debugPrint('FirebaseMessaging not available: $e');
      return null;
    }
  }

  @override
  void registerBackgroundHandler() {
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint('registerBackgroundHandler failed: $e');
    }
  }

  @override
  Future<void> initialize({
    required Future<void> Function(String token) onToken,
  }) async {
    try {
      await _requestPermission();
      await _initLocalNotifications();
      await _initFcmToken(onToken);
    } catch (e) {
      debugPrint('Gagal inisialisasi push service: $e');
    }
  }

  @override
  Future<void> attachNavigator(RouteNavigator navigate) async {
    _navigate = navigate;
    try {
      _listenForeground();
      await _handleTerminated();
    } catch (e) {
      debugPrint('attachNavigator error: $e');
    }
  }

  Future<bool> _requestPermission() async {
    final messaging = _messaging;
    if (messaging == null) return false;
    final settings = await messaging.requestPermission(
      alert: true, badge: true, sound: true,
      announcement: false, carPlay: false, criticalAlert: false,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _local.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {

        final route = response.payload;
        if (route == null) return;
        final navigate = _navigate;
        if (navigate != null) {
          navigate(route);
        } else {
          _pendingDeepLink = route;
        }
      },
    );
  }

  Future<void> _initFcmToken(Future<void> Function(String token) onToken) async {
    final messaging = _messaging;
    if (messaging == null) return;

    final token = await messaging.getToken();
    if (token != null) await onToken(token);

    messaging.onTokenRefresh.listen(onToken);

    await messaging.subscribeToTopic(topic);
  }

  void _listenForeground() {
    final messaging = _messaging;
    if (messaging == null) return;

    // Foreground: sistem TIDAK menampilkan banner otomatis,
    FirebaseMessaging.onMessage.listen((message) async {
      final route = message.data['route'] ?? '/';
      const androidDetails = AndroidNotificationDetails(
        'pengumuman', 'Pengumuman Kampus',
        importance: Importance.high, priority: Priority.high,
      );
      await _local.show(
        id: message.hashCode,
        title: message.notification?.title ?? 'Pengumuman',
        body: message.notification?.body ?? '',
        notificationDetails: const NotificationDetails(android: androidDetails),
        payload: route,
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _navigate?.call(message.data['route'] ?? '/');
    });
  }

  Future<void> _handleTerminated() async {
    final messaging = _messaging;
    if (messaging == null) return;

    final initial = await messaging.getInitialMessage();
    if (initial != null) _navigate?.call(initial.data['route'] ?? '/');
    final pending = _pendingDeepLink;
    if (pending != null) {
      _navigate?.call(pending);
      _pendingDeepLink = null; 
    }
  }
}
