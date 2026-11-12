typedef RouteNavigator = void Function(String route);

abstract interface class PushNotificationService {
  void registerBackgroundHandler();


  Future<void> initialize({
    required Future<void> Function(String token) onToken,
  });

  Future<void> attachNavigator(RouteNavigator navigate);
}

class NoopPushNotificationService implements PushNotificationService {
  const NoopPushNotificationService();

  @override
  void registerBackgroundHandler() {}

  @override
  Future<void> initialize({
    required Future<void> Function(String token) onToken,
  }) async {}

  @override
  Future<void> attachNavigator(RouteNavigator navigate) async {}
}
