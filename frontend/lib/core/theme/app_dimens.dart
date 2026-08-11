import 'package:flutter/material.dart';

class AppDimens {
  const AppDimens._();

  // 圆角层级（对应三阶段学习进阶：启蒙/识字/表达）
  static const double radiusL1 = 28; // L1 启蒙期：大圆角，最亲和
  static const double radiusL2 = 20; // L2 识字期：中圆角
  static const double radiusL3 = 12; // L3 表达期：小圆角，偏成熟
  static const double radiusToast = 16; // Toast / WordCard 圆角
  static const double radiusFull = 999; // 胶囊 / 圆形按钮（足够大即可全圆）

  // 间距档位（用于 padding / gap / margin）
  static const double spacingXS = 8;
  static const double spacingS = 12;
  static const double spacingM = 16;
  static const double spacingL = 20;
  static const double spacingXL = 24;
  static const double spacingXXL = 32;

  // 组件固定尺寸
  static const double buttonHeightPrimary = 56;
  static const double buttonHeightSecondary = 48;
  static const double inputHeight = 56;
  static const double micButtonSize = 96;
  static const double wordCardWidth = 96;
  static const double wordCardHeight = 80;
  static const double starSize = 32;
  static const double avatarSizeS = 40; // 导航头像、气泡头像
  static const double avatarSizeM = 64; // 练习页节点头像

  // 底部安全区兜底偏移（Toast 底部偏移量）
  static const double toastBottomOffset = 80;

  // 边框宽度
  static const double borderWidthNormal = 1;
  static const double borderWidthFocus = 2;

  // BorderRadius 快捷方法（避免每处都写 BorderRadius.circular）
  static BorderRadius get brL1 => BorderRadius.circular(radiusL1);
  static BorderRadius get brL2 => BorderRadius.circular(radiusL2);
  static BorderRadius get brL3 => BorderRadius.circular(radiusL3);
  static BorderRadius get brToast => BorderRadius.circular(radiusToast);
  static BorderRadius get brFull => BorderRadius.circular(radiusFull);
}
