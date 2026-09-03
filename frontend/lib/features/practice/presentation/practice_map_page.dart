import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

class PracticeMapPage extends StatelessWidget {
  const PracticeMapPage({super.key});

  static const _nodes = [
    _PracticeNodeData(
      title: '拼图关',
      subtitle: '拖一拖，拼一拼',
      route: '/practice/word_match',
      center: Offset(0.22, 0.18),
      state: _PracticeNodeState.completed,
      accent: AppColors.cheeseYellow,
      kind: _PracticeNodeKind.puzzle,
    ),
    _PracticeNodeData(
      title: '田字格 · 当前',
      subtitle: '描一描，写一写',
      route: '/practice/sentence_order',
      center: Offset(0.37, 0.35),
      state: _PracticeNodeState.current,
      accent: AppColors.starPurple,
      kind: _PracticeNodeKind.grid,
    ),
    _PracticeNodeData(
      title: '跟读关',
      subtitle: '开口试一试',
      route: '/practice/sign_recognize',
      center: Offset(0.58, 0.52),
      state: _PracticeNodeState.completed,
      accent: AppColors.sproutYellow,
      kind: _PracticeNodeKind.voice,
    ),
    _PracticeNodeData(
      title: '识字关',
      subtitle: '再往前一步',
      route: '/practice/word_match',
      center: Offset(0.74, 0.68),
      state: _PracticeNodeState.completed,
      accent: AppColors.lilacPurple,
      kind: _PracticeNodeKind.reading,
    ),
    _PracticeNodeData(
      title: '进阶关',
      subtitle: '继续前进',
      route: '/practice/sentence_order',
      center: Offset(0.28, 0.84),
      state: _PracticeNodeState.completed,
      accent: AppColors.sakuraPink,
      kind: _PracticeNodeKind.trophy,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.morningMist,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);

            return Stack(
              children: [
                const Positioned.fill(child: _PracticeMapBackdrop()),
                const Positioned.fill(
                  child: CustomPaint(
                    painter: _PracticeMapPathPainter(nodes: _nodes),
                  ),
                ),
                Positioned(
                  top: 6,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Text(
                        '练习地图',
                        style: TextStyle(
                          color: AppColors.starPurple.withValues(alpha: 0.92),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '沿路往前进，解锁更多关卡',
                        style: TextStyle(
                          color:
                              AppColors.textSecondary.withValues(alpha: 0.78),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                ..._buildDecorations(size),
                ..._nodes.map((node) => _buildNode(context, size, node)),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildDecorations(Size size) {
    return [
      Positioned(
        left: size.width * 0.03,
        top: size.height * 0.11,
        child: _CloudGlow(
          size: 92,
          color: AppColors.pureWhite.withValues(alpha: 0.28),
        ),
      ),
      Positioned(
        right: size.width * 0.02,
        top: size.height * 0.24,
        child: _CloudGlow(
          size: 82,
          color: AppColors.pureWhite.withValues(alpha: 0.22),
        ),
      ),
      Positioned(
        left: size.width * 0.05,
        bottom: size.height * 0.16,
        child: _CloudGlow(
          size: 76,
          color: AppColors.pureWhite.withValues(alpha: 0.22),
        ),
      ),
      Positioned(
        left: size.width * 0.16,
        top: size.height * 0.29,
        child: const _DiamondDot(color: AppColors.cheeseYellow, size: 22),
      ),
      Positioned(
        left: size.width * 0.40,
        top: size.height * 0.45,
        child: const _DiamondDot(color: AppColors.cheeseYellow, size: 20),
      ),
      Positioned(
        left: size.width * 0.57,
        top: size.height * 0.44,
        child: const _DiamondDot(color: AppColors.sproutYellow, size: 20),
      ),
      Positioned(
        left: size.width * 0.67,
        top: size.height * 0.50,
        child: const _DiamondDot(color: AppColors.lightCloudGray, size: 18),
      ),
      Positioned(
        left: size.width * 0.46,
        top: size.height * 0.62,
        child: const _DiamondDot(color: AppColors.lightCloudGray, size: 16),
      ),
      Positioned(
        left: size.width * 0.69,
        top: size.height * 0.60,
        child: const _DiamondDot(color: AppColors.lightCloudGray, size: 16),
      ),
    ];
  }

  Widget _buildNode(BuildContext context, Size size, _PracticeNodeData node) {
    final diameter = node.state == _PracticeNodeState.current ? 84.0 : 78.0;
    final centerLeft = size.width * node.center.dx;
    final centerTop = size.height * node.center.dy;

    return Positioned(
      left: centerLeft - diameter / 2,
      top: centerTop - diameter / 2,
      child: GestureDetector(
        onTap: () => context.go(node.route),
        child: SizedBox(
          width: diameter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PracticeNodeCircle(node: node, diameter: diameter),
              const SizedBox(height: 8),
              Text(
                node.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: node.state == _PracticeNodeState.current
                      ? AppColors.starPurple
                      : AppColors.calmBlue.withValues(alpha: 0.96),
                  fontSize: 13,
                  fontWeight: node.state == _PracticeNodeState.current
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                node.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.95),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PracticeMapBackdrop extends StatelessWidget {
  const _PracticeMapBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.morningMist.withValues(alpha: 0.96),
            AppColors.morningMist,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -24,
            top: 90,
            child: _BlurCircle(
              diameter: 110,
              color: AppColors.pureWhite.withValues(alpha: 0.35),
            ),
          ),
          Positioned(
            right: -18,
            top: 200,
            child: _BlurCircle(
              diameter: 92,
              color: AppColors.pureWhite.withValues(alpha: 0.26),
            ),
          ),
          Positioned(
            left: 24,
            bottom: 110,
            child: _BlurCircle(
              diameter: 80,
              color: AppColors.pureWhite.withValues(alpha: 0.24),
            ),
          ),
        ],
      ),
    );
  }
}

class _CloudGlow extends StatelessWidget {
  const _CloudGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 40, spreadRadius: 10)],
      ),
    );
  }
}

class _BlurCircle extends StatelessWidget {
  const _BlurCircle({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 30,
            spreadRadius: 8,
          ),
        ],
      ),
    );
  }
}

