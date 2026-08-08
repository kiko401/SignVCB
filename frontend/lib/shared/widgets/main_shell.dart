import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  static const List<_TabItem> _tabs = [
    _TabItem(path: '/chat', label: '沟通', icon: Icons.chat_bubble_outline),
    _TabItem(path: '/reading/books', label: '阅读', icon: Icons.menu_book_outlined),
    _TabItem(path: '/practice/map', label: '练习', icon: Icons.flag_outlined),
    _TabItem(path: '/profile', label: '我的', icon: Icons.person_outline),
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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -2)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 68,
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: InkWell(
                      onTap: () => context.go(_tabs[i].path),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _tabs[i].icon,
                            size: 24,
                            color: i == index ? AppColors.starPurple : AppColors.thinCloudGray,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _tabs[i].label,
                            style: TextStyle(
                              fontSize: 12,
                              color: i == index ? AppColors.starPurple : AppColors.thinCloudGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
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
