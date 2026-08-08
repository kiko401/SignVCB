import 'package:flutter/material.dart';

import '../../../shared/widgets/page_scaffold.dart';

class SignRecognizePage extends StatelessWidget {
  const SignRecognizePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageScaffold(
      title: '跟读练习',
      description: '这里将承载录音、波形、ASR 对比与结果反馈。',
    );
  }
}
