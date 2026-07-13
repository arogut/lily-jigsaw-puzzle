import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/core/constants/celebration_constants.dart';
import 'package:lily_jigsaw_puzzle/models/celebration_style.dart';

void main() {
  group('CelebrationStyleId', () {
    test('has all four celebration values', () {
      expect(CelebrationStyleId.values, hasLength(4));
      expect(CelebrationStyleId.values, contains(CelebrationStyleId.confetti));
      expect(CelebrationStyleId.values, contains(CelebrationStyleId.balloons));
      expect(CelebrationStyleId.values, contains(CelebrationStyleId.fireworks));
      expect(CelebrationStyleId.values, contains(CelebrationStyleId.milestone));
    });

    test('standardStyles contains exactly confetti balloons fireworks', () {
      expect(
        CelebrationStyleId.standardStyles,
        [
          CelebrationStyleId.confetti,
          CelebrationStyleId.balloons,
          CelebrationStyleId.fireworks,
        ],
      );
      expect(
        CelebrationStyleId.standardStyles,
        isNot(contains(CelebrationStyleId.milestone)),
      );
    });

    test('each style has a non-empty audio asset path', () {
      for (final style in CelebrationStyleId.values) {
        expect(style.audioAsset, isNotEmpty);
      }
    });

    test('milestone is not in rotation', () {
      expect(CelebrationStyleId.milestone.isInRotation, isFalse);
      for (final style in CelebrationStyleId.standardStyles) {
        expect(style.isInRotation, isTrue);
      }
    });
  });

  group('CelebrationPhase', () {
    test('has animating and overlay values', () {
      expect(CelebrationPhase.values, [
        CelebrationPhase.animating,
        CelebrationPhase.overlay,
      ]);
    });
  });

  group('CelebrationConstants', () {
    test('has required constants with valid relationships', () {
      expect(CelebrationConstants.maxIntensityLevel, greaterThanOrEqualTo(2));
      expect(
        CelebrationConstants.baseAnimationDuration,
        lessThan(CelebrationConstants.maxAnimationDuration),
      );
      expect(
        CelebrationConstants.baseParticleCount,
        lessThan(CelebrationConstants.maxParticleCount),
      );
      expect(CelebrationConstants.dailyDateKey, isNotEmpty);
      expect(CelebrationConstants.dailyCountKey, isNotEmpty);
      expect(CelebrationConstants.offsetEpoch, isNotNull);
    });
  });

  group('CelebrationIntensity', () {
    test('given_0_weeks_when_fromStreakWeeks_then_level_1_baseline', () {
      final intensity = CelebrationIntensity.fromStreakWeeks(0);
      expect(intensity.level, 1);
      expect(intensity.particleCount, CelebrationConstants.baseParticleCount);
      expect(
        intensity.animationDuration,
        CelebrationConstants.baseAnimationDuration,
      );
    });

    test('given_1_week_when_fromStreakWeeks_then_level_2', () {
      final intensity = CelebrationIntensity.fromStreakWeeks(1);
      expect(intensity.level, 2);
      expect(intensity.particleCount, greaterThan(CelebrationConstants.baseParticleCount));
    });

    test('given_4_weeks_when_fromStreakWeeks_then_level_5_max', () {
      final intensity = CelebrationIntensity.fromStreakWeeks(4);
      expect(intensity.level, CelebrationConstants.maxIntensityLevel);
      expect(intensity.particleCount, CelebrationConstants.maxParticleCount);
      expect(intensity.animationDuration, CelebrationConstants.maxAnimationDuration);
    });

    test('given_10_weeks_when_fromStreakWeeks_then_clamped_at_max', () {
      final intensity = CelebrationIntensity.fromStreakWeeks(10);
      expect(intensity.level, CelebrationConstants.maxIntensityLevel);
      expect(intensity.particleCount, CelebrationConstants.maxParticleCount);
      expect(intensity.animationDuration, CelebrationConstants.maxAnimationDuration);
    });

    test('particleCount and animationDuration interpolate across levels', () {
      final level3 = CelebrationIntensity.fromStreakWeeks(2);
      expect(level3.particleCount, greaterThan(CelebrationConstants.baseParticleCount));
      expect(level3.particleCount, lessThan(CelebrationConstants.maxParticleCount));
      expect(
        level3.animationDuration.inMilliseconds,
        greaterThan(CelebrationConstants.baseAnimationDuration.inMilliseconds),
      );
      expect(
        level3.animationDuration.inMilliseconds,
        lessThan(CelebrationConstants.maxAnimationDuration.inMilliseconds),
      );
    });
  });
}
