/*
1. `main.dart` 启动的时候，在 MaterialApp 写入 `theme: AppTheme.light`
2. 主题加载，载入紫色主色调、页面背景色
3. 自动挂载好提前写好的全套文字样式
4. 所有页面顶部导航栏透明居中
5. 所有聊天输入框、登录输入框默认圆角 20，点击之后紫色高亮边框
*/
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    //`get` 代表只读属性，每次调用返回一套浅色模式的完整主题数据
    return ThemeData(
      useMaterial3: true, //开启 Material‑3 最新一套 Flutter 设计规范，圆角、控件样式都是新版风格
      scaffoldBackgroundColor: AppColors
          .morningMist, //Scaffold 页面默认背景色，设置成浅紫色 `morningMist`，所有新建页面默认底色
      colorScheme: ColorScheme.fromSeed(
        //colorScheme 整套配色方案
        seedColor: AppColors.starPurple, //种子主色，整套配色基于这个紫色衍生
        primary: AppColors.starPurple, //主颜色：按钮、重点控件
        secondary: AppColors.lilacPurple, //次要辅助淡紫色
        surface: AppColors.pureWhite, //卡片、弹窗白底
      ),
      textTheme: const TextTheme(
        //textTheme 绑定全局字体,Text("文字",style:Theme.of(context).textTheme.bodyLarge)
        displayLarge: AppTextStyles.display,
        headlineLarge: AppTextStyles.h1,
        headlineMedium: AppTextStyles.h2,
        bodyLarge: AppTextStyles.body,
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.caption,
      ),
      appBarTheme: const AppBarTheme(
        //顶部导航栏全局样式
        backgroundColor: Colors.transparent, //背景透明，和页面底色融为一体
        elevation: 0, //取消导航栏下方阴影
        centerTitle: true, //标题居中
        foregroundColor: AppColors.calmBlue, //标题文字颜色
      ),
      inputDecorationTheme: InputDecorationTheme(
        //输入框全局默认样式
        filled: true, //开启填充底色
        fillColor: AppColors.pureWhite, //输入框底色纯白色
        border: OutlineInputBorder(
          //普通边框：浅灰色、圆角 20
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.lightCloudGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.lightCloudGray),
        ),
        focusedBorder: OutlineInputBorder(
          //激活 / 点击聚焦之后：边框变成主题紫色、线条加宽到 2px
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.starPurple, width: 2),
        ),
      ),
    );
  }
}
