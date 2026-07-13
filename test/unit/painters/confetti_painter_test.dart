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
        shape: ConfettiShape.star,
      );
      expect(particle.x, 0.5);
      expect(particle.shape, ConfettiShape.star);
    });

    test('non-const constructor is callable at runtime', () {
      final shape = [ConfettiShape.heart].first;
      final particle = ConfettiParticle(
        x: 0.3,
        speed: 0.5,
        startDelay: 0,
        color: const Color(0xFF00FF00),
        size: 8,
        rotSpeed: 1.5,
        wobblePhase: 1,
        shape: shape,
      );
      expect(particle.shape, ConfettiShape.heart);
    });
  });

  group('generateConfettiParticles', () {
    test('returns exactly count particles', () {
      final particles = generateConfettiParticles(42);
      expect(particles, hasLength(42));
    });

    test('uses only ConfettiShape values', () {
      final particles = generateConfettiParticles(20);
      for (final particle in particles) {
        expect(ConfettiShape.values, contains(particle.shape));
      }
    });

    test('uses colours from provided palette', () {
      const palette = [Color(0xFF112233), Color(0xFF445566)];
      final particles = generateConfettiParticles(10, palette: palette);
      for (final particle in particles) {
        expect(palette, contains(particle.color));
      }
    });
  });

  group('ConfettiPainter', () {
    test('paints star particle without error at mid-animation', () {
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
          shape: ConfettiShape.star,
        ),
      ];
      final painter = ConfettiPainter(particles: particles, animation: animation);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(400, 600));
      recorder.endRecording().dispose();
    });

    test('paints heart particle without error at mid-animation', () {
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
          shape: ConfettiShape.heart,
        ),
      ];
      final painter = ConfettiPainter(particles: particles, animation: animation);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(400, 600));
      recorder.endRecording().dispose();
    });

    test('paints squiggle particle without error at mid-animation', () {
      const animation = AlwaysStoppedAnimation<double>(0.5);
      final particles = [
        const ConfettiParticle(
          x: 0.6,
          speed: 0.9,
          startDelay: 0,
          color: Color(0xFFFFFF00),
          size: 12,
          rotSpeed: 1,
          wobblePhase: 0.5,
          shape: ConfettiShape.squiggle,
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
          shape: ConfettiShape.star,
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
          shape: ConfettiShape.heart,
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
          shape: ConfettiShape.star,
        ),
        const ConfettiParticle(
          x: 0.7,
          speed: 0.9,
          startDelay: 0.1,
          color: Color(0xFF6BCB77),
          size: 9,
          rotSpeed: 2.5,
          wobblePhase: 1.2,
          shape: ConfettiShape.squiggle,
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
