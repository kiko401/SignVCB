import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';

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
      appBar: AppBar(
        backgroundColor: AppColors.pureWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.calmBlue),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('跟读练习', style: AppTextStyles.h2),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppDimens.spacingXXL),
            // 呦呦 Signing 占位
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.pureWhite,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sign_language, size: 40, color: AppColors.starPurple),
              ),
            ),
            const SizedBox(height: AppDimens.spacingL),
            // 目标句子展示
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(AppDimens.spacingL),
              decoration: BoxDecoration(
                color: AppColors.pureWhite,
                borderRadius: AppDimens.brL2,
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
                  Text(
                    '请跟读：',
                    style: AppTextStyles.caption.copyWith(color: AppColors.thinCloudGray),
                  ),
                  const SizedBox(height: AppDimens.spacingXS),
                  const Text('我想吃苹果', style: AppTextStyles.h1, textAlign: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.spacingXXL),
            // 录音波形占位
            AnimatedOpacity(
              opacity: _recording ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 160,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.calmBlue,
                  borderRadius: AppDimens.brFull,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (i) {
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 200 + i * 60),
                      width: 8,
                      height: _recording ? (20.0 + i * 8) : 8,
                      decoration: BoxDecoration(
                        color: i.isEven ? AppColors.starPurple : AppColors.cheeseYellow,
                        borderRadius: AppDimens.brFull,
                      ),
                    );
                  }),
                ),
              ),
            ),
            if (_recording) const SizedBox(height: AppDimens.spacingXXL),
            const Spacer(),
            // 结果反馈
            if (_done)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Container(
                  padding: const EdgeInsets.all(AppDimens.spacingM),
                  decoration: BoxDecoration(
                    color: AppColors.sproutYellow,
                    borderRadius: AppDimens.brL2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_rounded, color: AppColors.cheeseYellow, size: 32),
                      const SizedBox(width: AppDimens.spacingS),
                      Text('读得很棒！',
                          style: AppTextStyles.body.copyWith(color: AppColors.calmBlue)),
                    ],
                  ),
                ),
              ),
            if (_done) const SizedBox(height: AppDimens.spacingL),
            // 麦克风按钮
            GestureDetector(
              onLongPressStart: (_) => setState(() {
                _recording = true;
                _done = false;
              }),
              onLongPressEnd: (_) {
                setState(() => _recording = false);
                Future.delayed(const Duration(milliseconds: 600),
                    () => mounted ? setState(() => _done = true) : null);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: AppDimens.micButtonSize,
                height: AppDimens.micButtonSize,
                decoration: BoxDecoration(
                  color: _recording ? AppColors.sproutYellow : AppColors.starPurple,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_recording ? AppColors.sproutYellow : AppColors.starPurple)
                          .withValues(alpha: 0.35),
                      blurRadius: _recording ? 28 : 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  _recording ? Icons.mic : Icons.mic_none,
                  color: AppColors.pureWhite,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: AppDimens.spacingXS),
            Text(
              _recording ? '松手提交' : '长按录音',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppDimens.spacingXXL),
          ],
        ),
      ),
    );
  }
}

