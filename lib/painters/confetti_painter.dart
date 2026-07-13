import 'dart:math' show Random, cos, pi, sin;

import 'package:flutter/material.dart';
import 'package:lily_jigsaw_puzzle/core/app_theme.dart';

/// Shape of a single confetti particle.
enum ConfettiShape { star, heart, squiggle }

/// A single confetti particle with position and motion parameters.
class ConfettiParticle {
  /// Creates a [ConfettiParticle].
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

  /// Horizontal start position as a fraction of canvas width.
  final double x;

  /// Fall speed multiplier.
  final double speed;

  /// Animation progress at which this particle begins moving.
  final double startDelay;

  /// Particle colour.
  final Color color;

  /// Particle size in logical pixels.
  final double size;

  /// Rotation speed multiplier.
  final double rotSpeed;

  /// Phase offset for horizontal wobble.
  final double wobblePhase;

  /// Visual shape of the particle.
  final ConfettiShape shape;
}

/// Paints falling confetti particles over the win celebration.
class ConfettiPainter extends CustomPainter {
  /// Creates a [ConfettiPainter].
  ConfettiPainter({required this.particles, required this.animation})
      : super(repaint: animation);

  /// Particles to render.
  final List<ConfettiParticle> particles;

  /// Animation driving particle motion.
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

/// Default pastel palette for confetti celebrations.
const List<Color> kConfettiPalette = [
  AppColors.pastelPink,
  AppColors.skyBlue,
  AppColors.mintGreen,
  AppColors.sunnyYellow,
  AppColors.lavender,
];

/// Generates [count] randomised confetti particles.
List<ConfettiParticle> generateConfettiParticles(
  int count, {
  List<Color> palette = kConfettiPalette,
  Random? rng,
}) {
  final random = rng ?? Random();
  const shapes = ConfettiShape.values;
  return List.generate(
    count,
    (_) => ConfettiParticle(
      x: random.nextDouble(),
      speed: 0.7 + random.nextDouble() * 0.6,
      startDelay: random.nextDouble() * 0.4,
      color: palette[random.nextInt(palette.length)],
      size: 12 + random.nextDouble() * 14,
      rotSpeed: (random.nextDouble() - 0.5) * 4,
      wobblePhase: random.nextDouble() * 2 * pi,
      shape: shapes[random.nextInt(shapes.length)],
    ),
  );
}
