import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';

class SentenceOrderPage extends StatefulWidget {
  const SentenceOrderPage({super.key});

  @override
  State<SentenceOrderPage> createState() => _SentenceOrderPageState();
}

class _SentenceOrderPageState extends State<SentenceOrderPage> {
  // 画布笔迹点
  final List<Offset> _points = [];
  bool _showResult = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.morningMist,
      appBar: AppBar(
        backgroundColor: AppColors.pureWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.calmBlue),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('描字练习', style: AppTextStyles.h2),
        actions: [
          TextButton(
            onPressed: () => setState(() {
              _points.clear();
              _showResult = false;
            }),
            child: Text('重置',
                style: AppTextStyles.caption.copyWith(color: AppColors.starPurple)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppDimens.spacingL),
            // 呦呦 HoldingBrush 占位
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: AppColors.pureWhite,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.draw, size: 48, color: AppColors.calmBlue),
                ),
                const SizedBox(width: AppDimens.spacingM),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('跟着虚线', style: AppTextStyles.body),
                    Text('描写这个字', style: AppTextStyles.body.copyWith(color: AppColors.starPurple)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppDimens.spacingXL),
            // 田字格画布
            Center(
              child: SizedBox(
                width: 360,
                height: 360,
                child: GestureDetector(
                  onPanStart: (d) => setState(() => _points.add(d.localPosition)),
                  onPanUpdate: (d) => setState(() => _points.add(d.localPosition)),
                  onPanEnd: (_) {
                    setState(() => _points.add(Offset.infinite));
                    Future.delayed(const Duration(milliseconds: 800), () {
                      if (mounted) setState(() => _showResult = true);
                    });
                  },
                  child: CustomPaint(
                    painter: _TianZiGePainter(points: _points, showResult: _showResult),
                  ),
                ),
              ),
            ),
            const Spacer(),
            if (_showResult)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Container(
                  padding: const EdgeInsets.all(AppDimens.spacingM),
                  decoration: BoxDecoration(
                    color: AppColors.sproutYellow,
                    borderRadius: AppDimens.brL2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_rounded, color: AppColors.cheeseYellow, size: 32),
                      const SizedBox(width: AppDimens.spacingS),
                      Text('写得很棒！', style: AppTextStyles.body.copyWith(color: AppColors.calmBlue)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppDimens.spacingXXL),
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
      ..color = AppColors.cheeseYellow.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final tracePaint = Paint()
      ..color = AppColors.calmBlue.withValues(alpha: 0.8)
      ..strokeWidth = 20
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 田字格外框
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), borderPaint);
    // 田字格十字线（虚线效果用短横替代）
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), borderPaint);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), borderPaint);
    // 对角虚线引导
    canvas.drawLine(const Offset(0, 0), Offset(size.width, size.height), guidePaint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), guidePaint);

    // 手指笔迹
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

