import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/text_input.dart';
import '../../../shared/widgets/toast.dart';
import '../../../shared/widgets/yuyu_avatar.dart';
import '../application/auth_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();
  String _ageGroup = 'L2';
  bool _submitting = false;
  bool _obscurePassword = true;

  static const Map<String, String> _ageLabels = {
    'L1': '\u004c\u0031\u0020\u542f\u8499\u671f',
    'L2': '\u004c\u0032\u0020\u8bc6\u5b57\u671f',
    'L3': '\u004c\u0033\u0020\u8868\u8fbe\u671f',
  };

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    try {
      await ref.read(authProvider.notifier).register(
            username: _usernameController.text.trim().isEmpty
                ? 'demo'
                : _usernameController.text.trim(),
            password: _passwordController.text.trim().isEmpty
                ? 'demo123'
                : _passwordController.text.trim(),
            ageGroup: _ageGroup,
            nickname: _nicknameController.text.trim().isEmpty
                ? null
                : _nicknameController.text.trim(),
          );
      if (mounted) context.go('/chat');
    } catch (_) {
      ToastHost.show(
          '\u6ce8\u518c\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickAgeGroup() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.starPurple.withValues(alpha: 0.14),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\u9009\u62e9\u5e74\u9f84\u6bb5',
                  style: AppTextStyles.h2.copyWith(
                    fontSize: 22,
                    color: AppColors.calmBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ..._ageLabels.entries.map((entry) {
                  final active = entry.key == _ageGroup;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.of(context).pop(entry.key),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.morningMist
                              : AppColors.cloudGray.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active
                                ? AppColors.starPurple.withValues(alpha: 0.45)
                                : AppColors.lightCloudGray
                                    .withValues(alpha: 0.8),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.value,
                                style: AppTextStyles.body.copyWith(
                                  fontSize: 18,
                                  color: active
                                      ? AppColors.starPurple
                                      : AppColors.calmBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(
                              active
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              size: 22,
                              color: active
                                  ? AppColors.starPurple
                                  : AppColors.thinCloudGray,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() => _ageGroup = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.morningMist,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.morningMist,
              AppColors.morningMist,
              AppColors.pureWhite.withValues(alpha: 0.18),
            ],
            stops: const [0.0, 0.68, 1.0],
          ),
        ),
        child: Stack(
          children: [
            const _RegisterBackgroundDecor(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.spacingXL,
                      vertical: AppDimens.spacingL,
                    ),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 372),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 4),
                              const YuyuAvatar(
                                width: 168,
                                height: 168,
                                animationName: 'Yuyu_Welcome',
                                assetPath: 'assets/rive/yuyu.riv',
                                artboardName: 'yuyu_main',
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\u6ce8\u518c',
                                style: AppTextStyles.h2.copyWith(
                                  color: AppColors.calmBlue,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                  fontSize: 26,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding:
                                    const EdgeInsets.fromLTRB(18, 16, 18, 16),
                                decoration: BoxDecoration(
                                  color: AppColors.pureWhite
                                      .withValues(alpha: 0.82),
                                  borderRadius: BorderRadius.circular(32),
                                  border: Border.all(
                                    color: AppColors.pureWhite
                                        .withValues(alpha: 0.95),
                                    width: 1.4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.starPurple
                                          .withValues(alpha: 0.10),
                                      blurRadius: 34,
                                      offset: const Offset(0, 16),
                                    ),
                                    BoxShadow(
                                      color: AppColors.pureWhite
                                          .withValues(alpha: 0.55),
                                      blurRadius: 8,
                                      offset: const Offset(0, -2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    AppTextInput(
                                      controller: _usernameController,
                                      hint:
                                          '\u8bf7\u8f93\u5165\u7528\u6237\u540d',
                                      textInputAction: TextInputAction.next,
                                      keyboardType: TextInputType.text,
                                      contentFontSize: 18,
                                      prefixIcon: const Icon(
                                        Icons.person_rounded,
                                        color: AppColors.calmBlue,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    AppTextInput(
                                      controller: _passwordController,
                                      hint: '\u8bf7\u8f93\u5165\u5bc6\u7801',
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.next,
                                      contentFontSize: 18,
                                      prefixIcon: const Icon(
                                        Icons.lock_rounded,
                                        color: AppColors.calmBlue,
                                        size: 20,
                                      ),
                                      suffixIcon: IconButton(
                                        splashRadius: 17,
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: AppColors.thinCloudGray
                                              .withValues(alpha: 0.86),
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    AppTextInput(
                                      controller: _nicknameController,
                                      hint:
                                          '\u8bf7\u8f93\u5165\u6635\u79f0\uff08\u9009\u586b\uff09',
                                      textInputAction: TextInputAction.done,
                                      contentFontSize: 18,
                                      prefixIcon: const Icon(
                                        Icons.face_rounded,
                                        color: AppColors.calmBlue,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    InkWell(
                                      borderRadius: BorderRadius.circular(28),
                                      onTap: _pickAgeGroup,
                                      child: Ink(
                                        height: 58,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        decoration: BoxDecoration(
                                          color: AppColors.cloudGray
                                              .withValues(alpha: 0.58),
                                          borderRadius:
                                              BorderRadius.circular(28),
                                          border: Border.all(
                                            color: AppColors.pureWhite
                                                .withValues(alpha: 0.88),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '\u5e74\u9f84\u6bb5',
                                                style:
                                                    AppTextStyles.body.copyWith(
                                                  fontSize: 16,
                                                  color: AppColors.calmBlue,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 10,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    AppColors.lilacPurple,
                                                    AppColors.starPurple,
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColors.starPurple
                                                        .withValues(
                                                            alpha: 0.18),
                                                    blurRadius: 14,
                                                    offset: const Offset(0, 6),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    _ageLabels[_ageGroup]!,
                                                    style: AppTextStyles.body
                                                        .copyWith(
                                                      fontSize: 15,
                                                      color:
                                                          AppColors.pureWhite,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 2),
                                                  const Icon(
                                                    Icons.chevron_right_rounded,
                                                    size: 16,
                                                    color: AppColors.pureWhite,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    PrimaryButton(
                                      label: _submitting
                                          ? '\u6ce8\u518c\u4e2d\u2026'
                                          : '\u6ce8\u518c',
                                      onPressed: _submitting ? null : _submit,
                                      loading: _submitting,
                                    ),
                                    const SizedBox(height: 10),
                                    Center(
                                      child: TextButton(
                                        onPressed: () =>
                                            context.go('/auth/login'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppColors.starPurple,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: RichText(
                                          text: TextSpan(
                                            style:
                                                AppTextStyles.caption.copyWith(
                                              fontSize: 15,
                                              height: 1.2,
                                              color: AppColors.calmBlue
                                                  .withValues(alpha: 0.8),
                                            ),
                                            children: [
                                              TextSpan(
                                                text:
                                                    '\u5df2\u6709\u8d26\u53f7\uff1f',
                                                style: TextStyle(
                                                  color: AppColors.calmBlue
                                                      .withValues(alpha: 0.52),
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const TextSpan(text: ' '),
                                              const TextSpan(
                                                text: '\u53bb\u767b\u5f55',
                                                style: TextStyle(
                                                  color: AppColors.starPurple,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegisterBackgroundDecor extends StatelessWidget {
  const _RegisterBackgroundDecor();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -72,
            left: -50,
            child: _GlowCircle(
              size: 168,
              color: AppColors.pureWhite.withValues(alpha: 0.34),
            ),
          ),
          Positioned(
            top: 126,
            right: -30,
            child: _GlowCircle(
              size: 96,
              color: AppColors.lilacPurple.withValues(alpha: 0.14),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 30,
            child: Container(
              height: 132,
              decoration: BoxDecoration(
                color: AppColors.pureWhite.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(42),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
