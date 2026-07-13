import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/painters/balloon_painter.dart';

void main() {
  group('generateBalloonParticles', () {
    test('returns exactly count particles', () {
      final particles = generateBalloonParticles(25);
      expect(particles, hasLength(25));
    });

    test('each particle has positive width and height', () {
      final particles = generateBalloonParticles(10);
      for (final particle in particles) {
        expect(particle.width, greaterThan(0));
        expect(particle.height, greaterThan(0));
      }
    });
  });

  group('BalloonPainter', () {
    test('paints without error', () {
      final particles = generateBalloonParticles(12);
      final painter = BalloonPainter(
        particles: particles,
        animation: const AlwaysStoppedAnimation(0.5),
      );
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(400, 600));
      recorder.endRecording().dispose();
    });

    test('balloons drift left and right over time', () {
      const size = Size(400, 600);
      const p = BalloonParticle(
        x: 0.5,
        speed: 1,
        startDelay: 0,
        color: Colors.red,
        width: 20,
        height: 30,
        wobblePhase: 0,
        driftPhase: 0,
        driftFrequency: 1,
        driftAmplitude: 20,
      );

      final posEarly = balloonParticlePosition(particle: p, size: size, t: 0.25)!;
      final posLate = balloonParticlePosition(particle: p, size: size, t: 0.75)!;

      // With a sine drift, these points should land on opposite sides of the base X.
      final baseX = p.x * size.width;
      expect(posEarly.dx - baseX, greaterThan(0));
      expect(posLate.dx - baseX, lessThan(0));
    });
  });
}
