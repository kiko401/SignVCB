/*
完整运行流程
1. 登录页面调用 AuthApi.login(username, password)
2. AuthApi 通过 Dio 发送 POST 请求到后端 /api/v1/auth/login
3. 后端验证成功返回 {access_token, token_type, user}
4. 前端解析响应，将 token 和 user 信息存入本地 SharedPreferences
5. AuthProvider 读取本地用户信息，更新全局登录状态为 authenticated
6. 路由守卫检测到登录状态变化，自动跳转到主页 /chat

知识点清单
1. Dio 网络请求：post() 方法发送 HTTP 请求
2. async/await 异步编程：等待网络响应
3. AuthResponse.fromJson：将后端 JSON 数据转换为 Dart 对象
4. TokenStorage：持久化存储 token 和用户信息
5. 错误处理：Dio 拦截器会自动捕获 401/500 等错误并转换为 ApiException
6. Provider 依赖注入：authApiProvider 提供全局唯一的 AuthApi 实例
*/

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import 'auth_models.dart';

class AuthApi {
  const AuthApi(this._dio);

  final Dio _dio;

  /*
   * @func: login
   * @description: 用户登录，发送账号密码到后端验证
   * @param: {String} username 用户名；{String} password 密码
   * @return: {Future<void>} 异步登录请求
   */
  Future<void> login({required String username, required String password}) async {
    final response = await _dio.post('/api/v1/auth/login', data: {
      'username': username,
      'password': password,
    });
    final authResponse = AuthResponse.fromJson(response.data as Map<String, dynamic>);
    await TokenStorage.saveToken(authResponse.token);
    await TokenStorage.saveUser(authResponse.user);
  }

  /*
   * @func: register
   * @description: 用户注册，创建新账号
   * @param: {String} username 用户名；{String} password 密码；{String} ageGroup 年龄段(L1/L2/L3)；{String?} nickname 昵称(可选)
   * @return: {Future<void>} 异步注册请求
   */
  Future<void> register({
    required String username,
    required String password,
    required String ageGroup,
    String? nickname,
  }) async {
    final response = await _dio.post('/api/v1/auth/register', data: {
      'username': username,
      'password': password,
      'age_group': ageGroup,
      if (nickname != null) 'nickname': nickname,
    });
    final authResponse = AuthResponse.fromJson(response.data as Map<String, dynamic>);
    await TokenStorage.saveToken(authResponse.token);
    await TokenStorage.saveUser(authResponse.user);
  }

  /*
   * @func: logout
   * @description: 用户退出登录，清空本地 token 和用户信息
   * @return: {Future<void>} 异步退出登录
   */
  Future<void> logout() async {
    await TokenStorage.clear();
  }
}

final authApiProvider = Provider<AuthApi>((ref) {
  // 不直接依赖 dioProvider，而是在内部创建 Dio 实例时才注入
  // 这样避免了 authApiProvider -> dioProvider -> authProvider -> authApiProvider 的循环依赖
  return AuthApi(ref.read(dioProvider));
});
