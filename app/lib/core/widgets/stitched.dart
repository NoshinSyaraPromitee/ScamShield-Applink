import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:scamshield/core/theme/app_colors.dart';

/// Kantha-style running stitch drawn inside a rounded card.
class Stitched extends StatelessWidget {
  const Stitched({super.key, required this.child, this.color = AppColors.stitch, this.radius = 24, this.inset = 8});

  final Widget child;
  final Color color;
  final double radius;
  final double inset;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(foregroundPainter: StitchPainter(color: color, radius: radius, inset: inset), child: child);
  }
}

class StitchPainter extends CustomPainter {
  StitchPainter({
    required this.color,
    this.radius = 24,
    this.inset = 8,
    this.circle = false,
    this.dash = 10,
    this.gap = 7,
    this.strokeWidth = 2.2,
  });

  final Color color;
  final double radius;
  final double inset;
  final bool circle;
  final double dash;
  final double gap;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(inset);
    final path = Path();
    if (circle) {
      path.addOval(rect);
    } else {
      path.addRRect(RRect.fromRectAndRadius(rect, Radius.circular(math.max(0, radius - inset))));
    }
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, math.min(distance + dash, metric.length)), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(StitchPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius || oldDelegate.inset != inset || oldDelegate.circle != circle;
}