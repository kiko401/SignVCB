/*
完整运行流程
1. 项目启动，Riverpod 创建全局唯一 dio 网络工具
2. dio 提前配置好后端地址、三种超时时间
3. 设置请求拦截器、错误拦截器
4. 你发起一次 post 请求
5. 进入 onRequest
   - 自动生成唯一请求 ID
   - 判断接口是不是登录注册
   - 需要登录的接口自动在头部带上 token
6. 请求发送给后端
7. 后端报错（引擎超时、token 过期）进入 onError
8. 401 就自动强制下线
9. 将后端返回的错误 json 封装成 ApiException 自定义异常抛出
10. 上层业务代码捕获 ApiException，判断错误码做出弹窗提示

知识点清单
1. import：导入各类工具、自定义类
2. Riverpod Provider：生成全局单例网络请求对象
3. Dio、BaseOptions：网络框架和全局配置（超时、后端域名）
4. InterceptorsWrapper 拦截器：请求钩子
5. onRequest 请求前置处理：uuid 请求编号、自动挂载 token
6. 路径字符串判断 contains
7. 异步 await 读取本地存储 token
8. onError 捕获所有网络报错
9. 401 鉴权失败触发强制登出
10. 利用上一节的 ApiException 将原生错误封装成项目统一异常
11. 空安全？、三目运算符、?? 兜底运算符
*/
import 'package:dio/dio.dart'; //第三方网络请求框架(HTTP请求库)，用来发接口和请求
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_provider.dart'; //登录模块仓库
import '../storage/token_storage.dart'; //读取本地保存的登录令牌token
import '../utils/uuid_generator.dart'; //生成唯一的请求编号request-id
import 'api_error_code.dart';
import 'api_exception.dart';

//final常量，赋值之后不能改动，生成全局唯一一份 Dio 网络对象
//`<Dio>` 代表这个提供者存放的数据类型是 Dio 网络实例
//在这里创建一个全局公用的网络请求工具，全项目共用一个 dio，统一配置拦截器、超时、请求头
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    //实例化 Dio，基础全局参数 BaseOptions
    BaseOptions(
      baseUrl: const String.fromEnvironment(
        //读取环境变量；打包时可以指定后端地址；没读取到就默认本地地址
        'BASE_URL',
        defaultValue: 'http://127.0.0.1:8081',
      ),
      connectTimeout: const Duration(seconds: 10), //连接超时：10 秒连不上后端直接报错
      receiveTimeout: const Duration(seconds: 15), //接收超时：后端返回数据等待上限 15 秒
      sendTimeout: const Duration(seconds: 15), //发送超时：上传数据最长等待 15 秒
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      //添加拦截器 InterceptorsWrapper
      //options：本次请求全部配置（地址、请求头、参数）
      //handler：拦截器控制器，用来放行请求或者拦截终止
      //请求发出去之前，自动生成请求 ID；非登录接口自动挂上登录令牌。
      onRequest: (options, handler) async {
        //请求发出之前触发
        options.headers['X-Request-ID'] = UuidGenerator
            .v4(); //`X‑Request‑ID`：给每一次网络请求生成唯一 uuid 编号，后端日志依靠这个编号排查问题
        //判断当前接口地址是不是**公开接口**：登录、注册、应用配置,公开接口不需要携带登录 token 令牌
        final isPublic = options.path.contains('/auth/login') ||
            options.path.contains('/auth/register') ||
            options.path.contains('/app_config');
        if (!isPublic) {
          final token = await TokenStorage.getToken(); //从本地存储读取登录 token
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] =
                'Bearer $token'; //如果令牌存在，往请求头带上 Authorization，后端依靠它识别你已经登录
          }
        }
        //放行，继续发送这条网络请求
        handler.next(options);
      },
      onError: (error, handler) async {
        //接口请求失败之后触发（重点）
        final statusCode =
            error.response?.statusCode; //http 状态码，401 = 未登录、500 = 服务器出错
        final data = error.response?.data; //后端返回的报错 json 数据
        if (statusCode == 401) {
          //如果状态码等于 401（token 过期、没有登录）
          //调用登录仓库的强制退出登录方法，清空本地登录信息，跳转登录页
          await ref.read(authProvider.notifier).forceLogout();
        }
        //判断后端返回的数据是不是 json 键值对 (Map)
        if (data is Map<String, dynamic>) {
          handler.reject(
            //抛出异常，终止本次请求
            DioException(
              requestOptions: error.requestOptions,
              error: ApiException.fromJson(data, statusCode: statusCode),
              response: error.response,
              type: error.type,
            ),
          );
          return;
        }
        //后端返回的数据不是标准 json 的时候，手动新建异常
        handler.reject(
          DioException(
            requestOptions: error.requestOptions,
            error: ApiException(
              code: statusCode == 401
                  ? ApiErrorCode.authInvalid
                  : ApiErrorCode.unknown, //401 → 鉴权失效枚举.其余错误 → 未知异常
              message: error.message ?? '网络请求失败', //?? 空判断，没有错误文案就默认文字：网络请求失败
              statusCode: statusCode,
            ),
            response: error.response,
            type: error.type,
          ),
        );
      },
    ),
  );

  return dio;
});
