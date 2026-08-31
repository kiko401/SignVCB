import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimens.buttonHeightSecondary,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.starPurple,
          backgroundColor: AppColors.pureWhite.withValues(alpha: 0.18),
          side: BorderSide(
            color: AppColors.starPurple.withValues(alpha: 0.55),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppDimens.buttonHeightSecondary / 2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32),
          elevation: 0,
        ),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: AppColors.starPurple.withValues(alpha: 0.86),
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
