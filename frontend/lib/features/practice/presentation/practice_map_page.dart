import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/yuyu_avatar.dart';

class PracticeMapPage extends StatelessWidget {
  const PracticeMapPage({super.key});

  static const _nodes = [
    _NodeData(
      label: '拼图练习',
      subtitle: '找一找、拼一拼',
      route: '/practice/word_match',
      icon: Icons.extension_rounded,
      color: AppColors.starPurple,
      stars: 3,
      xAlign: -0.8,
    ),
    _NodeData(
      label: '描字练习',
      subtitle: '跟着线条写',
      route: '/practice/sentence_order',
      icon: Icons.draw_rounded,
      color: AppColors.calmBlue,
      stars: 1,
      xAlign: 0.8,
    ),
    _NodeData(
      label: '跟读练习',
      subtitle: '开口读一读',
      route: '/practice/sign_recognize',
      icon: Icons.mic_rounded,
      color: AppColors.sproutYellow,
      stars: 0,
      xAlign: -0.35,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.morningMist,
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: '练习地图',
              onBack: () => context.go('/chat'),
              actions: const [
                SizedBox(
                  width: 42,
                  height: 42,
                  child: YuyuAvatar(
                    width: 42,
                    height: 42,
                    animationName: 'Yuyu_Backflip',
                    assetPath: 'assets/rive/yuyu.riv',
                    artboardName: 'yuyu_main',
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: _PathPainter()),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (final node in _nodes)
                          Align(
                            alignment: Alignment(node.xAlign, 0),
                            child: _MapNode(node: node),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapNode extends StatelessWidget {
  const _MapNode({required this.node});

  final _NodeData node;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(node.route),
      child: Container(
        width: 238,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D9067ED),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [node.color.withValues(alpha: 0.85), node.color],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(node.icon, color: AppColors.pureWhite, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    node.label,
                    style: AppTextStyles.body.copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    node.subtitle,
                    style: AppTextStyles.caption.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: List.generate(3, (i) {
                      return Icon(
                        i < node.stars
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 18,
                        color: i < node.stars
                            ? AppColors.cheeseYellow
                            : AppColors.lightCloudGray,
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.lilacPurple.withValues(alpha: 0.45)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.25, size.height * 0.12)
      ..cubicTo(
        size.width * 0.55,
        size.height * 0.22,
        size.width * 0.45,
        size.height * 0.42,
        size.width * 0.72,
        size.height * 0.52,
      )
      ..cubicTo(
        size.width * 0.38,
        size.height * 0.67,
        size.width * 0.35,
        size.height * 0.82,
        size.width * 0.24,
        size.height * 0.92,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) => false;
}

class _NodeData {
  const _NodeData({
    required this.label,
    required this.subtitle,
    required this.route,
    required this.icon,
    required this.color,
    required this.stars,
    required this.xAlign,
  });

  final String label;
  final String subtitle;
  final String route;
  final IconData icon;
  final Color color;
  final int stars;
  final double xAlign;
}
