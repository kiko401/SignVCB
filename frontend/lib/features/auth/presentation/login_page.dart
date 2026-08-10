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
  
  /*
   * @func: dispose
   * @description: 页面销毁时释放输入控制器资源，避免内存泄漏
   */
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /*
   * @func: _submit
   * @description: 获取表单账号密码，调用全局登录方法；成功跳转聊天页，失败弹出提示
   * @return: {Future<void>} 异步登录任务
   */
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
  Widget build(BuildContext context) {//build 页面 UI 搭建函数
    return Scaffold(//页面基础脚手架，自带顶部导航栏 appBar
      appBar: AppBar(title: const Text('登录')),
      body: Center(
        child: ConstrainedBox(//限制表单最大宽度，平板、大屏手机表单不会拉得很宽
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(//可滚动布局，防止小屏幕输入框被键盘顶起报错
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
                onPressed: _submitting ? null : _submit,//正在提交登录时 onPressed 设置为 null，按钮禁用；按钮文字切换「登录中…」
                child: Text(_submitting ? '登录中...' : '登录'),
              ),
              const SizedBox(height: 12),
              TextButton(//点击后 `context.go('/auth/register')`，使用 go‑router 跳转到注册页面
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
