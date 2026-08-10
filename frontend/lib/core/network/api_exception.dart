/*
1. `import`：导入外部依赖文件
2. class：封装类，封装异常的数据和处理函数
3. 成员变量 final 只读变量、空安全？
4. 普通构造函数：初始化对象属性
5. factory 工厂构造：解析 json，加工之后生成异常对象
6. static 静态私有方法：字符串映射枚举
7. switch‑case 多分支判断
8. ?? 空值兜底运算符
9. @override 重写 toString，调试打印
10. implements 实现系统 Exception，自定义异常
*/

import 'api_error_code.dart'; //导入外部依赖文件，里面存放错误枚举

//手动封装的一个接口请求报错专用的异常类（封装一堆变量、一堆函数的盒子）
//后端返回的错误信息，全部包装成统一对象，方便我的程序识别「引擎超时、权限失效、限流」这些报错
class ApiException implements Exception {
  //普通构造函数(新建这个类对象的时候自动执行的函数，用来给成员变量赋值)
  ApiException({
    required this.code, //required：必填参数
    required this.message,
    this.requestId,
    this.statusCode,
  });

//final：变量一旦赋值之后，**一辈子不能修改**
//? 代表这个变量可以为空（null）
//四个成员变量（类里面的数据）
  final ApiErrorCode code; //枚举类型，标记是什么错误（引擎超时 / 登录失败）
  final String message; //后端返回的错误提示文字
  final String? requestId; //本次请求唯一编号，后端查日志用，可以为空
  final int? statusCode; //HTTP 状态码，例如 401、500，可以为空

//工厂构造函数：加工数据之后再返回对象
  factory ApiException.fromJson(Map<String, dynamic> json, {int? statusCode}) {
    return ApiException(
      code: _mapCode(json['code'] as String?),
      message: (json['message'] as String?) ??
          '请求失败', //`??`是空值运算符：如果后端没返回 message，默认文字 = "请求失败"
      requestId: json['request_id'] as String?,
      statusCode: statusCode,
    );
  }

//私有静态函数 _mapCode,后端返回的错误code,将字符串 → 转换成程序能识别的枚举
  static ApiErrorCode _mapCode(String? code) {
    switch (code) {
      case 'auth_invalid':
        return ApiErrorCode.authInvalid;
      case 'rate_limited':
        return ApiErrorCode.rateLimited;
      case 'engine_timeout':
        return ApiErrorCode.engineTimeout;
      case 'engine_unavailable':
        return ApiErrorCode.engineUnavailable;
      case 'asr_failed':
        return ApiErrorCode.asrFailed;
      case 'validation_error':
        return ApiErrorCode.validationError;
      case 'internal_error':
        return ApiErrorCode.internalError;
      default:
        return ApiErrorCode.unknown;
    }
  }

//重写 toString 方法(所有类默认自带toString方法，打印对象的时候会调用这个方法)
//控制台打印报错的时候，直接输出错误码 + 错误信息，方便调试
  @override
  String toString() => 'ApiException(code: $code, message: $message)';
}
