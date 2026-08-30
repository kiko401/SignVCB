import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';
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

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
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
      ToastHost.show('登录失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.morningMist,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.spacingXL,
              vertical: AppDimens.spacingL,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const YuyuAvatar(
                    width: 56,
                    height: 56,
                    animationName: 'Yuyu_HoldingTray',
                    assetPath: 'assets/rive/yuyu.riv',
                    artboardName: 'yuyu_main',
                  ),
                  const SizedBox(height: AppDimens.spacingM),
                  const Text('登录', style: AppTextStyles.h2),
                  const SizedBox(height: AppDimens.spacingL),
                  AppTextInput(
                    controller: _usernameController,
                    hint: '请输入用户名',
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppDimens.spacingL),
                  AppTextInput(
                    controller: _passwordController,
                    hint: '请输入密码',
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: AppDimens.spacingXL),
                  PrimaryButton(
                    label: _submitting ? '登录中…' : '登录',
                    onPressed: _submitting ? null : _submit,
                    loading: _submitting,
                  ),
                  const SizedBox(height: AppDimens.spacingM),
                  SecondaryButton(
                    label: '还没账号？去注册',
                    onPressed: () => context.go('/auth/register'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
