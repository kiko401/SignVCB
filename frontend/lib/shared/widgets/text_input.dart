import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';

class AppTextInput extends StatelessWidget {
  const AppTextInput({
    super.key,
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.contentFontSize = 22,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final double contentFontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimens.inputHeight,
      decoration: BoxDecoration(
        color: AppColors.pureWhite.withValues(alpha: 0.96),
        borderRadius: AppDimens.brL2,
        boxShadow: [
          BoxShadow(
            color: AppColors.starPurple.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: AppTextStyles.body.copyWith(
          color: AppColors.calmBlue,
          fontSize: contentFontSize,
          height: 1.2,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.body.copyWith(
            color: AppColors.thinCloudGray,
            fontSize: contentFontSize,
            height: 1.2,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: prefixIcon == null
              ? null
              : Padding(
                  padding: const EdgeInsetsDirectional.only(start: 16, end: 10),
                  child: prefixIcon,
                ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: suffixIcon,
          suffixIconConstraints: const BoxConstraints(minWidth: 52, minHeight: 52),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 0,
          ),
          border: OutlineInputBorder(
            borderRadius: AppDimens.brL2,
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppDimens.brL2,
            borderSide: BorderSide(
              color: AppColors.pureWhite.withValues(alpha: 0.85),
              width: 1,
            ),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppDimens.radiusL2)),
            borderSide: BorderSide(
              color: AppColors.starPurple,
              width: AppDimens.borderWidthFocus,
            ),
          ),
        ),
      ),
    );
  }
}
