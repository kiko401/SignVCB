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

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    try {
      await ref.read(authProvider.notifier).login(
            username: _usernameController.text.trim().isEmpty
                ? 'demo'
                : _usernameController.text.trim(),
            password: _passwordController.text.trim().isEmpty
                ? 'demo123'
                : _passwordController.text.trim(),
          );
      if (mounted) context.go('/chat');
    } catch (_) {
      ToastHost.show(
          '\u767b\u5f55\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5');
    } finally {
      if (mounted) setState(() => _submitting = false);
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
            const _LoginBackgroundDecor(),
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
                                width: 150,
                                height: 150,
                                animationName: 'Yuyu_HoldingTray',
                                assetPath: 'assets/rive/yuyu.riv',
                                artboardName: 'yuyu_main',
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\u767b\u5f55',
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
                                    const EdgeInsets.fromLTRB(18, 18, 18, 16),
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
                                      keyboardType: TextInputType.text,
                                      textInputAction: TextInputAction.next,
                                      contentFontSize: 18,
                                      prefixIcon: const Icon(
                                        Icons.person_rounded,
                                        color: AppColors.calmBlue,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    AppTextInput(
                                      controller: _passwordController,
                                      hint: '\u8bf7\u8f93\u5165\u5bc6\u7801',
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.done,
                                      onSubmitted: (_) => _submit(),
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
                                    const SizedBox(height: 18),
                                    PrimaryButton(
                                      label: _submitting
                                          ? '\u767b\u5f55\u4e2d\u2026'
                                          : '\u767b\u5f55',
                                      onPressed: _submitting ? null : _submit,
                                      loading: _submitting,
                                    ),
                                    const SizedBox(height: 12),
                                    Center(
                                      child: TextButton(
                                        onPressed: () =>
                                            context.go('/auth/register'),
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
                                                    '\u8fd8\u6ca1\u6709\u8d26\u53f7\uff1f',
                                                style: TextStyle(
                                                  color: AppColors.calmBlue
                                                      .withValues(alpha: 0.78),
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const TextSpan(text: ' '),
                                              const TextSpan(
                                                text: '\u53bb\u6ce8\u518c',
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

class _LoginBackgroundDecor extends StatelessWidget {
  const _LoginBackgroundDecor();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -70,
            left: -54,
            child: _GlowCircle(
              size: 174,
              color: AppColors.pureWhite.withValues(alpha: 0.34),
            ),
          ),
          Positioned(
            top: 104,
            right: -28,
            child: _GlowCircle(
              size: 98,
              color: AppColors.lilacPurple.withValues(alpha: 0.16),
            ),
          ),
          Positioned(
            left: 22,
            right: 22,
            bottom: 28,
            child: Container(
              height: 126,
              decoration: BoxDecoration(
                color: AppColors.pureWhite.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(40),
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
