import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../application/auth_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  Timer? _timer;

  @override
  void initState() {
    //`initState` 页面刚创建完毕立刻执行
    super.initState(); //等待 3 秒之后执行跳转函数 _maybeRedirect
    _timer = Timer(const Duration(seconds: 3), _maybeRedirect);
  }

  /*
   * @func: dispose
   * @description: 页面关闭时取消定时器，防止定时器后台执行引发报错
   * @return {*}
   */
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /*
   * @func: _maybeRedirect
   * @description: 根据认证状态决定跳转页面
   */
  void _maybeRedirect() {
    if (!mounted) return; //页面已经关闭，直接终止后续代码
    final status = ref.read(authProvider).status; //读取全局登录状态
    if (status == AuthStatus.initial) {
      //初始化，正在读取本地缓存；
      _timer = Timer(const Duration(milliseconds: 500), _maybeRedirect);
      return;
    }
    if (status == AuthStatus.authenticated) {
      //用户已经登录
      context.go('/chat');
    } else {
      //没有登录
      context.go('/auth/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (next.status != AuthStatus.initial) {
        _maybeRedirect();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.morningMist,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  color: AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(36),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.pets,
                    size: 88, color: AppColors.starPurple),
              ),
              const SizedBox(height: 32),
              const Text(
                '听见你的声音，看见你的世界',
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.starPurple),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
