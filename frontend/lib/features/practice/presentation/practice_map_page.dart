import 'package:flutter/material.dart';

import '../../../shared/widgets/page_scaffold.dart';

class PracticeMapPage extends StatelessWidget {
  const PracticeMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageScaffold(
      title: '练习地图',
      description: '这里将展示关卡地图、节点状态与跳转逻辑。',
    );
  }
}
