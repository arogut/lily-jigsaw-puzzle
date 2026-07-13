import 'dart:math' show Random, pi, sin;

import 'package:flutter/material.dart';
import 'package:lily_jigsaw_puzzle/core/app_theme.dart';

/// A single balloon particle floating upward.
class BalloonParticle {
  /// Creates a [BalloonParticle].
  const BalloonParticle({
    required this.x,
    required this.speed,
    required this.startDelay,
    required this.color,
    required this.width,
    required this.height,
    required this.wobblePhase,
    required this.driftPhase,
    required this.driftFrequency,
    required this.driftAmplitude,
  });

  /// Horizontal start position as a fraction of canvas width.
  final double x;

  /// Rise speed multiplier.
  final double speed;

  /// Animation progress at which this particle begins moving.
  final double startDelay;

  /// Balloon fill colour.
  final Color color;

  /// Balloon oval width.
  final double width;

  /// Balloon oval height.
  final double height;

  /// Phase offset for horizontal sway.
  final double wobblePhase;

  /// Phase offset for the slow drift.
  final double driftPhase;

  /// Frequency multiplier for the slow drift.
  final double driftFrequency;

  /// Maximum horizontal drift distance in logical pixels.
  final double driftAmplitude;
}

Offset? balloonParticlePosition({
  required BalloonParticle particle,
  required Size size,
  required double t,
}) {
  if (t < particle.startDelay) return null;
  final pt = ((t - particle.startDelay) / (1.0 - particle.startDelay))
      .clamp(0.0, 1.0);

  final wobbleX = sin(pt * 3 * pi + particle.wobblePhase) * 20;
  final driftX = sin(pt * 2 * pi * particle.driftFrequency + particle.driftPhase) *
      particle.driftAmplitude;
  final px = particle.x * size.width + wobbleX + driftX;
  final py = size.height + 40 - pt * particle.speed * (size.height + 80);
  return Offset(px, py);
}

/// Paints upward-floating balloon particles.
class BalloonPainter extends CustomPainter {
  /// Creates a [BalloonPainter].
  BalloonPainter({required this.particles, required this.animation})
      : super(repaint: animation);

  /// Particles to render.
  final List<BalloonParticle> particles;

  /// Animation driving particle motion.
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    for (final p in particles) {
      final pos = balloonParticlePosition(particle: p, size: size, t: t);
      if (pos == null) continue;
      final pt = ((t - p.startDelay) / (1.0 - p.startDelay)).clamp(0.0, 1.0);
      final alpha = pt > 0.8 ? (1.0 - pt) / 0.2 : 1.0;
      final px = pos.dx;
      final py = pos.dy;

      canvas
        ..save()
        ..translate(px, py);

      final paint = Paint()..color = p.color.withValues(alpha: alpha);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: p.width,
        height: p.height,
      );
      canvas.drawOval(rect, paint);

      final stringPaint = Paint()
        ..color = p.color.withValues(alpha: alpha * 0.7)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas
        ..drawLine(
          Offset(0, p.height / 2),
          Offset(0, p.height / 2 + 18),
          stringPaint,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(BalloonPainter old) => true;
}

/// Default palette for balloon celebrations.
const List<Color> kBalloonPalette = [
  AppColors.pastelPink,
  AppColors.skyBlue,
  AppColors.sunnyYellow,
  AppColors.mintGreen,
];

/// Generates [count] balloon particles.
List<BalloonParticle> generateBalloonParticles(
  int count, {
  List<Color> palette = kBalloonPalette,
  Random? rng,
}) {
  final random = rng ?? Random();
  return List.generate(
    count,
    (_) => BalloonParticle(
      x: random.nextDouble(),
      speed: 0.6 + random.nextDouble() * 0.5,
      startDelay: random.nextDouble() * 0.3,
      color: palette[random.nextInt(palette.length)],
      width: 18 + random.nextDouble() * 14,
      height: 22 + random.nextDouble() * 16,
      wobblePhase: random.nextDouble() * 2 * pi,
      driftPhase: random.nextDouble() * 2 * pi,
      driftFrequency: 0.4 + random.nextDouble() * 0.6,
      driftAmplitude: 10 + random.nextDouble() * 18,
    ),
  );
}
