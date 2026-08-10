import 'dart:convert'; //dart 自带编解码工具

import 'package:shared_preferences/shared_preferences.dart'; //Flutter 最常用本地缓存插件

import '../../features/auth/data/auth_models.dart'; //导入用户实体类 `AuthUser`（账号、昵称、id 这类用户数据）

class TokenStorage {
  const TokenStorage._(); //私有构造函数

  static const _keyToken = 'token';
  static const _keyUser = 'user';

  static Future<void> saveToken(String token) async {
    //保存登录令牌
    final prefs = await SharedPreferences.getInstance(); //获取本地缓存工具实例
    await prefs.setString(_keyToken, token); //把 token 写到手机本地
  }

  static Future<String?> getToken() async {
    //读取 token,前面的 dio 拦截器，就是调用这个函数自动往请求头带上 Token
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken); //从本地缓存拿出 token；没有存过就返回 null
  }

  static Future<void> saveUser(AuthUser user) async {
    //保存用户完整信息
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _keyUser, jsonEncode(user.toJson())); //用户实体 → Dart Map 字典,再转成JSON字符串
  }

  static Future<AuthUser?> getUser() async {
    //读取用户信息
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUser); //取出 json 字符串
    if (raw == null || raw.isEmpty) return null;
    return AuthUser.fromJson(
        jsonDecode(raw) as Map<String, dynamic>); //字符串转回 Map,字典还原成用户对象
  }

  static Future<void> clear() async {//用户主动退出或token失效
    //清空登录数据（退出登录），对应 dio 里面 401 鉴权失败触发的强制登出。
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken); //删掉本地 token和用户资料
    await prefs.remove(_keyUser);
  }
}
