import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';

class PracticeMapPage extends StatelessWidget {
  const PracticeMapPage({super.key});

  static const _nodes = [
    _NodeData(label: '拼图练习', route: '/practice/word_match', icon: Icons.extension, color: AppColors.starPurple),
    _NodeData(label: '描字练习', route: '/practice/sentence_order', icon: Icons.edit, color: AppColors.calmBlue),
    _NodeData(label: '跟读练习', route: '/practice/sign_recognize', icon: Icons.mic, color: AppColors.sproutYellow),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.morningMist,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部标题 + 呦呦占位
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
              child: Row(
                children: [
                  const Expanded(child: Text('练习地图', style: AppTextStyles.h2)),
                  // 呦呦 Backflip 占位
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppColors.pureWhite,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.directions_run, size: 36, color: AppColors.starPurple),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.spacingL),
            // 地图主体
            Expanded(
              child: Stack(
                children: [
                  // 路径曲线
                  Positioned.fill(
                    child: CustomPaint(painter: _PathPainter()),
                  ),
                  // 节点列
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (var i = 0; i < _nodes.length; i++)
                          _MapNode(
                            node: _nodes[i],
                            stars: i == 0 ? 3 : i == 1 ? 1 : 0,
                            alignRight: i.isOdd,
                          ),
                      ],
                    ),
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

class _MapNode extends StatelessWidget {
  const _MapNode({required this.node, required this.stars, required this.alignRight});
  final _NodeData node;
  final int stars;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Column(
          children: [
            // 节点圆圈
            GestureDetector(
              onTap: () => Navigator.of(context).pushNamed(node.route),
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [node.color.withValues(alpha: 0.8), node.color],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: node.color.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppColors.pureWhite,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(node.icon, size: 32, color: node.color),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.spacingXS),
            Text(node.label, style: AppTextStyles.caption.copyWith(color: AppColors.calmBlue)),
            const SizedBox(height: AppDimens.spacingXS),
            // 星星评分
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: AppDimens.starSize,
                    color: i < stars ? AppColors.cheeseYellow : AppColors.lightCloudGray,
                  ),
                );
              }),
            ),
          ],
        ),
      ],
    );
  }
}

class _PathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final third = size.height / 4;
    path.moveTo(size.width * 0.25, third);
    path.cubicTo(
      size.width * 0.1, third * 1.5,
      size.width * 0.9, third * 1.5,
      size.width * 0.75, third * 2,
    );
    path.cubicTo(
      size.width * 0.9, third * 2.5,
      size.width * 0.1, third * 2.5,
      size.width * 0.25, third * 3,
    );

    // 虚线效果
    final dashPaint = Paint()
      ..color = AppColors.lilacPurple.withValues(alpha: 0.4)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, dashPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NodeData {
  const _NodeData({required this.label, required this.route, required this.icon, required this.color});
  final String label;
  final String route;
  final IconData icon;
  final Color color;
}
