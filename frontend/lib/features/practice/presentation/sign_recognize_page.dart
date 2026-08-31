import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/yuyu_avatar.dart';

class SignRecognizePage extends StatefulWidget {
  const SignRecognizePage({super.key});

  @override
  State<SignRecognizePage> createState() => _SignRecognizePageState();
}

class _SignRecognizePageState extends State<SignRecognizePage> {
  bool _recording = false;
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.morningMist,
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: '跟读练习',
              onBack: () => context.go('/practice/map'),
            ),
            const SizedBox(height: 16),
            const SizedBox(
              width: 72,
              height: 72,
              child: YuyuAvatar(
                width: 72,
                height: 72,
                animationName: 'Yuyu_Signing',
                assetPath: 'assets/rive/yuyu.riv',
                artboardName: 'yuyu_main',
              ),
            ),
            const SizedBox(height: 14),
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
              child: Column(
                children: [
                  Text('请跟读',
                      style: AppTextStyles.caption.copyWith(fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(
                    '我想吃苹果',
                    style: AppTextStyles.h1.copyWith(fontSize: 28),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AnimatedOpacity(
              opacity: _recording ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 180),
              child: Container(
                width: 152,
                height: 72,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.calmBlue,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (i) {
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 160 + i * 40),
                      width: 8,
                      height: _recording ? (18.0 + i * 6) : 8,
                      decoration: BoxDecoration(
                        color: i.isEven
                            ? AppColors.starPurple
                            : AppColors.cheeseYellow,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (_done)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.sproutYellow,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppColors.cheeseYellow, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        '读得很棒！',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.calmBlue,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const Spacer(),
            GestureDetector(
              onLongPressStart: (_) => setState(() {
                _recording = true;
                _done = false;
              }),
              onLongPressEnd: (_) {
                setState(() => _recording = false);
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) setState(() => _done = true);
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: _recording
                      ? AppColors.sproutYellow
                      : AppColors.starPurple,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_recording
                              ? AppColors.sproutYellow
                              : AppColors.starPurple)
                          .withValues(alpha: 0.35),
                      blurRadius: _recording ? 24 : 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  _recording ? Icons.mic : Icons.mic_none_rounded,
                  color: AppColors.pureWhite,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _recording ? '松手提交' : '长按录音',
              style: AppTextStyles.caption.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 22),
          ],
        ),
      ),
    );
  }
}
