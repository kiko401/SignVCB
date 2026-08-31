import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/yuyu_avatar.dart';

class WordMatchPage extends StatefulWidget {
  const WordMatchPage({super.key});

  @override
  State<WordMatchPage> createState() => _WordMatchPageState();
}

class _WordMatchPageState extends State<WordMatchPage> {
  int? _selected;
  final List<bool?> _results = [null, null, null, null];

  static const _words = ['苹果', '猫咪', '跑步', '书包'];
  static const _icons = [
    Icons.apple_rounded,
    Icons.pets_rounded,
    Icons.directions_run_rounded,
    Icons.backpack_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.morningMist,
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: '拼图练习',
              onBack: () => context.go('/practice/map'),
            ),
            const SizedBox(height: 14),
            const SizedBox(
              width: 56,
              height: 56,
              child: YuyuAvatar(
                width: 56,
                height: 56,
                animationName: 'Yuyu_HoldingTray',
                assetPath: 'assets/rive/yuyu.riv',
                artboardName: 'yuyu_main',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '把词卡拼起来',
              style: AppTextStyles.caption.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 18),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.pureWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D9067ED),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.view_module_rounded,
                      color: AppColors.starPurple, size: 18),
                  const SizedBox(width: 8),
                  Text('目标句子',
                      style: AppTextStyles.body.copyWith(fontSize: 16)),
                  const Spacer(),
                  Text('点选 4 张词卡',
                      style: AppTextStyles.caption.copyWith(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.18,
                ),
                itemCount: _words.length,
                itemBuilder: (context, i) => _WordCard(
                  word: _words[i],
                  icon: _icons[i],
                  selected: _selected == i,
                  result: _results[i],
                  onTap: () =>
                      setState(() => _selected = _selected == i ? null : i),
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selected == null ? null : _checkAnswer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.starPurple,
                    disabledBackgroundColor: AppColors.lightCloudGray,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                  child: Text(
                    '确认',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.pureWhite,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
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
            ? AppColors.kumquatOrange.withValues(alpha: 0.28)
            : selected
                ? AppColors.morningMist
                : AppColors.cloudGray;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: selected
              ? Border.all(color: AppColors.starPurple, width: 1.5)
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
            Icon(icon, size: 30, color: AppColors.calmBlue),
            const SizedBox(height: 6),
            Text(word, style: AppTextStyles.body.copyWith(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
