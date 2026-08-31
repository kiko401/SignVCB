import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
    this.centerTitle = false,
  });

  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.pureWhite,
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
      child: Row(
        children: [
          if (onBack != null) ...[
            InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(18),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: AppColors.calmBlue,
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          if (centerTitle)
            Expanded(
              child: Center(
                child: Text(
                  title,
                  style: AppTextStyles.h2.copyWith(
                    fontSize: 19,
                    color: AppColors.calmBlue,
                  ),
                ),
              ),
            )
          else
            Text(
              title,
              style: AppTextStyles.h2.copyWith(
                fontSize: 19,
                color: AppColors.calmBlue,
              ),
            ),
          if (!centerTitle) const Spacer(),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}
