import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/check_auth_status.dart';
import '../../domain/usecases/login_user.dart';
import '../../domain/usecases/logout_user.dart';

// ---------- Data layer (DI) ----------
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => MockAuthRemoteDataSource(),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remote: ref.watch(authRemoteDataSourceProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

// ---------- Domain layer: use cases receive the abstraction ----------
final loginUserProvider = Provider<LoginUser>(
  (ref) => LoginUser(ref.watch(authRepositoryProvider)),
);

final logoutUserProvider = Provider<LogoutUser>(
  (ref) => LogoutUser(ref.watch(authRepositoryProvider)),
);

final checkAuthStatusProvider = Provider<CheckAuthStatus>(
  (ref) => CheckAuthStatus(ref.watch(authRepositoryProvider)),
);

// ---------- Presentation layer: UI state ----------
final authStateProvider = AsyncNotifierProvider<AuthNotifier, bool>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.watch(checkAuthStatusProvider).call();

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    final result = await ref
        .read(loginUserProvider)
        .call(email: email, password: password);
    final failure = result.failure;
    state = failure == null
        ? const AsyncData(true)
        : AsyncError(failure, StackTrace.current);
  }

  Future<void> logout() async {
    await ref.read(logoutUserProvider).call();
    ref.invalidateSelf();
  }
}
