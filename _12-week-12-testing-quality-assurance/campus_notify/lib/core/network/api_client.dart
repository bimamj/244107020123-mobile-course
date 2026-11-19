import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'token_refresher.dart';

const _defaultBaseUrl = 'https://example-campus-api.test';

Dio buildApiClient({
  required TokenStorage store,
  required TokenRefresher refresher,
  String baseUrl = _defaultBaseUrl,
}) {
  final dio = Dio(BaseOptions(baseUrl: baseUrl));
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final access = await store.readAccess();
      if (access != null) {
        options.headers['Authorization'] = 'Bearer $access';
      }
      handler.next(options);
    },
    onError: (e, handler) async {
      if (e.response?.statusCode == 401) {
        final refresh = await store.readRefresh();
        if (refresh == null) return handler.next(e);
        try {
          final renewed = await refresher.refresh(refresh);
          await store.save(access: renewed, refresh: refresh);
          final retry = await dio.fetch(
            e.requestOptions..headers['Authorization'] = 'Bearer $renewed',
          );
          return handler.resolve(retry);
        } catch (_) {
          await store.clear(); // refresh dead too -> force re-login
        }
      }
      handler.next(e);
    },
  ));
  return dio;
}
