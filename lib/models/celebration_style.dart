import 'package:flutter/foundation.dart';

import 'package:lily_jigsaw_puzzle/core/constants/celebration_constants.dart';

/// Identifies one of the four celebration variants.
enum CelebrationStyleId {
  /// Coloured paper shapes raining down.
  confetti,

  /// Balloon-shaped particles floating upward.
  balloons,

  /// Radial burst explosions from screen centres.
  fireworks,

  /// Combined elaborate celebration for streak milestones.
  milestone;

  /// The three styles that appear in the daily rotation.
  static const List<CelebrationStyleId> standardStyles = [
    confetti,
    balloons,
    fireworks,
  ];

  /// Asset path for this style's fanfare audio.
  String get audioAsset => switch (this) {
        CelebrationStyleId.confetti => 'sounds/win_confetti.wav',
        CelebrationStyleId.balloons => 'sounds/win_balloons.wav',
        CelebrationStyleId.fireworks => 'sounds/win_fireworks.wav',
        CelebrationStyleId.milestone => 'sounds/win_milestone.wav',
      };

  /// Whether this style participates in the standard daily rotation.
  bool get isInRotation => this != CelebrationStyleId.milestone;
}

/// Active stage of a win celebration (animation first, then overlay).
enum CelebrationPhase {
  /// Particle animation playing; skippable with a tap.
  animating,

  /// Fixed win overlay visible; fanfare still playing.
  overlay,
}

/// Derived intensity level for a celebration, based on completed streak weeks.
@immutable
final class CelebrationIntensity {
  /// Creates a [CelebrationIntensity] at the given [level].
  const CelebrationIntensity({
    required this.level,
    required this.particleCount,
    required this.animationDuration,
  });

  /// Derives intensity from the number of completed streak weeks.
  ///
  /// [completedStreakWeeks] is typically the player's current streak in days ~/ 7.
  factory CelebrationIntensity.fromStreakWeeks(int completedStreakWeeks) {
    final level = (completedStreakWeeks + 1)
        .clamp(1, CelebrationConstants.maxIntensityLevel);
    return CelebrationIntensity(
      level: level,
      particleCount: _lerpInt(
        CelebrationConstants.baseParticleCount,
        CelebrationConstants.maxParticleCount,
        level,
      ),
      animationDuration: Duration(
        milliseconds: _lerpInt(
          CelebrationConstants.baseAnimationDuration.inMilliseconds,
          CelebrationConstants.maxAnimationDuration.inMilliseconds,
          level,
        ),
      ),
    );
  }

  /// Intensity level in range [1, CelebrationConstants.maxIntensityLevel].
  final int level;

  /// Particle count derived by linear interpolation.
  final int particleCount;

  /// Animation duration derived by linear interpolation.
  final Duration animationDuration;

  static int _lerpInt(int min, int max, int level) {
    if (CelebrationConstants.maxIntensityLevel <= 1) return min;
    final t = (level - 1) / (CelebrationConstants.maxIntensityLevel - 1);
    return min + ((max - min) * t).round();
  }
}
