import 'package:flutter/material.dart';

import '../../../shared/widgets/page_scaffold.dart';

class BookListPage extends StatelessWidget {
  const BookListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageScaffold(
      title: '阅读书库',
      description: '这里将展示分级书单、封面卡片与年龄段筛选。',
    );
  }
}
