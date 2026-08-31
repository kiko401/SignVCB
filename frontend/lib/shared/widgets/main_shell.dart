import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  static const List<_TabItem> _tabs = [
    _TabItem(path: '/chat', label: '沟通', icon: Icons.chat_bubble_outline),
    _TabItem(path: '/reading/books', label: '阅读', icon: Icons.menu_book_rounded),
    _TabItem(path: '/practice/map', label: '练习', icon: Icons.radio_button_checked_rounded),
    _TabItem(path: '/profile', label: '我的', icon: Icons.person_outline_rounded),
  ];

  int _indexFor(String location) {
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _indexFor(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.pureWhite,
            boxShadow: [
              BoxShadow(
                color: AppColors.starPurple.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: SizedBox(
              height: 66,
              child: Row(
                children: [
                  for (var i = 0; i < _tabs.length; i++)
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => context.go(_tabs[i].path),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: i == index
                                ? AppColors.morningMist.withValues(alpha: 0.85)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                i == index
                                    ? _tabs[i].icon
                                    : _tabs[i].icon,
                                size: i == index ? 26 : 24,
                                color: i == index
                                    ? AppColors.starPurple
                                    : AppColors.thinCloudGray,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _tabs[i].label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: i == index ? FontWeight.w600 : FontWeight.w400,
                                  color: i == index
                                      ? AppColors.starPurple
                                      : AppColors.thinCloudGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({required this.path, required this.label, required this.icon});

  final String path;
  final String label;
  final IconData icon;
}
