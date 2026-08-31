import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/yuyu_avatar.dart';
import '../application/reading_provider.dart';
import '../data/reading_models.dart';

class BookListPage extends ConsumerStatefulWidget {
  const BookListPage({super.key});

  @override
  ConsumerState<BookListPage> createState() => _BookListPageState();
}

class _BookListPageState extends ConsumerState<BookListPage> {
  static const _levels = ['L1', 'L2', 'L3'];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(readingBooksProvider);

    return Scaffold(
      backgroundColor: AppColors.morningMist,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              title: '阅读书库',
              centerTitle: true,
              actions: [
                _EatingLeavesAvatar(),
              ],
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  for (final level in _levels) ...[
                    _LevelTab(
                      level: level,
                      selected: level == state.selectedAgeGroup,
                      onTap: () => ref
                          .read(readingBooksProvider.notifier)
                          .selectAgeGroup(level),
                    ),
                    if (level != _levels.last) const SizedBox(width: 10),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: _BooksContent(
                state: state,
                onRetry: () =>
                    ref.read(readingBooksProvider.notifier).loadBooks(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EatingLeavesAvatar extends StatelessWidget {
  const _EatingLeavesAvatar();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 42,
      height: 42,
      child: YuyuAvatar(
        width: 42,
        height: 42,
        animationName: 'Yuyu_EatingLeaves',
        assetPath: 'assets/rive/yuyu.riv',
        artboardName: 'yuyu_main',
      ),
    );
  }
}

class _LevelTab extends StatelessWidget {
  const _LevelTab({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  final String level;
  final bool selected;
  final VoidCallback onTap;

  Color get _accentColor => switch (level) {
        'L1' => AppColors.cheeseYellow,
        'L2' => AppColors.starPurple,
        'L3' => AppColors.sproutYellow,
        _ => AppColors.starPurple,
      };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$level 阅读等级',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _accentColor : AppColors.pureWhite,
            borderRadius: AppDimens.brFull,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _accentColor.withValues(alpha: 0.34),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Text(
            level,
            style: AppTextStyles.body.copyWith(
              fontSize: 16,
              height: 1,
              fontWeight: FontWeight.w700,
              color: selected && level == 'L2'
                  ? AppColors.pureWhite
                  : AppColors.calmBlue,
            ),
          ),
        ),
      ),
    );
  }
}

class _BooksContent extends StatelessWidget {
  const _BooksContent({required this.state, required this.onRetry});

  final ReadingBooksState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      child: switch (state.status) {
        ReadingBooksStatus.initial ||
        ReadingBooksStatus.loading =>
          const _BooksLoading(key: ValueKey('loading')),
        ReadingBooksStatus.empty => _BooksEmpty(
            key: const ValueKey('empty'),
            level: state.selectedAgeGroup,
          ),
        ReadingBooksStatus.error => _BooksError(
            key: const ValueKey('error'),
            message: state.errorMessage ?? '书库加载失败，请稍后再试',
            onRetry: onRetry,
          ),
        ReadingBooksStatus.data => _BooksGrid(
            key: const ValueKey('data'),
            books: state.books,
          ),
      },
    );
  }
}

class _BooksGrid extends StatelessWidget {
  const _BooksGrid({super.key, required this.books});

  final List<ReadingBook> books;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 14,
        childAspectRatio: 3 / 4,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) => _BookCard(book: books[index]),
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({required this.book});

  final ReadingBook book;

  Color get _levelColor => switch (book.ageGroup) {
        'L1' => AppColors.cheeseYellow,
        'L2' => AppColors.starPurple,
        'L3' => AppColors.sproutYellow,
        _ => AppColors.lightCloudGray,
      };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '打开《${book.title}》',
      child: Material(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shadowColor: AppColors.starPurple.withValues(alpha: 0.2),
        child: InkWell(
          onTap: () => context.push('/reading/content/${book.id}'),
          splashColor: AppColors.lilacPurple.withValues(alpha: 0.16),
          highlightColor: AppColors.lilacPurple.withValues(alpha: 0.08),
          child: Column(
            children: [
              Expanded(
                flex: 7,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _BookCover(book: book),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _LevelBadge(
                        level: book.ageGroup,
                        color: _levelColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 10, 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      book.title,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 15,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookCover extends StatelessWidget {
  const _BookCover({required this.book});

  final ReadingBook book;

  @override
  Widget build(BuildContext context) {
    final coverUrl = book.coverUrl?.trim();
    final image = coverUrl == null || coverUrl.isEmpty
        ? const _LocalCoverFallback()
        : coverUrl.startsWith('assets/')
            ? SvgPicture.asset(
                coverUrl,
                fit: BoxFit.cover,
                placeholderBuilder: (_) => const _LocalCoverFallback(),
              )
            : Image.network(
                coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _LocalCoverFallback(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const _LocalCoverFallback(showLoading: true);
                },
              );

    return Hero(
      tag: 'reading-book-${book.id}',
      child: ColoredBox(
        color: AppColors.cloudGray,
        child: image,
      ),
    );
  }
}

class _LocalCoverFallback extends StatelessWidget {
  const _LocalCoverFallback({this.showLoading = false});

  final bool showLoading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.lilacPurple, AppColors.morningMist],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: -16,
            bottom: -8,
            child: Opacity(
              opacity: 0.92,
              child: SizedBox(
                width: 116,
                height: 116,
                child: SvgPicture.asset(
                  'assets/svg/yuyu/Yuyu_EatingLeaves1.svg',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          if (showLoading)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.pureWhite,
              ),
            ),
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level, required this.color});

  final String level;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppDimens.brFull,
      ),
      child: Text(
        level,
        style: AppTextStyles.caption.copyWith(
          fontSize: 13,
          height: 1,
          fontWeight: FontWeight.w700,
          color: level == 'L2' ? AppColors.pureWhite : AppColors.calmBlue,
        ),
      ),
    );
  }
}

class _BooksLoading extends StatelessWidget {
  const _BooksLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 14,
        childAspectRatio: 3 / 4,
      ),
      itemCount: 4,
      itemBuilder: (_, __) => const _BookSkeleton(),
    );
  }
}

class _BookSkeleton extends StatelessWidget {
  const _BookSkeleton();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.pureWhite.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 7,
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.cloudGray.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.lilacPurple,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                height: 14,
                margin: const EdgeInsets.fromLTRB(14, 0, 28, 12),
                decoration: BoxDecoration(
                  color: AppColors.cloudGray,
                  borderRadius: AppDimens.brFull,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BooksEmpty extends StatelessWidget {
  const _BooksEmpty({super.key, required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    return _BooksMessage(
      icon: Icons.auto_stories_rounded,
      title: '$level 还没有故事哦',
      message: '换一个阅读阶段试试看吧。',
    );
  }
}

class _BooksError extends StatelessWidget {
  const _BooksError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _BooksMessage(
      icon: Icons.cloud_off_rounded,
      title: '书库暂时打不开',
      message: message,
      action: FilledButton.tonal(
        onPressed: onRetry,
        style: FilledButton.styleFrom(
          foregroundColor: AppColors.starPurple,
          backgroundColor: AppColors.pureWhite,
        ),
        child: const Text('重新加载'),
      ),
    );
  }
}

class _BooksMessage extends StatelessWidget {
  const _BooksMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: AppColors.pureWhite,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 38, color: AppColors.lilacPurple),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(fontSize: 14),
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
