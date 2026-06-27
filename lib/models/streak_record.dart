import 'package:flutter/foundation.dart';

/// Immutable snapshot of a user's consecutive-day puzzle completion streak.
@immutable
class StreakRecord {
  /// Creates a [StreakRecord].
  ///
  /// Asserts that [currentStreak] ≥ 0, [longestStreak] ≥ 0, and
  /// [longestStreak] ≥ [currentStreak].
  const StreakRecord({
    required this.currentStreak,
    required this.longestStreak,
    this.lastCompletionDate,
  })  : assert(currentStreak >= 0, 'currentStreak must be non-negative'),
        assert(longestStreak >= 0, 'longestStreak must be non-negative'),
        assert(
          longestStreak >= currentStreak,
          'longestStreak must be >= currentStreak',
        );

  /// Returns the initial [StreakRecord] before any puzzle has ever been completed.
  factory StreakRecord.initial() =>
      const StreakRecord(currentStreak: 0, longestStreak: 0);

  /// Number of consecutive calendar days on which at least one puzzle was completed,
  /// ending on [lastCompletionDate]. Zero before the first puzzle is completed.
  final int currentStreak;

  /// All-time highest value of [currentStreak]. Never decremented.
  final int longestStreak;

  /// ISO 8601 date (`YYYY-MM-DD`, device local time zone) of the most recent
  /// puzzle completion, or `null` when no puzzle has ever been completed.
  final String? lastCompletionDate;

  /// Returns a copy of this record with the specified fields overridden.
  StreakRecord copyWith({
    int? currentStreak,
    int? longestStreak,
    String? lastCompletionDate,
  }) =>
      StreakRecord(
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        lastCompletionDate: lastCompletionDate ?? this.lastCompletionDate,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreakRecord &&
          other.currentStreak == currentStreak &&
          other.longestStreak == longestStreak &&
          other.lastCompletionDate == lastCompletionDate;

  @override
  int get hashCode =>
      Object.hash(currentStreak, longestStreak, lastCompletionDate);
}
