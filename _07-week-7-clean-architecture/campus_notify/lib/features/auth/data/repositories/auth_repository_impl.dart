import '../../../../core/failures.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this._remote, required this._tokenStorage});

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokenStorage;

  @override
  Future<({AuthSession? session, Failure? failure})> login({
    required String email,
    required String password,
  }) async {
    try {
      final session = await _remote.login(email: email, password: password);
      await _tokenStorage.save(access: session.access, refresh: session.refresh);
      return (session: session, failure: null);
    } catch (e) {
      return (session: null, failure: AuthFailure('Login failed: $e'));
    }
  }

  @override
  Future<void> logout() => _tokenStorage.clear();

  @override
  Future<bool> isLoggedIn() async {
    try {
      return await _tokenStorage.readAccess() != null;
    } catch (_) {
      return false;
    }
  }
}