class _DiamondDot extends StatelessWidget {
  const _DiamondDot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: math.pi / 4,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(size * 0.18),
        ),
      ),
    );
  }
}

class _PracticeNodeCircle extends StatelessWidget {
  const _PracticeNodeCircle({required this.node, required this.diameter});

  final _PracticeNodeData node;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final isCurrent = node.state == _PracticeNodeState.current;
    final isCompleted = node.state == _PracticeNodeState.completed;

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.pureWhite,
        boxShadow: [
          BoxShadow(
            color: node.accent.withValues(alpha: isCurrent ? 0.24 : 0.16),
            blurRadius: isCurrent ? 24 : 18,
            spreadRadius: isCurrent ? 4 : 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: diameter - 10,
            height: diameter - 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isCurrent
                    ? AppColors.starPurple
                    : node.accent.withValues(alpha: 0.72),
                width: isCurrent ? 3.0 : 2.2,
              ),
              gradient: RadialGradient(
                colors: [
                  AppColors.pureWhite,
                  node.accent.withValues(alpha: isCompleted ? 0.18 : 0.12),
                ],
              ),
            ),
          ),
          Container(
            width: diameter - 22,
            height: diameter - 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: node.accent.withValues(alpha: isCurrent ? 0.16 : 0.12),
            ),
          ),
          _StageIcon(
            kind: node.kind,
            accent: node.accent,
            isCurrent: isCurrent,
            isLocked: node.state == _PracticeNodeState.locked,
          ),
          if (isCurrent)
            Positioned(
              top: 6,
              child: Container(
                width: diameter * 0.56,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.sproutYellow.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StageIcon extends StatelessWidget {
  const _StageIcon({
    required this.kind,
    required this.accent,
    required this.isCurrent,
    required this.isLocked,
  });

  final _PracticeNodeKind kind;
  final Color accent;
  final bool isCurrent;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final tone = isCurrent ? AppColors.starPurple : accent;
    final softTone = tone.withValues(alpha: 0.24);

    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: switch (kind) {
              _PracticeNodeKind.puzzle =>
                _PuzzleIcon(tone: tone, softTone: softTone),
              _PracticeNodeKind.grid =>
                _GridIcon(tone: tone, softTone: softTone),
              _PracticeNodeKind.voice =>
                _VoiceIcon(tone: tone, softTone: softTone),
              _PracticeNodeKind.reading =>
                _ReadingIcon(tone: tone, softTone: softTone),
              _PracticeNodeKind.locked =>
                _LockedIcon(tone: tone, softTone: softTone),
              _PracticeNodeKind.trophy =>
                _TrophyIcon(tone: tone, softTone: softTone),
            },
          ),
          if (isLocked) const _StageBadge(color: AppColors.thinCloudGray),
        ],
      ),
    );
  }
}

