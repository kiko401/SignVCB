import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/secondary_button.dart';
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              // 呦呦 Sleeping 占位
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite,
                    borderRadius: AppDimens.brFull,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x149067ED),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.pets, size: 64, color: AppColors.starPurple),
                ),
              ),
              const SizedBox(height: AppDimens.spacingL),
              Text(username, style: AppTextStyles.h2),
              const SizedBox(height: AppDimens.spacingXS),
              _AgeGroupBadge(ageGroup: ageGroup),
              const SizedBox(height: AppDimens.spacingXXL),
              // 信息卡片
              _InfoCard(
                items: [
                  _InfoRow(label: '用户名', value: username),
                  _InfoRow(label: '学习阶段', value: _ageGroupLabel(ageGroup)),
                ],
              ),
              const SizedBox(height: AppDimens.spacingXXL),
              // 退出登录
              SecondaryButton(
                label: '退出登录',
                onPressed: () => ref.read(authProvider.notifier).logout(),
              ),
              const SizedBox(height: AppDimens.spacingXXL),
            ],
          ),
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
    final textColor = ageGroup == 'L2' ? AppColors.pureWhite : AppColors.calmBlue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppDimens.brFull,
      ),
      child: Text(
        ageGroup == 'L1'
            ? 'L1 启蒙期'
            : ageGroup == 'L2'
                ? 'L2 识字期'
                : 'L3 表达期',
        style: AppTextStyles.caption.copyWith(color: textColor, fontWeight: FontWeight.w600),
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
      padding: const EdgeInsets.all(AppDimens.spacingL),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: AppDimens.brL2,
        boxShadow: const [
          BoxShadow(
            color: Color(0x149067ED),
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
                  Text(item.label, style: AppTextStyles.caption),
                  Text(item.value, style: AppTextStyles.body),
                ],
              ),
              if (!isLast) ...[
                const SizedBox(height: AppDimens.spacingS),
                const Divider(color: AppColors.lightCloudGray, height: 1),
                const SizedBox(height: AppDimens.spacingS),
              ],
            ],
          );
        }).toList(),
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

