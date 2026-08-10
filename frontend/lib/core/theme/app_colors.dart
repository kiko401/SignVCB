import 'package:flutter/material.dart'; //Flutter UI 基础包

class AppColors {
  const AppColors._();
//构造函数带下划线，外部代码不能 `AppColors()` 新建这个类的对象
//所有颜色都是 `static const` 静态常量，直接通过 `AppColors.starPurple` 调用
  static const Color starPurple = Color(0xFF9067ED);
  static const Color lilacPurple = Color(0xFFC490F9);
  static const Color morningMist = Color(0xFFEBE3F8);
  static const Color cheeseYellow = Color(0xFFFDF37D);
  static const Color sproutYellow = Color(0xFFE2ED8F);
  static const Color sakuraPink = Color(0xFFF2C8F7);
  static const Color cloudGray = Color(0xFFF1F5F9);
  static const Color lightCloudGray = Color(0xFFE2E8F0);
  static const Color calmBlue = Color(0xFF6792BC);
  static const Color thinCloudGray = Color(0xFFAFAFAF);
  static const Color kumquatOrange = Color(0xFFFDB728);
  static const Color paleGolden = Color(0xFFFEF3C7);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = calmBlue;
  static const Color textSecondary = thinCloudGray;
}
