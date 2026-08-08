import 'package:flutter/material.dart';

import '../../../shared/widgets/page_scaffold.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageScaffold(
      title: '沟通',
      description: '这里将承载 SSE 沟通流、词卡状态机、麦克风与输入托盘。',
    );
  }
}
