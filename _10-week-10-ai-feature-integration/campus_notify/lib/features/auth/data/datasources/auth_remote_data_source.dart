import '../../../../core/network/token_refresher.dart';
import '../models/auth_session_model.dart';

/// Remote auth API contract. Also a [TokenRefresher] so it can be plugged
/// into the shared API client.
abstract interface class AuthRemoteDataSource implements TokenRefresher {
  Future<AuthSessionModel> login({
    required String email,
    required String password,
  });
}

class MockAuthRemoteDataSource implements AuthRemoteDataSource {
  @override
  Future<AuthSessionModel> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Simulated JWT: header.payload.signature (never parse manually
    // in production, use server-side verification).
    return AuthSessionModel(
      access: 'mock-access-for-$email',
      refresh: 'mock-refresh-for-$email',
    );
  }

  @override
  Future<String> refresh(String refreshToken) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (refreshToken.isEmpty) throw Exception('Refresh token missing');
    return 'mock-access-renewed-${DateTime.now().millisecondsSinceEpoch}';
  }
}
