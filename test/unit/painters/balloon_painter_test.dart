import 'dart:ui';

import 'package:flutter/animation.dart';
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
  });
}
