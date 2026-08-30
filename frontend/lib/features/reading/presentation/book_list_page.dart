import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';

class BookListPage extends StatefulWidget {
  const BookListPage({super.key});

  @override
  State<BookListPage> createState() => _BookListPageState();
}

class _BookListPageState extends State<BookListPage> {
  String _selectedLevel = 'L1';

  static const _levels = ['L1', 'L2', 'L3'];

  // Mock books for skeleton demo
  static const _mockBooks = [
    _MockBook(title: '小鹿的一天', level: 'L1', difficulty: 1, colorSeed: 0xFF9067ED),
    _MockBook(title: '我爱吃苹果', level: 'L1', difficulty: 1, colorSeed: 0xFFC490F9),
    _MockBook(title: '下雨天', level: 'L2', difficulty: 2, colorSeed: 0xFF6792BC),
    _MockBook(title: '去公园玩', level: 'L2', difficulty: 2, colorSeed: 0xFFE2ED8F),
    _MockBook(title: '手语故事集', level: 'L3', difficulty: 3, colorSeed: 0xFFFDB728),
    _MockBook(title: '成长的声音', level: 'L3', difficulty: 3, colorSeed: 0xFFF2C8F7),
  ];

  List<_MockBook> get _filteredBooks =>
      _mockBooks.where((b) => b.level == _selectedLevel).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.morningMist,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部标题行 + 呦呦占位
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('阅读书库', style: AppTextStyles.h2),
                  ),
                  // 呦呦 EatingLeaves 占位
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: AppColors.pureWhite,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.eco, size: 40, color: AppColors.sproutYellow),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.spacingM),
            // 年龄段 Tab 筛选
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: _levels.map((level) {
                  final active = level == _selectedLevel;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppDimens.spacingS),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedLevel = level),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: active ? AppColors.starPurple : AppColors.pureWhite,
                          borderRadius: AppDimens.brFull,
                          boxShadow: active
                              ? const [
                                  BoxShadow(
                                    color: Color(0x1E9067ED),
                                    blurRadius: 12,
                                    offset: Offset(0, 6),
                                  )
                                ]
                              : null,
                        ),
                        child: Text(
                          level,
                          style: AppTextStyles.body.copyWith(
                            color: active ? AppColors.pureWhite : AppColors.thinCloudGray,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppDimens.spacingL),
            // 书单 GridView
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppDimens.spacingM,
                  crossAxisSpacing: AppDimens.spacingM,
                  childAspectRatio: 3 / 4,
                ),
                itemCount: _filteredBooks.length,
                itemBuilder: (context, i) => _BookCard(book: _filteredBooks[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({required this.book});
  final _MockBook book;

  @override
  Widget build(BuildContext context) {
    final levelColor = switch (book.level) {
      'L1' => AppColors.cheeseYellow,
      'L2' => AppColors.starPurple,
      'L3' => AppColors.sproutYellow,
      _ => AppColors.lightCloudGray,
    };

    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D9067ED),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // 封面区域 70%
          Expanded(
            flex: 7,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Color(book.colorSeed).withValues(alpha: 0.2),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Center(
                    child: Icon(Icons.auto_stories, size: 56, color: Color(book.colorSeed)),
                  ),
                ),
                // 难度标签
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: levelColor,
                      borderRadius: AppDimens.brFull,
                    ),
                    child: Text(
                      book.level,
                      style: AppTextStyles.caption.copyWith(
                        color: book.level == 'L2' ? AppColors.pureWhite : AppColors.calmBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 标题区域 30%
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  book.title,
                  style: AppTextStyles.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MockBook {
  const _MockBook({
    required this.title,
    required this.level,
    required this.difficulty,
    required this.colorSeed,
  });
  final String title;
  final String level;
  final int difficulty;
  final int colorSeed;
}
