import '../repositories/auth_repository.dart';

/// Use case: end the current session.
class LogoutUser {
  const LogoutUser(this._repository);
  final AuthRepository _repository;

  Future<void> call() => _repository.logout();
}
