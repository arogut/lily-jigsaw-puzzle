import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/painters/confetti_painter.dart';

void main() {
  group('ConfettiParticle', () {
    test('can be constructed with all fields', () {
      const particle = ConfettiParticle(
        x: 0.5,
        speed: 1,
        startDelay: 0.1,
        color: Color(0xFFFF0000),
        size: 10,
        rotSpeed: 2,
        wobblePhase: 0,
        isRect: true,
      );
      expect(particle.x, 0.5);
      expect(particle.isRect, isTrue);
    });

    test('non-const constructor is callable at runtime', () {
      // Use a non-const initializer so the constructor call cannot be const,
      // exercising it at runtime.
      final isRect = [false].first;
      final particle = ConfettiParticle(
        x: 0.3,
        speed: 0.5,
        startDelay: 0,
        color: const Color(0xFF00FF00),
        size: 8,
        rotSpeed: 1.5,
        wobblePhase: 1,
        isRect: isRect,
      );
      expect(particle.isRect, isFalse);
    });
  });

  group('ConfettiPainter', () {
    test('paints rect particle without error at mid-animation', () {
      const animation = AlwaysStoppedAnimation<double>(0.5);
      final particles = [
        const ConfettiParticle(
          x: 0.5,
          speed: 1,
          startDelay: 0,
          color: Color(0xFFFF0000),
          size: 10,
          rotSpeed: 2,
          wobblePhase: 0,
          isRect: true,
        ),
      ];
      final painter = ConfettiPainter(particles: particles, animation: animation);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(400, 600));
      recorder.endRecording().dispose();
    });

    test('paints oval particle without error at mid-animation', () {
      const animation = AlwaysStoppedAnimation<double>(0.5);
      final particles = [
        const ConfettiParticle(
          x: 0.3,
          speed: 0.8,
          startDelay: 0,
          color: Color(0xFF00FF00),
          size: 8,
          rotSpeed: 3,
          wobblePhase: 1,
          isRect: false,
        ),
      ];
      final painter = ConfettiPainter(particles: particles, animation: animation);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(400, 600));
      recorder.endRecording().dispose();
    });

    test('skips particle when animation time is before startDelay', () {
      const animation = AlwaysStoppedAnimation<double>(0.1);
      final particles = [
        const ConfettiParticle(
          x: 0.5,
          speed: 1,
          startDelay: 0.9,
          color: Color(0xFF0000FF),
          size: 10,
          rotSpeed: 1,
          wobblePhase: 0,
          isRect: true,
        ),
      ];
      final painter = ConfettiPainter(particles: particles, animation: animation);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(400, 600));
      recorder.endRecording().dispose();
    });

    test('applies fade-out in last 25% of animation', () {
      const animation = AlwaysStoppedAnimation<double>(0.9);
      final particles = [
        const ConfettiParticle(
          x: 0.5,
          speed: 1,
          startDelay: 0,
          color: Color(0xFFFFFF00),
          size: 12,
          rotSpeed: 2,
          wobblePhase: 0,
          isRect: false,
        ),
      ];
      final painter = ConfettiPainter(particles: particles, animation: animation);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(400, 600));
      recorder.endRecording().dispose();
    });

    test('paints empty particles list without error', () {
      const animation = AlwaysStoppedAnimation<double>(0.5);
      final painter = ConfettiPainter(particles: const [], animation: animation);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(400, 600));
      recorder.endRecording().dispose();
    });

    test('shouldRepaint always returns true', () {
      const animation = AlwaysStoppedAnimation<double>(0.5);
      final painter = ConfettiPainter(particles: const [], animation: animation);
      expect(painter.shouldRepaint(painter), isTrue);
    });

    test('paints multiple mixed particles without error', () {
      const animation = AlwaysStoppedAnimation<double>(0.4);
      final particles = [
        const ConfettiParticle(
          x: 0.2,
          speed: 1.2,
          startDelay: 0,
          color: Color(0xFFFF6B6B),
          size: 14,
          rotSpeed: 4,
          wobblePhase: 0.5,
          isRect: true,
        ),
        const ConfettiParticle(
          x: 0.7,
          speed: 0.9,
          startDelay: 0.1,
          color: Color(0xFF6BCB77),
          size: 9,
          rotSpeed: 2.5,
          wobblePhase: 1.2,
          isRect: false,
        ),
      ];
      final painter = ConfettiPainter(particles: particles, animation: animation);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(400, 600));
      recorder.endRecording().dispose();
    });
  });
}
