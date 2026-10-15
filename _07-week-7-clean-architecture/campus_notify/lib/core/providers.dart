import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'messaging/fcm_push_notification_service.dart';
import 'messaging/push_notification_service.dart';
import 'network/api_client.dart';
import 'network/token_refresher.dart';
import 'storage/token_storage.dart';

/// Cross-feature providers. Every provider is typed by its ABSTRACTION,
final tokenStorageProvider =
    Provider<TokenStorage>((ref) => SecureTokenStorage());

final tokenRefresherProvider = Provider<TokenRefresher>(
  (ref) => throw UnimplementedError(
    'tokenRefresherProvider must be overridden in ProviderScope (main.dart).',
  ),
);

final apiClientProvider = Provider<Dio>((ref) {
  return buildApiClient(
    store: ref.watch(tokenStorageProvider),
    refresher: ref.watch(tokenRefresherProvider),
  );
});

final pushNotificationServiceProvider =
    Provider<PushNotificationService>((ref) => FcmPushNotificationService());
