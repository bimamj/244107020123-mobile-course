import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/core/storage/token_storage.dart';
import 'package:campus_notify/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:campus_notify/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:campus_notify/features/auth/domain/usecases/check_auth_status.dart';
import 'package:campus_notify/features/auth/domain/usecases/login_user.dart';
import 'package:campus_notify/features/auth/domain/usecases/logout_user.dart';
import 'package:flutter_test/flutter_test.dart';

class InMemoryTokenStorage implements TokenStorage {
  String? access;
  String? refresh;

  @override
  Future<void> save({required String access, required String refresh}) async {
    this.access = access;
    this.refresh = refresh;
  }

  @override
  Future<String?> readAccess() async => access;

  @override
  Future<String?> readRefresh() async => refresh;

  @override
  Future<void> clear() async => access = refresh = null;
}

void main() {
  late InMemoryTokenStorage storage;
  late AuthRepositoryImpl repo;

  setUp(() {
    storage = InMemoryTokenStorage();
    repo = AuthRepositoryImpl(
      remote: MockAuthRemoteDataSource(),
      tokenStorage: storage,
    );
  });

  test('LoginUser rejects invalid credentials', () async {
    final result = await LoginUser(repo)(email: 'nope', password: '123');
    expect(result.failure, isA<ValidationFailure>());
    expect(storage.access, isNull);
  });

  test('login -> status -> logout flow', () async {
    final result = await LoginUser(repo)(
      email: 'a@campus.ac.id',
      password: 'secret1',
    );
    expect(result.failure, isNull);
    expect(await CheckAuthStatus(repo)(), isTrue);

    await LogoutUser(repo)();
    expect(await CheckAuthStatus(repo)(), isFalse);
  });
}
