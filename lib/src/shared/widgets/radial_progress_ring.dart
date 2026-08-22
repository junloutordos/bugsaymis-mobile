import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A circular progress gauge with a gradient stroke and an optional slot
/// for center content (a value + label). [value]/[max] are raw units, not
/// pre-normalized — callers pass whatever's natural for their stat (GWA
/// points, a completed-count, days present) and this widget computes the
/// fraction, clamped to [0, 1]. A [max] of zero renders an empty ring
/// rather than dividing by zero.
class RadialProgressRing extends StatelessWidget {
  final double value;
  final double max;
  final List<Color> colors;
  final double size;
  final double strokeWidth;
  final Widget? center;

  const RadialProgressRing({
    super.key,
    required this.value,
    required this.max,
    required this.colors,
    this.size = 120,
    this.strokeWidth = 12,
    this.center,
  });

  double get _fraction => max <= 0 ? 0 : (value / max).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              fraction: _fraction,
              colors: colors,
              strokeWidth: strokeWidth,
            ),
          ),
          if (center != null) center!,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double fraction;
  final List<Color> colors;
  final double strokeWidth;

  _RingPainter({
    required this.fraction,
    required this.colors,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, track);

    if (fraction <= 0) return;

    final sweep = 2 * math.pi * fraction;
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + sweep,
      colors: colors,
    );
    final foreground = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, sweep, false, foreground);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.fraction != fraction || oldDelegate.colors != colors;
}
