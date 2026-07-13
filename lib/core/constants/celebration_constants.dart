/// Constants for celebration style rotation and intensity scaling.
abstract final class CelebrationConstants {
  /// Maximum intensity level (inclusive).
  static const int maxIntensityLevel = 5;

  /// Particle count at intensity level 1.
  static const int baseParticleCount = 80;

  /// Particle count at intensity level 5.
  static const int maxParticleCount = 250;

  /// Animation duration at intensity level 1.
  static const Duration baseAnimationDuration = Duration(seconds: 5);

  /// Animation duration at intensity level 5.
  static const Duration maxAnimationDuration = Duration(seconds: 12);

  /// Fixed epoch for deterministic day-offset calculation.
  static final DateTime offsetEpoch = DateTime(2024);

  /// Preferences key for the last recorded completion date.
  static const String dailyDateKey = 'celebration_daily_date';

  /// Preferences key for within-day completion count.
  static const String dailyCountKey = 'celebration_daily_count';
}
