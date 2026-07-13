import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/painters/milestone_painter.dart';

void main() {
  group('generateMilestoneParticles', () {
    test('returns exactly count particles', () {
      final particles = generateMilestoneParticles(30);
      expect(particles, hasLength(30));
    });
  });

  group('MilestonePainter', () {
    test('paints without error', () {
      final particles = generateMilestoneParticles(20);
      final painter = MilestonePainter(
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