class _StageBadge extends StatelessWidget {
  const _StageBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 0,
      bottom: 0,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: AppColors.pureWhite.withValues(alpha: 0.96),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.42), width: 1),
        ),
        child: Icon(
          Icons.lock_rounded,
          size: 10,
          color: color.withValues(alpha: 0.72),
        ),
      ),
    );
  }
}

class _PuzzleIcon extends StatelessWidget {
  const _PuzzleIcon({required this.tone, required this.softTone});

  final Color tone;
  final Color softTone;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 7,
          top: 13,
          child: _MiniTile(color: tone.withValues(alpha: 0.34), size: 16),
        ),
        Positioned(
          left: 20,
          top: 8,
          child: _MiniTile(color: tone.withValues(alpha: 0.52), size: 18),
        ),
        Positioned(
          left: 28,
          top: 19,
          child: _MiniTile(color: tone.withValues(alpha: 0.42), size: 15),
        ),
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.pureWhite.withValues(alpha: 0.92),
            border: Border.all(color: tone.withValues(alpha: 0.24), width: 1),
          ),
        ),
      ],
    );
  }
}

class _GridIcon extends StatelessWidget {
  const _GridIcon({required this.tone, required this.softTone});

  final Color tone;
  final Color softTone;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: tone.withValues(alpha: 0.72), width: 1.8),
          ),
          child: CustomPaint(
            painter: _GridPainter(color: tone.withValues(alpha: 0.72)),
          ),
        ),
        Positioned(
          right: 4,
          bottom: 4,
          child: Container(
            width: 12,
            height: 6,
            decoration: BoxDecoration(
              color: softTone,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        Positioned(
          right: 8,
          top: 4,
          child: Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.40),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ],
    );
  }
}

class _VoiceIcon extends StatelessWidget {
  const _VoiceIcon({required this.tone, required this.softTone});

  final Color tone;
  final Color softTone;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 1,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: softTone,
            ),
          ),
        ),
        Container(
          width: 20,
          height: 16,
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: tone.withValues(alpha: 0.55), width: 1.2),
          ),
        ),
        Positioned(
          right: 2,
          child: _WaveArc(color: tone.withValues(alpha: 0.56), size: 16),
        ),
        Positioned(
          right: 8,
          child: _WaveArc(color: tone.withValues(alpha: 0.42), size: 10),
        ),
      ],
    );
  }
}

class _ReadingIcon extends StatelessWidget {
  const _ReadingIcon({required this.tone, required this.softTone});

  final Color tone;
  final Color softTone;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 4,
          child: Transform.rotate(
            angle: -0.12,
            child: Container(
              width: 18,
              height: 20,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(4),
                border:
                    Border.all(color: tone.withValues(alpha: 0.42), width: 1.1),
              ),
            ),
          ),
        ),
        Positioned(
          right: 4,
          child: Transform.rotate(
            angle: 0.12,
            child: Container(
              width: 18,
              height: 20,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(4),
                border:
                    Border.all(color: tone.withValues(alpha: 0.34), width: 1.0),
              ),
            ),
          ),
        ),
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.pureWhite.withValues(alpha: 0.96),
            border: Border.all(color: tone.withValues(alpha: 0.48), width: 1.0),
          ),
          alignment: Alignment.center,
          child: Text(
            '字',
            style: TextStyle(
              color: tone,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _LockedIcon extends StatelessWidget {
  const _LockedIcon({required this.tone, required this.softTone});

  final Color tone;
  final Color softTone;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 26,
          height: 20,
          decoration: BoxDecoration(
            color: softTone,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: tone.withValues(alpha: 0.48), width: 1.2),
          ),
        ),
        Positioned(
          top: 5,
          child: Container(
            width: 15,
            height: 11,
            decoration: BoxDecoration(
              border:
                  Border.all(color: tone.withValues(alpha: 0.56), width: 1.4),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
            ),
          ),
        ),
        Positioned(
          top: 11,
          child: Container(
            width: 3,
            height: 5,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ],
    );
  }
}

