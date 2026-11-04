import '../../../../core/failures.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

/// Use case: log a user in. Owns the input-validation business rule.
class LoginUser {
  const LoginUser(this._repository);
  final AuthRepository _repository;

  static const minPasswordLength = 6;

  Future<({AuthSession? session, Failure? failure})> call({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();
    if (!trimmedEmail.contains('@') || password.length < minPasswordLength) {
      return (
        session: null,
        failure: const ValidationFailure('Invalid email or password'),
      );
    }
    return _repository.login(email: trimmedEmail, password: password);
  }
}
