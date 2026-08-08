import 'package:flutter/material.dart';

import '../../../shared/widgets/page_scaffold.dart';

class ReadingContentPage extends StatelessWidget {
  const ReadingContentPage({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: '阅读内容',
      description: '当前书籍 ID：$bookId。这里将承载正文、TTS 与句子高亮。',
    );
  }
}
