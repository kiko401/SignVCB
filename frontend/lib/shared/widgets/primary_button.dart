import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimens.buttonHeightPrimary,
      width: double.infinity,
      child: AnimatedScale(
        scale: onPressed == null ? 1.0 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: ElevatedButton(
          onPressed: (loading || onPressed == null) ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.starPurple,
            disabledBackgroundColor: AppColors.lightCloudGray,
            foregroundColor: AppColors.pureWhite,
            disabledForegroundColor: AppColors.thinCloudGray,
            shape: RoundedRectangleBorder(borderRadius: AppDimens.brL1),
            padding: const EdgeInsets.symmetric(horizontal: 32),
            elevation: 0,
          ),
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.pureWhite,
                  ),
                )
              : Text(label, style: AppTextStyles.body.copyWith(color: AppColors.pureWhite)),
        ),
      ),
    );
  }
}
