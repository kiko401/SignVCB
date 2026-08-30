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

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
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
      ToastHost.show('注册失败，请稍后重试');
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
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              children: [
                const SizedBox(height: 36),
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.pureWhite,
                      borderRadius: AppDimens.brL1,
                    ),
                    child: const Icon(Icons.pets, size: 64, color: AppColors.starPurple),
                  ),
                ),
                const SizedBox(height: AppDimens.spacingXL),
                const Text(
                  '创建账号',
                  style: AppTextStyles.h2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimens.spacingXXL),
                AppTextInput(
                  controller: _usernameController,
                  hint: '用户名',
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppDimens.spacingM),
                AppTextInput(
                  controller: _passwordController,
                  hint: '密码',
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppDimens.spacingM),
                AppTextInput(
                  controller: _nicknameController,
                  hint: '昵称（选填）',
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: AppDimens.spacingM),
                // 年龄段选择器
                Container(
                  height: AppDimens.inputHeight,
                  decoration: BoxDecoration(
                    color: AppColors.cloudGray,
                    borderRadius: AppDimens.brL2,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _ageGroup,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.calmBlue),
                      style: AppTextStyles.body.copyWith(color: AppColors.calmBlue),
                      items: const [
                        DropdownMenuItem(
                          value: 'L1',
                          child: Text('L1 启蒙期'),
                        ),
                        DropdownMenuItem(
                          value: 'L2',
                          child: Text('L2 识字期'),
                        ),
                        DropdownMenuItem(
                          value: 'L3',
                          child: Text('L3 表达期'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _ageGroup = v ?? 'L2'),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimens.spacingXXL),
                PrimaryButton(
                  label: _submitting ? '注册中...' : '注册',
                  onPressed: _submitting ? null : _submit,
                  loading: _submitting,
                ),
                const SizedBox(height: AppDimens.spacingM),
                SecondaryButton(
                  label: '已有账号？去登录',
                  onPressed: () => context.go('/auth/login'),
                ),
                const SizedBox(height: AppDimens.spacingXXL),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
