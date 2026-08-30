import 'package:flutter_riverpod/flutter_riverpod.dart'; //主流 Flutter 全局状态管理工具

import '../../../core/storage/token_storage.dart';
import '../../../core/utils/logger.dart';
import '../data/auth_api.dart';
import '../data/auth_models.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthState {
  const AuthState({this.status = AuthStatus.initial, this.user});

  final AuthStatus status; //当前登录状态
  final AuthUser? user; //登录之后存放用户信息，没登录就是 null

  /*
   * @func: copyWith
   * @description: 在原有状态基础上拷贝生成新实例，按需修改字段
   * @param: {AuthStatus?} status 新登录状态；{AuthUser?} user 用户数据
   * @return: {AuthState} 返回全新状态对象
   */
  AuthState copyWith({AuthStatus? status, AuthUser? user}) {
    return AuthState(status: status ?? this.status, user: user ?? this.user);
  }
}

//所有登录逻辑
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authApi) : super(const AuthState()) {
    _bootstrap();
  }

  final AuthApi _authApi;

  /*
   * @func: _bootstrap
   * @description: 程序启动校验本地Token，自动判定登录状态
   * @return: {Future<void>} 异步初始化任务
   */
  Future<void> _bootstrap() async {
    //程序启动初始化登录校验
    try {
      final token = await TokenStorage.getToken();
      //本地没有token → 未登录
      if (token == null || token.isEmpty) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }
      //拿到本地存储的用户信息，标记为已登录
      final user = await TokenStorage.getUser();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (error, stackTrace) {
      AppLogger.e('Auth bootstrap failed', error, stackTrace);
      //读取缓存出错，判定为未登录
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /*
   * @func: login
   * @description: 账号密码发起登录请求，更新全局登录状态
   * @param: {String} username 账号；{String} password 密码
   * @return: {Future<void>} 异步登录请求
   */
  Future<void> login(
      {required String username, required String password}) async {
    //登录方法
    state = state.copyWith(status: AuthStatus.loading); //状态改成 loading
    await _authApi.login(
        username: username, password: password); //请求后端登录接口,登录成功后端会把 token 存入本地
    final user = await TokenStorage.getUser(); //读取本地用户信息
    state = AuthState(status: AuthStatus.authenticated, user: user); //切换为已登录状态
  }

  /*
   * @func: register
   * @description: 用户账号注册，注册成功自动进入登录状态
   * @param: {String} username 账号；{String} password 密码；{String} ageGroup 年龄段；{String?} nickname 昵称
   * @return: {Future<void>} 异步注册请求
   */
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

  /*
   * @func: logout
   * @description: 用户主动退出登录，清空本地登录信息
   * @return: {Future<void>} 异步退出登录请求
   */
  Future<void> logout() async {
    await _authApi.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /*
   * @func: forceLogout
   * @description: 强制用户退出登录，通常在 token 失效时调用
   * @return: {Future<void>} 异步强制退出登录请求
   */
  Future<void> forceLogout() async => logout();
}

final StateNotifierProvider<AuthNotifier, AuthState> authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authApiProvider));
});
