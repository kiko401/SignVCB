import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppShadows {
  const AppShadows._();
//使用实例：boxShadow: AppShadows.resting, //直接套用卡片阴影
  static final List<BoxShadow> resting = [
    //默认平放状态・轻度阴影
    BoxShadow(
      color: AppColors.starPurple.withValues(alpha: 0.08), //透明度 8%，淡淡的阴影
      blurRadius: 12, //模糊半径，数值越大阴影越松散、越柔和
      offset: const Offset(0, 6), //阴影**向下偏移 6 像素**，往上不会有阴影，模拟卡片悬浮往下投影
    ),
  ];

  static final List<BoxShadow> lifted = [
    //抬起状态，中等阴影（点击、悬停抬高）
    BoxShadow(
      color: AppColors.starPurple.withValues(alpha: 0.12),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  static final List<BoxShadow> floating = [
    //高层悬浮阴影（弹窗、浮窗、顶部悬浮控件）
    BoxShadow(
      color: AppColors.starPurple.withValues(alpha: 0.16),
      blurRadius: 28,
      offset: const Offset(0, 16),
    ),
  ];
}
