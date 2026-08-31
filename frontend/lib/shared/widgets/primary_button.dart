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
    final bool disabled = loading || onPressed == null;

    return SizedBox(
      height: AppDimens.buttonHeightPrimary,
      width: double.infinity,
      child: AnimatedScale(
        scale: onPressed == null ? 1.0 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppDimens.brL1,
            gradient: disabled
                ? LinearGradient(
                    colors: [
                      AppColors.lightCloudGray,
                      AppColors.lightCloudGray.withValues(alpha: 0.92),
                    ],
                  )
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.lilacPurple,
                      AppColors.starPurple,
                    ],
                  ),
            boxShadow: disabled
                ? const []
                : [
                    BoxShadow(
                      color: AppColors.starPurple.withValues(alpha: 0.20),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: ElevatedButton(
            onPressed: disabled ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              disabledForegroundColor: AppColors.thinCloudGray,
              foregroundColor: AppColors.pureWhite,
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
                : Text(
                    label,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.pureWhite,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
