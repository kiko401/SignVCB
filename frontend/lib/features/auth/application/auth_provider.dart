import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/token_storage.dart';
import '../../../core/utils/logger.dart';
import '../data/auth_api.dart';
import '../data/auth_models.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthState {
  const AuthState({this.status = AuthStatus.initial, this.user});

  final AuthStatus status;
  final AuthUser? user;

  AuthState copyWith({AuthStatus? status, AuthUser? user}) {
    return AuthState(status: status ?? this.status, user: user ?? this.user);
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authApi) : super(const AuthState()) {
    _bootstrap();
  }

  final AuthApi _authApi;

  Future<void> _bootstrap() async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null || token.isEmpty) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }
      final user = await TokenStorage.getUser();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (error, stackTrace) {
      AppLogger.e('Auth bootstrap failed', error, stackTrace);
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login({required String username, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading);
    await _authApi.login(username: username, password: password);
    final user = await TokenStorage.getUser();
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  Future<void> register({
    required String username,
    required String password,
    required String ageGroup,
    String? nickname,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    await _authApi.register(
      username: username,
      password: password,
      ageGroup: ageGroup,
      nickname: nickname,
    );
    final user = await TokenStorage.getUser();
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  Future<void> logout() async {
    await _authApi.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> forceLogout() async => logout();
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authApiProvider));
});
