import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/token_storage.dart';
import 'auth_models.dart';

class AuthApi {
  
  Future<void> login({required String username, required String password}) async {
    final response = AuthResponse(
      token: 'mock-token',
      user: AuthUser(id: 1, username: username, ageGroup: 'L2', nickname: username),
    );
    await TokenStorage.saveToken(response.token);
    await TokenStorage.saveUser(response.user);
  }

  Future<void> register({
    required String username,
    required String password,
    required String ageGroup,
    String? nickname,
  }) async {
    final response = AuthResponse(
      token: 'mock-token',
      user: AuthUser(id: 1, username: username, ageGroup: ageGroup, nickname: nickname),
    );
    await TokenStorage.saveToken(response.token);
    await TokenStorage.saveUser(response.user);
  }

  Future<void> logout() async {
    await TokenStorage.clear();
  }
}

final authApiProvider = Provider<AuthApi>((ref) => AuthApi());
