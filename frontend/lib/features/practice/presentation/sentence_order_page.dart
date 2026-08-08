import 'package:flutter/material.dart';

import '../../../shared/widgets/page_scaffold.dart';

class SentenceOrderPage extends StatelessWidget {
  const SentenceOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageScaffold(
      title: '句序练习',
      description: '这里将承载田字格、句序拼装与提示逻辑。',
    );
  }
}