class _TrophyIcon extends StatelessWidget {
  const _TrophyIcon({required this.tone, required this.softTone});

  final Color tone;
  final Color softTone;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 24,
          height: 22,
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: tone.withValues(alpha: 0.38), width: 1.2),
          ),
        ),
        Positioned(
          top: 8,
          child: Container(
            width: 14,
            height: 10,
            decoration: BoxDecoration(
              color: softTone,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        Positioned(
          left: 7,
          top: 5,
          child: Icon(
            Icons.star_rounded,
            size: 10,
            color: tone.withValues(alpha: 0.8),
          ),
        ),
        Positioned(
          right: 7,
          top: 5,
          child: Icon(
            Icons.star_rounded,
            size: 10,
            color: tone.withValues(alpha: 0.8),
          ),
        ),
        Positioned(
          bottom: 3,
          child: Container(
            width: 10,
            height: 3,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniTile extends StatelessWidget {
  const _MiniTile({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
    );
  }
}

class _WaveArc extends StatelessWidget {
  const _WaveArc({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _WaveArcPainter(color: color),
    );
  }
}

class _WaveArcPainter extends CustomPainter {
  const _WaveArcPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width * 0.9, size.height * 0.9);
    canvas.drawArc(rect, -math.pi / 2.2, math.pi / 1.6, false, paint);
  }

  @override
  bool shouldRepaint(covariant _WaveArcPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.25, 0),
      Offset(size.width * 0.25, size.height),
      paint..color = color.withValues(alpha: 0.34),
    );
    canvas.drawLine(
      Offset(size.width * 0.75, 0),
      Offset(size.width * 0.75, size.height),
      paint..color = color.withValues(alpha: 0.34),
    );
    canvas.drawLine(
      Offset(0, size.height * 0.25),
      Offset(size.width, size.height * 0.25),
      paint..color = color.withValues(alpha: 0.34),
    );
    canvas.drawLine(
      Offset(0, size.height * 0.75),
      Offset(size.width, size.height * 0.75),
      paint..color = color.withValues(alpha: 0.34),
    );
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _PracticeMapPathPainter extends CustomPainter {
  const _PracticeMapPathPainter({required this.nodes});

  final List<_PracticeNodeData> nodes;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || nodes.isEmpty) return;

    final points = nodes
        .map(
          (node) => Offset(
            size.width * node.center.dx,
            size.height * node.center.dy,
          ),
        )
        .toList(growable: false);

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      final control = Offset(
        (current.dx + next.dx) / 2 + (i.isEven ? 10 : -16),
        (current.dy + next.dy) / 2 + (i.isEven ? 22 : -18),
      );
      path.quadraticBezierTo(control.dx, control.dy, next.dx, next.dy);
    }

    final shadowPaint = Paint()
      ..color = AppColors.pureWhite.withValues(alpha: 0.34)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final mainPaint = Paint()
      ..color = AppColors.lilacPurple.withValues(alpha: 0.68)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _drawDashedPath(canvas, path, shadowPaint, 10, 10);
    _drawDashedPath(canvas, path, mainPaint, 8, 8);
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint,
    double dash,
    double gap,
  ) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PracticeMapPathPainter oldDelegate) {
    return oldDelegate.nodes != nodes;
  }
}

class _PracticeNodeData {
  const _PracticeNodeData({
    required this.title,
    required this.subtitle,
    required this.route,
    required this.center,
    required this.state,
    required this.accent,
    required this.kind,
  });

  final String title;
  final String subtitle;
  final String route;
  final Offset center;
  final _PracticeNodeState state;
  final Color accent;
  final _PracticeNodeKind kind;
}

enum _PracticeNodeState { completed, current, locked }

enum _PracticeNodeKind { puzzle, grid, voice, reading, locked, trophy }
