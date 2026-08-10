import 'package:flutter/material.dart';

import 'app_colors.dart';

//调用示例：`AppTextStyles.h1`
class AppTextStyles {
  const AppTextStyles._();

  static const TextStyle display = TextStyle(
    //超大展示标题（首页大字、欢迎标语）
    fontSize: 56,
    height: 64 / 56, //行高，**行高 ÷ 字体大小**
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, //文字颜色，绑定全局配色
  );

  static const TextStyle h1 = TextStyle(
    //h1 一级大标题
    fontSize: 40,
    height: 48 / 40,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle h2 = TextStyle(
    //h2 二级标题
    fontSize: 32,
    height: 44 / 32,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    //body 正文文本（聊天消息、普通内容文字）
    fontSize: 24,
    height: 36 / 24,
    letterSpacing: 0.5,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    //caption 小字说明、备注、提示文字
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
}
