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
          side: const BorderSide(color: AppColors.starPurple, width: AppDimens.borderWidthFocus),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.buttonHeightSecondary / 2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32),
        ),
        child: Text(label, style: AppTextStyles.body.copyWith(color: AppColors.starPurple)),
      ),
    );
  }
}
