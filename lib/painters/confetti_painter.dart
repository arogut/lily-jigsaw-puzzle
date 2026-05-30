import 'dart:math' show Random, cos, pi, sin;

import 'package:flutter/material.dart';
import 'package:lily_jigsaw_puzzle/core/app_theme.dart';

/// Shape of a single confetti particle.
enum ConfettiShape { star, heart, squiggle }

class ConfettiParticle {
  const ConfettiParticle({
    required this.x,
    required this.speed,
    required this.startDelay,
    required this.color,
    required this.size,
    required this.rotSpeed,
    required this.wobblePhase,
    required this.shape,
  });

  final double x;
  final double speed;
  final double startDelay;
  final Color color;
  final double size;
  final double rotSpeed;
  final double wobblePhase;
  final ConfettiShape shape;
}

class ConfettiPainter extends CustomPainter {
  ConfettiPainter({required this.particles, required this.animation})
      : super(repaint: animation);

  final List<ConfettiParticle> particles;
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    for (final p in particles) {
      if (t < p.startDelay) continue;
      final pt = ((t - p.startDelay) / (1.0 - p.startDelay)).clamp(0.0, 1.0);
      final alpha = pt > 0.75 ? (1.0 - pt) / 0.25 : 1.0;
      final px = p.x * size.width +
          sin(pt * 4 * pi + p.wobblePhase) * 28 +
          cos(pt * 2.5 * pi + p.wobblePhase * 0.7) * 14;
      final py = size.height + 28.0 - pt * p.speed * (size.height + 56);
      final rot = pt * 2 * pi * p.rotSpeed;

      canvas
        ..save()
        ..translate(px, py)
        ..rotate(rot);

      final paint = Paint()..color = p.color.withValues(alpha: alpha);
      switch (p.shape) {
        case ConfettiShape.star:
          _drawStar(canvas, paint, p.size);
        case ConfettiShape.heart:
          _drawHeart(canvas, paint, p.size);
        case ConfettiShape.squiggle:
          _drawSquiggle(canvas, p.color.withValues(alpha: alpha), p.size);
      }
      canvas.restore();
    }
  }

  void _drawStar(Canvas canvas, Paint paint, double r) {
    final outer = r * 0.5;
    final inner = outer * 0.42;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -pi / 2 + i * pi / 5;
      final rad = i.isEven ? outer : inner;
      final x = rad * cos(angle);
      final y = rad * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawHeart(Canvas canvas, Paint paint, double r) {
    final s = r * 0.45;
    final path = Path()
      ..moveTo(0, s * 0.4)
      ..cubicTo(-s * 0.1, -s * 0.3, -s, -s * 0.3, -s, s * 0.1)
      ..cubicTo(-s, s * 0.6, -s * 0.1, s * 0.9, 0, s * 1.1)
      ..cubicTo(s * 0.1, s * 0.9, s, s * 0.6, s, s * 0.1)
      ..cubicTo(s, -s * 0.3, s * 0.1, -s * 0.3, 0, s * 0.4)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawSquiggle(Canvas canvas, Color color, double r) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.22
      ..strokeCap = StrokeCap.round;
    final len = r * 1.4;
    final path = Path()
      ..moveTo(-len / 2, 0)
      ..cubicTo(-len / 6, -r * 0.4, len / 6, r * 0.4, len / 2, 0);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(ConfettiPainter old) => true;
}

/// Generates a list of randomised confetti particles using the pastel palette.
List<ConfettiParticle> generateConfettiParticles(int count) {
  const colors = [
    AppColors.pastelPink,
    AppColors.skyBlue,
    AppColors.mintGreen,
    AppColors.sunnyYellow,
    AppColors.lavender,
  ];
  const shapes = ConfettiShape.values;
  final rng = Random();
  return List.generate(count, (_) => ConfettiParticle(
        x: rng.nextDouble(),
        speed: 0.7 + rng.nextDouble() * 0.6,
        startDelay: rng.nextDouble() * 0.4,
        color: colors[rng.nextInt(colors.length)],
        size: 12 + rng.nextDouble() * 14,
        rotSpeed: (rng.nextDouble() - 0.5) * 4,
        wobblePhase: rng.nextDouble() * 2 * pi,
        shape: shapes[rng.nextInt(shapes.length)],
      ));
}
