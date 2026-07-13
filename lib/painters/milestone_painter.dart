import 'dart:math' show Random, cos, pi, sin;

import 'package:flutter/material.dart';
import 'package:lily_jigsaw_puzzle/core/app_theme.dart';

/// Kind of particle used in a milestone celebration.
enum MilestoneParticleKind { burst, confetti }

/// A single milestone celebration particle (burst ray or confetti piece).
class MilestoneParticle {
  /// Creates a [MilestoneParticle].
  const MilestoneParticle({
    required this.kind,
    required this.x,
    required this.y,
    required this.startDelay,
    required this.color,
    required this.size,
    required this.rayCount,
    required this.speed,
    required this.wobblePhase,
  });

  /// Whether this particle is a burst ray or falling confetti.
  final MilestoneParticleKind kind;

  /// Horizontal position as a fraction of canvas width.
  final double x;

  /// Vertical position as a fraction of canvas height.
  final double y;

  /// Animation progress at which this particle begins.
  final double startDelay;

  /// Particle colour.
  final Color color;

  /// Size or radius of the particle.
  final double size;

  /// Ray count for burst particles; unused for confetti.
  final int rayCount;

  /// Motion speed multiplier.
  final double speed;

  /// Phase offset for wobble motion.
  final double wobblePhase;
}

/// Paints an elaborate milestone celebration combining bursts and confetti.
class MilestonePainter extends CustomPainter {
  /// Creates a [MilestonePainter].
  MilestonePainter({required this.particles, required this.animation})
      : super(repaint: animation);

  /// Particles to render.
  final List<MilestoneParticle> particles;

  /// Animation driving particle motion.
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    for (final p in particles) {
      if (t < p.startDelay) continue;
      final pt = ((t - p.startDelay) / (1.0 - p.startDelay)).clamp(0.0, 1.0);
      final alpha = pt > 0.75 ? (1.0 - pt) / 0.25 : 1.0;

      switch (p.kind) {
        case MilestoneParticleKind.burst:
          _paintBurst(canvas, size, p, pt, alpha);
        case MilestoneParticleKind.confetti:
          _paintConfetti(canvas, size, p, pt, alpha);
      }
    }
  }

  void _paintBurst(
    Canvas canvas,
    Size size,
    MilestoneParticle p,
    double pt,
    double alpha,
  ) {
    final cx = p.x * size.width;
    final cy = p.y * size.height;
    final radius = p.size * Curves.easeOut.transform(pt);
    final paint = Paint()
      ..color = p.color.withValues(alpha: alpha)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < p.rayCount; i++) {
      final angle = (2 * pi * i) / p.rayCount;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + cos(angle) * radius, cy + sin(angle) * radius),
        paint,
      );
    }
  }

  void _paintConfetti(
    Canvas canvas,
    Size size,
    MilestoneParticle p,
    double pt,
    double alpha,
  ) {
    final px = p.x * size.width + sin(pt * 4 * pi + p.wobblePhase) * 24;
    final py = size.height + 20 - pt * p.speed * (size.height + 40);
    final paint = Paint()..color = p.color.withValues(alpha: alpha);
    canvas.drawCircle(Offset(px, py), p.size * 0.4, paint);
  }

  @override
  bool shouldRepaint(MilestonePainter old) => true;
}

/// Default palette for milestone celebrations.
const List<Color> kMilestonePalette = [
  AppColors.sunnyYellow,
  AppColors.pastelPink,
  AppColors.skyBlue,
  AppColors.mintGreen,
  AppColors.lavender,
];

/// Generates [count] milestone particles mixing bursts and confetti.
List<MilestoneParticle> generateMilestoneParticles(
  int count, {
  List<Color> palette = kMilestonePalette,
  Random? rng,
}) {
  final random = rng ?? Random();
  final burstCount = (count * 0.25).ceil().clamp(3, 8);
  final confettiCount = count - burstCount;

  final bursts = List.generate(
    burstCount,
    (_) => MilestoneParticle(
      kind: MilestoneParticleKind.burst,
      x: 0.2 + random.nextDouble() * 0.6,
      y: 0.15 + random.nextDouble() * 0.4,
      startDelay: random.nextDouble() * 0.2,
      color: palette[random.nextInt(palette.length)],
      size: 50 + random.nextDouble() * 40,
      rayCount: 8 + random.nextInt(4),
      speed: 1,
      wobblePhase: 0,
    ),
  );

  final confetti = List.generate(
    confettiCount,
    (_) => MilestoneParticle(
      kind: MilestoneParticleKind.confetti,
      x: random.nextDouble(),
      y: 0,
      startDelay: random.nextDouble() * 0.4,
      color: palette[random.nextInt(palette.length)],
      size: 10 + random.nextDouble() * 12,
      rayCount: 0,
      speed: 0.8 + random.nextDouble() * 0.5,
      wobblePhase: random.nextDouble() * 2 * pi,
    ),
  );

  return [...bursts, ...confetti];
}
