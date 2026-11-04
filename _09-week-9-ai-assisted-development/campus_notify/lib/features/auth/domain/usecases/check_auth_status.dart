import '../repositories/auth_repository.dart';

/// Use case: check whether a session is already stored (app start).
class CheckAuthStatus {
  const CheckAuthStatus(this._repository);
  final AuthRepository _repository;

  Future<bool> call() => _repository.isLoggedIn();
}
