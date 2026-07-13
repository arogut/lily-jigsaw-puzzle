import 'dart:ui';

import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/painters/fireworks_painter.dart';

void main() {
  group('generateFireworksParticles', () {
    test('returns exactly count particles', () {
      final particles = generateFireworksParticles(12);
      expect(particles, hasLength(12));
    });

    test('each particle has centre and positive ray count', () {
      final particles = generateFireworksParticles(8);
      for (final particle in particles) {
        expect(particle.centerX, inInclusiveRange(0.0, 1.0));
        expect(particle.centerY, inInclusiveRange(0.0, 1.0));
        expect(particle.rayCount, greaterThan(0));
      }
    });
  });

  group('FireworksPainter', () {
    test('paints without error', () {
      final particles = generateFireworksParticles(10);
      final painter = FireworksPainter(
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
