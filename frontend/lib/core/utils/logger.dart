/*
 * @Author: sunny-orb sunyan12201@outlook.com
 * @Date: 2026-08-08 14:06:53
 * @LastEditors: sunny-orb sunyan12201@outlook.com
 * @LastEditTime: 2026-08-10 20:30:14
 * @FilePath: \SignVCB\frontend\lib\core\utils\logger.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
import 'package:flutter/foundation.dart'; //Flutter 底层基础包

class AppLogger {
  const AppLogger._();

  static void d(Object? message) {
    //d () → debug 调试日志
    //`kDebugMode`：系统自带常量，**true = 现在是调试模式；正式打包之后为 false**
    //`debugPrint`：专门的控制台打印方法，比 print 更适合 Flutter（长日志不会截断）
    if (kDebugMode) debugPrint('🐛 $message');
  }

  static void i(Object? message) {
    //i () → info 普通信息日志
    debugPrint('ℹ️ $message');
  }

  static void w(Object? message) {
    //w () → warning 警告日志
    debugPrint('⚠️ $message');
  }

  static void e(Object? message, [Object? error, StackTrace? stackTrace]) {
    //e () → error 错误日志
    debugPrint('❌ $message');
    if (error != null) debugPrint('   error: $error');
    if (stackTrace != null) debugPrint('   stack: $stackTrace');
  }
}
