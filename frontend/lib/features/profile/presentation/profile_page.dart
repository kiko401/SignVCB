import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/secondary_button.dart';
import '../../../shared/widgets/yuyu_avatar.dart';
import '../../auth/application/auth_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final username = user?.username ?? '—';
    final ageGroup = user?.ageGroup ?? '—';

    return Scaffold(
      backgroundColor: AppColors.morningMist,
      body: SafeArea(
        child: Column(
          children: [
            const PageHeader(title: '我的', centerTitle: true),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                child: Column(
                  children: [
                    const SizedBox(
                      width: 96,
                      height: 96,
                      child: YuyuAvatar(
                        width: 96,
                        height: 96,
                        animationName: 'Yuyu_Sleeping',
                        assetPath: 'assets/rive/yuyu.riv',
                        artboardName: 'yuyu_main',
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      username,
                      style: AppTextStyles.h2.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 8),
                    _AgeGroupBadge(ageGroup: ageGroup),
                    const SizedBox(height: 20),
                    _InfoCard(
                      items: [
                        _InfoRow(label: '用户名', value: username),
                        _InfoRow(
                            label: '学习阶段', value: _ageGroupLabel(ageGroup)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _ProgressCard(ageGroup: ageGroup),
                    const SizedBox(height: 20),
                    SecondaryButton(
                      label: '退出登录',
                      onPressed: () => ref.read(authProvider.notifier).logout(),
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

  String _ageGroupLabel(String ageGroup) {
    switch (ageGroup) {
      case 'L1':
        return 'L1 启蒙期';
      case 'L2':
        return 'L2 识字期';
      case 'L3':
        return 'L3 表达期';
      default:
        return ageGroup;
    }
  }
}

class _AgeGroupBadge extends StatelessWidget {
  const _AgeGroupBadge({required this.ageGroup});

  final String ageGroup;

  @override
  Widget build(BuildContext context) {
    final color = switch (ageGroup) {
      'L1' => AppColors.cheeseYellow,
      'L2' => AppColors.starPurple,
      'L3' => AppColors.sproutYellow,
      _ => AppColors.lightCloudGray,
    };
    final textColor =
        ageGroup == 'L2' ? AppColors.pureWhite : AppColors.calmBlue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        ageGroup == 'L1'
            ? 'L1 启蒙期'
            : ageGroup == 'L2'
                ? 'L2 识字期'
                : 'L3 表达期',
        style: AppTextStyles.caption.copyWith(
          fontSize: 12,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.items});

  final List<_InfoRow> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
        children: items.map((item) {
          final isLast = item == items.last;
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item.label,
                      style: AppTextStyles.caption.copyWith(fontSize: 12)),
                  Text(item.value,
                      style: AppTextStyles.body.copyWith(fontSize: 16)),
                ],
              ),
              if (!isLast) ...[
                const SizedBox(height: 10),
                const Divider(color: AppColors.lightCloudGray, height: 1),
                const SizedBox(height: 10),
              ],
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.ageGroup});

  final String ageGroup;

  @override
  Widget build(BuildContext context) {
    final progress = switch (ageGroup) {
      'L1' => 0.72,
      'L2' => 0.56,
      'L3' => 0.43,
      _ => 0.2,
    };

    return Container(
      width: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('鹿角成长', style: AppTextStyles.body.copyWith(fontSize: 16)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress,
              backgroundColor: AppColors.cloudGray,
              color: AppColors.starPurple,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '今天也在慢慢长大',
            style: AppTextStyles.caption.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _InfoRow {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is _InfoRow && other.label == label);

  @override
  int get hashCode => label.hashCode;
}
