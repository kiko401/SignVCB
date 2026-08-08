import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/page_scaffold.dart';
import '../../auth/application/auth_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageScaffold(
      title: '个人中心',
      description: '这里将承载用户信息、配置开关与退出登录入口。',
      action: FilledButton(
        onPressed: () => ref.read(authProvider.notifier).logout(),
        child: const Text('退出登录'),
      ),
    );
  }
}
