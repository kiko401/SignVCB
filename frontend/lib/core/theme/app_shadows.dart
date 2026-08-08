import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppShadows {
  const AppShadows._();

  static final List<BoxShadow> resting = [
    BoxShadow(
      color: AppColors.starPurple.withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];

  static final List<BoxShadow> lifted = [
    BoxShadow(
      color: AppColors.starPurple.withValues(alpha: 0.12),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  static final List<BoxShadow> floating = [
    BoxShadow(
      color: AppColors.starPurple.withValues(alpha: 0.16),
      blurRadius: 28,
      offset: const Offset(0, 16),
    ),
  ];
}
