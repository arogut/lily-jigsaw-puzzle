import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/core/app_theme.dart';

void main() {
  group('AppColors', () {
    test('deepPurple is Color(0xFF5B2D8E)', () {
      expect(AppColors.deepPurple, const Color(0xFF5B2D8E));
    });

    test('mediumPurple is Color(0xFF9B6DD4)', () {
      expect(AppColors.mediumPurple, const Color(0xFF9B6DD4));
    });

    test('pastelPink is Color(0xFFFA9AC1)', () {
      expect(AppColors.pastelPink, const Color(0xFFFA9AC1));
    });

    test('skyBlue is Color(0xFF80D4F7)', () {
      expect(AppColors.skyBlue, const Color(0xFF80D4F7));
    });

    test('lavender is Color(0xFFCEB4F0)', () {
      expect(AppColors.lavender, const Color(0xFFCEB4F0));
    });

    test('babyPink is Color(0xFFFFCCE5)', () {
      expect(AppColors.babyPink, const Color(0xFFFFCCE5));
    });

    test('mintGreen is Color(0xFF99EEC4)', () {
      expect(AppColors.mintGreen, const Color(0xFF99EEC4));
    });

    test('red is Color(0xFFFF7BAC)', () {
      expect(AppColors.red, const Color(0xFFFF7BAC));
    });

    test('sunnyYellow is Color(0xFFFEE668)', () {
      expect(AppColors.sunnyYellow, const Color(0xFFFEE668));
    });

    test('gold is Color(0xFFFFD700)', () {
      expect(AppColors.gold, const Color(0xFFFFD700));
    });
  });

  group('AppTheme', () {
    test('backgroundDecoration is a BoxDecoration with LinearGradient', () {
      expect(AppTheme.backgroundDecoration, isA<BoxDecoration>());
      const decoration = AppTheme.backgroundDecoration;
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
