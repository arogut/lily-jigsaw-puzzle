import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/core/app_theme.dart';

void main() {
  group('AppColors', () {
    test('deepPurple is Color(0xFF6A1B9A)', () {
      expect(AppColors.deepPurple, const Color(0xFF6A1B9A));
    });

    test('mediumPurple is Color(0xFF9B59B6)', () {
      expect(AppColors.mediumPurple, const Color(0xFF9B59B6));
    });

    test('hotPink is Color(0xFFFF6B9D)', () {
      expect(AppColors.hotPink, const Color(0xFFFF6B9D));
    });

    test('skyBlue is Color(0xFF87CEEB)', () {
      expect(AppColors.skyBlue, const Color(0xFF87CEEB));
    });

    test('lavender is Color(0xFFB39DDB)', () {
      expect(AppColors.lavender, const Color(0xFFB39DDB));
    });

    test('babyPink is Color(0xFFFFABD0)', () {
      expect(AppColors.babyPink, const Color(0xFFFFABD0));
    });

    test('green is Color(0xFF6BCB77)', () {
      expect(AppColors.green, const Color(0xFF6BCB77));
    });

    test('red is Color(0xFFFF6B6B)', () {
      expect(AppColors.red, const Color(0xFFFF6B6B));
    });

    test('blue is Color(0xFF4D96FF)', () {
      expect(AppColors.blue, const Color(0xFF4D96FF));
    });

    test('gold is Color(0xFFFFD700)', () {
      expect(AppColors.gold, const Color(0xFFFFD700));
    });
  });

  group('AppTheme', () {
    test('backgroundDecoration is a BoxDecoration with LinearGradient', () {
      expect(AppTheme.backgroundDecoration, isA<BoxDecoration>());
      final decoration = AppTheme.backgroundDecoration;
      expect(decoration.gradient, isA<LinearGradient>());
    });

    test('backgroundDecoration gradient uses skyBlue, lavender, babyPink', () {
      final gradient = AppTheme.backgroundDecoration.gradient! as LinearGradient;
      expect(gradient.colors, contains(AppColors.skyBlue));
      expect(gradient.colors, contains(AppColors.lavender));
      expect(gradient.colors, contains(AppColors.babyPink));
    });

    test('backgroundDecoration gradient has correct stops', () {
      final gradient = AppTheme.backgroundDecoration.gradient! as LinearGradient;
      expect(gradient.stops, equals([0.0, 0.50, 1.0]));
    });
  });
}
