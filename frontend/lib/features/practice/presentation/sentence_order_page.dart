import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/yuyu_avatar.dart';

class SentenceOrderPage extends StatefulWidget {
  const SentenceOrderPage({super.key});

  @override
  State<SentenceOrderPage> createState() => _SentenceOrderPageState();
}

class _SentenceOrderPageState extends State<SentenceOrderPage> {
  final List<Offset> _points = [];
  bool _showResult = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.morningMist,
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: '描字练习',
              onBack: () => context.go('/practice/map'),
              actions: [
                TextButton(
                  onPressed: () => setState(() {
                    _points.clear();
                    _showResult = false;
                  }),
                  child: Text(
                    '重置',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 13,
                      color: AppColors.starPurple,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 72,
                  height: 72,
                  child: YuyuAvatar(
                    width: 72,
                    height: 72,
                    animationName: 'Yuyu_HoldingBrush',
                    assetPath: 'assets/rive/yuyu.riv',
                    artboardName: 'yuyu_main',
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('跟着虚线',
                        style: AppTextStyles.body.copyWith(fontSize: 18)),
                    Text(
                      '描写这个字',
                      style: AppTextStyles.body.copyWith(
                        fontSize: 18,
                        color: AppColors.starPurple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: 320,
              height: 320,
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
              child: GestureDetector(
                onPanStart: (d) => setState(() => _points.add(d.localPosition)),
                onPanUpdate: (d) =>
                    setState(() => _points.add(d.localPosition)),
                onPanEnd: (_) {
                  setState(() => _points.add(Offset.infinite));
                  Future.delayed(const Duration(milliseconds: 700), () {
                    if (mounted) setState(() => _showResult = true);
                  });
                },
                child: CustomPaint(
                  painter: _TianZiGePainter(
                      points: _points, showResult: _showResult),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cloudGray,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tips_and_updates_rounded,
                        color: AppColors.starPurple, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '先描横竖，再慢慢连起来。',
                        style: AppTextStyles.caption.copyWith(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            if (_showResult)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.sproutYellow,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppColors.cheeseYellow, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        '写得很棒！',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.calmBlue,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

class _TianZiGePainter extends CustomPainter {
  const _TianZiGePainter({required this.points, required this.showResult});

  final List<Offset> points;
  final bool showResult;

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = AppColors.lightCloudGray
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final guidePaint = Paint()
      ..color = AppColors.cheeseYellow.withValues(alpha: 0.55)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final tracePaint = Paint()
      ..color = AppColors.calmBlue.withValues(alpha: 0.8)
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), borderPaint);
    canvas.drawLine(Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height), borderPaint);
    canvas.drawLine(Offset(0, size.height / 2),
        Offset(size.width, size.height / 2), borderPaint);
    canvas.drawLine(
        const Offset(0, 0), Offset(size.width, size.height), guidePaint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), guidePaint);

    final path = Path();
    bool moveTo = true;
    for (final p in points) {
      if (p == Offset.infinite) {
        moveTo = true;
      } else if (moveTo) {
        path.moveTo(p.dx, p.dy);
        moveTo = false;
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(path, tracePaint);
  }

  @override
  bool shouldRepaint(covariant _TianZiGePainter old) =>
      old.points != points || old.showResult != showResult;
}
