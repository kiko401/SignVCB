import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/yuyu_avatar.dart';
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
    super.initState();
    _timer = Timer(const Duration(seconds: 2), _redirect);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _redirect() {
    if (!mounted) return;
    final status = ref.read(authProvider).status;
    if (status == AuthStatus.initial) {
      _timer = Timer(const Duration(milliseconds: 300), _redirect);
      return;
    }
    context.go(status == AuthStatus.authenticated ? '/chat' : '/auth/login');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status != AuthStatus.initial) _redirect();
    });

    return Scaffold(
      backgroundColor: AppColors.morningMist,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const YuyuAvatar(
                width: 260,
                height: 260,
                animationName: 'Yuyu_Welcome',
                assetPath: 'assets/rive/yuyu.riv',
                artboardName: 'yuyu_main',
              ),
              const SizedBox(height: AppDimens.spacingXXL),
              const Text(
                '听见你的声音\n看见你的世界',
                style: AppTextStyles.display,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
