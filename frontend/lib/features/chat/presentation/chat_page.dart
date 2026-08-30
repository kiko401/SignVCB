import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/application/auth_provider.dart';

class ChatPage extends ConsumerWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final nickname = user?.nickname ?? user?.username ?? '小朋友';

    return Scaffold(
      backgroundColor: AppColors.morningMist,
      appBar: AppBar(
        backgroundColor: AppColors.pureWhite,
        elevation: 0,
        title: const Text('默语共鸣', style: AppTextStyles.h2),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: AppDimens.avatarSizeS / 2,
              backgroundColor: AppColors.morningMist,
              child: Icon(Icons.pets, size: 22, color: AppColors.starPurple),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 消息列表区域
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.spacingM,
                vertical: AppDimens.spacingM,
              ),
              children: [
                // 欢迎气泡占位
                _YuyuWelcomeBubble(nickname: nickname),
                const SizedBox(height: AppDimens.spacingM),
                // 示意词卡行占位
                _PlaceholderCardRow(),
              ],
            ),
          ),
          // 底部输入区域
          _BottomInputArea(),
        ],
      ),
    );
  }
}

class _YuyuWelcomeBubble extends StatelessWidget {
  const _YuyuWelcomeBubble({required this.nickname});
  final String nickname;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 头像
        Container(
          width: AppDimens.avatarSizeS,
          height: AppDimens.avatarSizeS,
          decoration: const BoxDecoration(
            color: AppColors.morningMist,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.pets, size: 22, color: AppColors.starPurple),
        ),
        const SizedBox(width: AppDimens.spacingS),
        // 气泡
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.all(AppDimens.spacingM),
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
            child: Text(
              '你好，$nickname！我是呦呦，今天想说什么？',
              style: AppTextStyles.body,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlaceholderCardRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final words = ['我', '想', '吃', '苹果'];
    return Padding(
      padding: const EdgeInsets.only(left: AppDimens.avatarSizeS + AppDimens.spacingS),
      child: Wrap(
        spacing: AppDimens.spacingS,
        runSpacing: AppDimens.spacingS,
        children: words.map((w) => _WordCardPlaceholder(word: w)).toList(),
      ),
    );
  }
}

class _WordCardPlaceholder extends StatelessWidget {
  const _WordCardPlaceholder({required this.word});
  final String word;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppDimens.wordCardWidth,
      height: AppDimens.wordCardHeight,
      decoration: BoxDecoration(
        color: AppColors.cloudGray,
        borderRadius: AppDimens.brToast,
        boxShadow: const [
          BoxShadow(
            color: Color(0x089067ED),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Text(word, style: AppTextStyles.body),
      ),
    );
  }
}

class _BottomInputArea extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
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
            horizontal: AppDimens.spacingM,
            vertical: AppDimens.spacingS,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 拼装托盘占位
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.morningMist,
                  borderRadius: AppDimens.brL2,
                ),
                child: Row(
                  children: [
                    // 呦呦托盘插画占位
                    Padding(
                      padding: const EdgeInsets.all(AppDimens.spacingS),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: AppColors.pureWhite,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.pets, size: 28, color: AppColors.starPurple),
                      ),
                    ),
                    // 词卡区域
                    const Expanded(
                      child: Center(
                        child: Text('点击词卡拼装句子', style: AppTextStyles.caption),
                      ),
                    ),
                    // 发送按钮
                    Padding(
                      padding: const EdgeInsets.all(AppDimens.spacingS),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: AppColors.starPurple,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send, color: AppColors.pureWhite, size: 28),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.spacingS),
              // 麦克风按钮
              Center(
                child: Container(
                  width: AppDimens.micButtonSize,
                  height: AppDimens.micButtonSize,
                  decoration: const BoxDecoration(
                    color: AppColors.starPurple,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x1E9067ED),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.mic, color: AppColors.pureWhite, size: 40),
                ),
              ),
              const SizedBox(height: AppDimens.spacingXS),
            ],
          ),
        ),
      ),
    );
  }
}
