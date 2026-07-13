import 'dart:math' show Random, cos, pi, sin;

import 'package:flutter/material.dart';
import 'package:lily_jigsaw_puzzle/core/app_theme.dart';

/// A single fireworks burst particle.
class FireworksParticle {
  /// Creates a [FireworksParticle].
  const FireworksParticle({
    required this.centerX,
    required this.centerY,
    required this.startDelay,
    required this.color,
    required this.rayCount,
    required this.radius,
  });

  /// Burst centre X as a fraction of canvas width.
  final double centerX;

  /// Burst centre Y as a fraction of canvas height.
  final double centerY;

  /// Animation progress at which this burst begins.
  final double startDelay;

  /// Burst colour.
  final Color color;

  /// Number of rays in the burst.
  final int rayCount;

  /// Maximum burst radius in logical pixels.
  final double radius;
}

/// Paints radial fireworks burst explosions.
class FireworksPainter extends CustomPainter {
  /// Creates a [FireworksPainter].
  FireworksPainter({required this.particles, required this.animation})
      : super(repaint: animation);

  /// Burst particles to render.
  final List<FireworksParticle> particles;

  /// Animation driving burst expansion.
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    for (final p in particles) {
      if (t < p.startDelay) continue;
      final pt = ((t - p.startDelay) / (1.0 - p.startDelay)).clamp(0.0, 1.0);
      final alpha = pt > 0.7 ? (1.0 - pt) / 0.3 : 1.0;
      final cx = p.centerX * size.width;
      final cy = p.centerY * size.height;
      final radius = p.radius * Curves.easeOut.transform(pt);

      final paint = Paint()
        ..color = p.color.withValues(alpha: alpha)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (var i = 0; i < p.rayCount; i++) {
        final angle = (2 * pi * i) / p.rayCount;
        final endX = cx + cos(angle) * radius;
        final endY = cy + sin(angle) * radius;
        canvas.drawLine(Offset(cx, cy), Offset(endX, endY), paint);
      }

      final corePaint = Paint()..color = p.color.withValues(alpha: alpha);
      canvas.drawCircle(Offset(cx, cy), 4 * (1 - pt * 0.5), corePaint);
    }
  }

  @override
  bool shouldRepaint(FireworksPainter old) => true;
}

/// Default palette for fireworks celebrations.
const List<Color> kFireworksPalette = [
  AppColors.sunnyYellow,
  AppColors.pastelPink,
  AppColors.skyBlue,
  AppColors.lavender,
];

/// Generates fireworks burst particles scaled from [count].
///
/// [count] reflects celebration intensity (particle budget); the number of
/// bursts is clamped so paint cost stays bounded on tablet.
List<FireworksParticle> generateFireworksParticles(
  int count, {
  List<Color> palette = kFireworksPalette,
  Random? rng,
}) {
  final random = rng ?? Random();
  final burstCount = (count * 0.25).ceil().clamp(3, 8);
  return List.generate(
    burstCount,
    (_) => FireworksParticle(
      centerX: 0.15 + random.nextDouble() * 0.7,
      centerY: 0.1 + random.nextDouble() * 0.5,
      startDelay: random.nextDouble() * 0.35,
      color: palette[random.nextInt(palette.length)],
      rayCount: 6 + random.nextInt(6),
      radius: 40 + random.nextDouble() * 50,
    ),
  );
}
