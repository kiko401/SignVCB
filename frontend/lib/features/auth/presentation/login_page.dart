import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/toast.dart';
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
            username: _usernameController.text.trim().isEmpty ? 'demo' : _usernameController.text.trim(),
            password: _passwordController.text.trim().isEmpty ? 'demo123' : _passwordController.text.trim(),
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
      appBar: AppBar(title: const Text('登录')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 24),
              const Text('欢迎回来', style: AppTextStyles.h2, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              TextField(controller: _usernameController, decoration: const InputDecoration(labelText: '用户名')),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: '密码'),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: Text(_submitting ? '登录中...' : '登录'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/auth/register'),
                child: const Text('还没有账号？去注册'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
