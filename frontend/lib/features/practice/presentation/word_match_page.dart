import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';

class WordMatchPage extends StatefulWidget {
  const WordMatchPage({super.key});

  @override
  State<WordMatchPage> createState() => _WordMatchPageState();
}

class _WordMatchPageState extends State<WordMatchPage> {
  int? _selected;
  final List<bool?> _results = [null, null, null, null];

  static const _words = ['苹果', '猫咪', '跑步', '书包'];
  static const _icons = [Icons.apple, Icons.pets, Icons.directions_run, Icons.backpack];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.morningMist,
      appBar: AppBar(
        backgroundColor: AppColors.pureWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.calmBlue),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('拼图练习', style: AppTextStyles.h2),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppDimens.spacingL),
            // 呦呦 HoldingTray 占位
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.pureWhite,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.extension, size: 28, color: AppColors.starPurple),
              ),
            ),
            const SizedBox(height: AppDimens.spacingS),
            const Text('找到对应的词卡', style: AppTextStyles.caption),
            const SizedBox(height: AppDimens.spacingXXL),
            // 词卡网格
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppDimens.spacingM,
                  crossAxisSpacing: AppDimens.spacingM,
                  childAspectRatio: AppDimens.wordCardWidth / AppDimens.wordCardHeight,
                ),
                itemCount: _words.length,
                itemBuilder: (context, i) => _WordCard(
                  word: _words[i],
                  icon: _icons[i],
                  selected: _selected == i,
                  result: _results[i],
                  onTap: () => setState(() => _selected = _selected == i ? null : i),
                ),
              ),
            ),
            const Spacer(),
            // 提交按钮
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                height: AppDimens.buttonHeightPrimary,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selected == null ? null : _checkAnswer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.starPurple,
                    disabledBackgroundColor: AppColors.lightCloudGray,
                    shape: RoundedRectangleBorder(borderRadius: AppDimens.brL1),
                  ),
                  child: Text(
                    '确认',
                    style: AppTextStyles.body.copyWith(color: AppColors.pureWhite),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.spacingXXL),
          ],
        ),
      ),
    );
  }

  void _checkAnswer() {
    if (_selected == null) return;
    setState(() {
      _results[_selected!] = _selected == 0;
      _selected = null;
    });
  }
}

class _WordCard extends StatelessWidget {
  const _WordCard({
    required this.word,
    required this.icon,
    required this.selected,
    required this.result,
    required this.onTap,
  });
  final String word;
  final IconData icon;
  final bool selected;
  final bool? result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = result == true
        ? AppColors.sproutYellow
        : result == false
            ? AppColors.kumquatOrange.withValues(alpha: 0.3)
            : selected
                ? AppColors.morningMist
                : AppColors.cloudGray;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppDimens.brToast,
          border: selected
              ? Border.all(color: AppColors.starPurple, width: AppDimens.borderWidthFocus)
              : null,
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x1E9067ED),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: AppColors.calmBlue),
            const SizedBox(height: 6),
            Text(word, style: AppTextStyles.body),
          ],
        ),
      ),
    );
  }
}

