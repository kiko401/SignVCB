import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/profile/application/config_provider.dart';
import 'shared/widgets/toast.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MoyuApp()));
}

class MoyuApp extends ConsumerStatefulWidget {
  const MoyuApp({super.key});

  @override
  ConsumerState<MoyuApp> createState() => _MoyuAppState();
}

class _MoyuAppState extends ConsumerState<MoyuApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(configProvider.notifier).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    return ToastHost(
      child: MaterialApp.router(
        title: '默语共鸣',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: router,
      ),
    );
  }
}
