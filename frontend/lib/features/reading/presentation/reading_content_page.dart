import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/yuyu_avatar.dart';

class ReadingContentPage extends StatefulWidget {
  const ReadingContentPage({super.key, required this.bookId});

  final int bookId;

  @override
  State<ReadingContentPage> createState() => _ReadingContentPageState();
}

class _ReadingContentPageState extends State<ReadingContentPage> {
  int _highlighted = 0;

  static const _sentences = [
    '春天来了，\n小鹿呦呦跑出森林。',
    '阳光暖洋洋的，\n她遇见了蝴蝶朋友。',
    '她们一起跳舞，\n笑声飘到云朵上。',
  ];

  static const _prompts = [
    '春天来 小鹿 呦呦 / 跑出 森林',
    '阳光 暖洋洋 她 遇见 蝴蝶 朋友',
    '她们 一起 跳舞 笑声 飘到 云朵',
  ];

  String get _bookTitle => switch (widget.bookId) {
        1 || 9001 => '小鹿呦呦',
        2 || 9002 => '蝴蝶朋友',
        3 || 9003 => '森林里的春天',
        _ => '阅读内容',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.morningMist,
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: _bookTitle,
              centerTitle: true,
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFF1E8FD),
                        Color(0xFFF6F0FE),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      const Positioned(
                          left: 12, top: 16, bottom: 16, child: _AccentBar()),
                      Positioned(
                        right: 14,
                        top: 14,
                        child: _VoiceBadge(onTap: () {}),
                      ),
                      Column(
                        children: [
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.only(left: 24, right: 56),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '点句子可播放',
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 11,
                                  color: AppColors.thinCloudGray
                                      .withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(24, 0, 16, 16),
                              itemCount: _sentences.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, i) {
                                final active = i == _highlighted;
                                return _ReadingCard(
                                  sentence: _sentences[i],
                                  prompt: _prompts[i],
                                  active: active,
                                  onTap: () => setState(() => _highlighted = i),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              color: AppColors.pureWhite,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 34,
                        height: 34,
                        child: YuyuAvatar(
                          width: 34,
                          height: 34,
                          animationName: 'Yuyu_Signing',
                          assetPath: 'assets/rive/yuyu.riv',
                          artboardName: 'yuyu_main',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '点句子可播放',
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 10,
                                color: AppColors.thinCloudGray
                                    .withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '上一句 / 下一句',
                              style: AppTextStyles.body.copyWith(
                                fontSize: 13,
                                height: 1.2,
                                fontWeight: FontWeight.w600,
                                color: AppColors.calmBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _NavButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        enabled: _highlighted > 0,
                        onTap: _highlighted > 0
                            ? () => setState(() => _highlighted--)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      _NavButton(
                        icon: Icons.arrow_forward_ios_rounded,
                        enabled: _highlighted < _sentences.length - 1,
                        onTap: _highlighted < _sentences.length - 1
                            ? () => setState(() => _highlighted++)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccentBar extends StatelessWidget {
  const _AccentBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.starPurple.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _VoiceBadge extends StatelessWidget {
  const _VoiceBadge({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.starPurple,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            Icons.graphic_eq_rounded,
            color: AppColors.pureWhite,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({
    required this.sentence,
    required this.prompt,
    required this.active,
    required this.onTap,
  });

  final String sentence;
  final String prompt;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.fromLTRB(16, 16, 14, 14),
        decoration: BoxDecoration(
          color: active
              ? AppColors.pureWhite
              : AppColors.pureWhite.withValues(alpha: 0.38),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: active
                ? AppColors.starPurple.withValues(alpha: 0.22)
                : Colors.transparent,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: active ? const Color(0x1A9067ED) : const Color(0x0A9067ED),
              blurRadius: active ? 16 : 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sentence,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 20,
                      height: 1.38,
                      fontWeight: FontWeight.w500,
                      color: active ? AppColors.starPurple : AppColors.calmBlue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    prompt,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 12,
                      height: 1.4,
                      letterSpacing: 0.15,
                      color: AppColors.lilacPurple.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                active ? Icons.volume_up_rounded : Icons.volume_up_outlined,
                color: active ? AppColors.starPurple : AppColors.lightCloudGray,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.enabled,
    this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? AppColors.starPurple : AppColors.lightCloudGray,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: AppColors.pureWhite, size: 16),
        ),
      ),
    );
  }
}
