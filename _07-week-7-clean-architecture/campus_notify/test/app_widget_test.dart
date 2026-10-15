import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_notify/main.dart';
import 'package:campus_notify/core/providers.dart';
import 'package:campus_notify/core/messaging/push_notification_service.dart';
import 'package:campus_notify/core/storage/token_storage.dart';
import 'package:campus_notify/features/auth/presentation/providers/auth_providers.dart';

class FakeTokenStorage implements TokenStorage {
  @override
  Future<void> clear() async {}
  @override
  Future<String?> readAccess() async => null;
  @override
  Future<String?> readRefresh() async => null;
  @override
  Future<void> save({required String access, required String refresh}) async {}
}

void main() {
  testWidgets('MyApp boots and displays Login screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pushNotificationServiceProvider
              .overrideWithValue(const NoopPushNotificationService()),
          tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
          tokenRefresherProvider.overrideWith(
              (ref) => ref.watch(authRemoteDataSourceProvider)),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Login'), findsWidgets);
  });
}
