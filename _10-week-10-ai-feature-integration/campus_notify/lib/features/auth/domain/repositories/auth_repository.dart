import '../../../../core/failures.dart';
import '../entities/auth_session.dart';

abstract interface class AuthRepository {
  /// Authenticates and persists the session tokens.
  Future<({AuthSession? session, Failure? failure})> login({
    required String email,
    required String password,
  });

  /// Removes any persisted session.
  Future<void> logout();

  /// Whether a session is currently persisted.
  Future<bool> isLoggedIn();
}
