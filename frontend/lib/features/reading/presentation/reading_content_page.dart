import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';

class ReadingContentPage extends StatefulWidget {
  const ReadingContentPage({super.key, required this.bookId});

  final int bookId;

  @override
  State<ReadingContentPage> createState() => _ReadingContentPageState();
}

class _ReadingContentPageState extends State<ReadingContentPage> {
  int _highlighted = -1;

  static const _mockSentences = [
    '小鹿呦呦在森林里跑来跑去。',
    '它有一对美丽的鹿角。',
    '每天早上，呦呦都会去小溪边喝水。',
    '溪水清澈透明，倒映着蓝色的天空。',
    '呦呦最喜欢吃嫩绿的树叶。',
    '晚上，它和朋友们一起仰望星空。',
  ];

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
        title: Text('书籍 ${widget.bookId}', style: AppTextStyles.h2),
      ),
      body: Column(
        children: [
          // 句子列表
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              itemCount: _mockSentences.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppDimens.spacingS),
              itemBuilder: (context, i) {
                final active = i == _highlighted;
                return GestureDetector(
                  onTap: () => setState(() => _highlighted = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.spacingL,
                      vertical: AppDimens.spacingM,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.pureWhite,
                      borderRadius: AppDimens.brL2,
                      border: active
                          ? const Border(
                              left: BorderSide(
                                color: AppColors.starPurple,
                                width: 6,
                              ),
                            )
                          : null,
                      boxShadow: active
                          ? const [
                              BoxShadow(
                                color: Color(0x1E9067ED),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ]
                          : const [
                              BoxShadow(
                                color: Color(0x0D9067ED),
                                blurRadius: 12,
                                offset: Offset(0, 6),
                              ),
                            ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _mockSentences[i],
                            style: AppTextStyles.h2.copyWith(
                              // 阅读行高1.8倍
                              height: 1.8,
                              color: active ? AppColors.starPurple : AppColors.calmBlue,
                            ),
                          ),
                        ),
                        if (active)
                          const Icon(Icons.volume_up_rounded,
                              color: AppColors.starPurple, size: 28),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // 底部控制栏
          Container(
            decoration: const BoxDecoration(
              color: AppColors.pureWhite,
              boxShadow: [
                BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -2)),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.spacingL, vertical: AppDimens.spacingS),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 呦呦 Signing 占位
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: AppColors.morningMist,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.sign_language, size: 36, color: AppColors.starPurple),
                    ),
                    Row(
                      children: [
                        _NavButton(
                          icon: Icons.arrow_back_ios_new,
                          onTap: _highlighted > 0
                              ? () => setState(() => _highlighted--)
                              : null,
                        ),
                        const SizedBox(width: AppDimens.spacingS),
                        _NavButton(
                          icon: Icons.arrow_forward_ios,
                          onTap: _highlighted < _mockSentences.length - 1
                              ? () => setState(() => _highlighted++)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.starPurple : AppColors.lightCloudGray,
          borderRadius: AppDimens.brFull,
        ),
        child: Icon(icon, color: AppColors.pureWhite, size: 20),
      ),
    );
  }
}

