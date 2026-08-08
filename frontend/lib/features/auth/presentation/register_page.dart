import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
            username: _usernameController.text.trim().isEmpty ? 'demo' : _usernameController.text.trim(),
            password: _passwordController.text.trim().isEmpty ? 'demo123' : _passwordController.text.trim(),
            ageGroup: _ageGroup,
            nickname: _nicknameController.text.trim().isEmpty ? null : _nicknameController.text.trim(),
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
      appBar: AppBar(title: const Text('注册')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TextField(controller: _usernameController, decoration: const InputDecoration(labelText: '用户名')),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: '密码'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(controller: _nicknameController, decoration: const InputDecoration(labelText: '昵称')),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _ageGroup,
                items: const [
                  DropdownMenuItem(value: 'L1', child: Text('L1 启蒙期')),
                  DropdownMenuItem(value: 'L2', child: Text('L2 识字期')),
                  DropdownMenuItem(value: 'L3', child: Text('L3 表达期')),
                ],
                onChanged: (value) => setState(() => _ageGroup = value ?? 'L2'),
                decoration: const InputDecoration(labelText: '年龄段'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: Text(_submitting ? '注册中...' : '注册'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
