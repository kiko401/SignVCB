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

  static const _mockSentences = [
    '小鹿呦呦在森林里跑来跑去。',
    '它有一对美丽的鹿角。',
    '每天早上，呦呦都会去小溪边喝水。',
    '溪水清澈透明，倒映着蓝色的天空。',
    '呦呦最喜欢吃嫩绿的树叶。',
    '晚上，它和朋友们一起仰望星空。',
  ];

  String get _bookTitle => switch (widget.bookId) {
        1 || 9001 => '小猫钓鱼',
        2 || 9002 => '小马过河',
        3 || 9003 => '曹冲称象',
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
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0E7FD),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
                        itemCount: _mockSentences.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final active = i == _highlighted;
                          return GestureDetector(
                            onTap: () => setState(() => _highlighted = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding:
                                  const EdgeInsets.fromLTRB(14, 12, 12, 12),
                              decoration: BoxDecoration(
                                color: AppColors.pureWhite,
                                borderRadius: BorderRadius.circular(18),
                                border: active
                                    ? const Border(
                                        left: BorderSide(
                                          color: AppColors.starPurple,
                                          width: 5,
                                        ),
                                      )
                                    : null,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x0C9067ED),
                                    blurRadius: 10,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _mockSentences[i],
                                          style: AppTextStyles.body.copyWith(
                                            fontSize: 18,
                                            height: 1.45,
                                            color: active
                                                ? AppColors.starPurple
                                                : AppColors.calmBlue,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _spacedText(_mockSentences[i]),
                                          style: AppTextStyles.caption.copyWith(
                                            fontSize: 12,
                                            height: 1.35,
                                            color: AppColors.lilacPurple,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Icon(
                                      Icons.volume_up_rounded,
                                      color: active
                                          ? AppColors.starPurple
                                          : AppColors.lightCloudGray,
                                      size: 19,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        color: AppColors.pureWhite,
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(28),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 12,
                            offset: Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 42,
                                height: 42,
                                child: YuyuAvatar(
                                  width: 42,
                                  height: 42,
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
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '上一句 / 下一句',
                                      style: AppTextStyles.body.copyWith(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _NavButton(
                                icon: Icons.arrow_back_ios_new_rounded,
                                onTap: _highlighted > 0
                                    ? () => setState(() => _highlighted--)
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              _NavButton(
                                icon: Icons.arrow_forward_ios_rounded,
                                onTap: _highlighted < _mockSentences.length - 1
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
            ),
          ],
        ),
      ),
    );
  }

  String _spacedText(String text) {
    final cleaned = text.replaceAll(RegExp(r'[，。！？!?、\s]'), '');
    return cleaned.split('').join(' ');
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap != null ? AppColors.starPurple : AppColors.lightCloudGray,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: AppColors.pureWhite, size: 17),
        ),
      ),
    );
  }
}
