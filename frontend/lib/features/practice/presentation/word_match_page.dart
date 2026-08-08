import 'package:flutter/material.dart';

import '../../../shared/widgets/page_scaffold.dart';

class WordMatchPage extends StatelessWidget {
  const WordMatchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageScaffold(
      title: '词图匹配',
      description: '这里将承载词卡拖拽、正确反馈与错误反馈。',
    );
  }
}
