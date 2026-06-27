import 'dart:math';

import 'package:lily_jigsaw_puzzle/models/streak_record.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and transitions a user's consecutive-day puzzle completion streak.
///
/// Streak data is stored via [SharedPreferences] using three keys under the
/// `streak_` namespace.
class StreakService {
  /// Creates a [StreakService].
  ///
  /// [clock] defaults to [DateTime.now]. Inject a custom clock in tests to
  /// control the current date without any mocking framework.
  StreakService({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static const _kCurrentKey = 'streak_current';
  static const _kLongestKey = 'streak_longest';
  static const _kLastDateKey = 'streak_last_date';

  final DateTime Function() _clock;

  /// Returns the current [StreakRecord] from persistent storage.
  ///
  /// Returns [StreakRecord.initial()] when no streak has been recorded yet.
  Future<StreakRecord> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return StreakRecord(
      currentStreak: prefs.getInt(_kCurrentKey) ?? 0,
      longestStreak: prefs.getInt(_kLongestKey) ?? 0,
      lastCompletionDate: prefs.getString(_kLastDateKey),
    );
  }

  /// Records a puzzle completion for today and returns the updated [StreakRecord].
  ///
  /// Transition rules applied against the current device date:
  /// - No prior completion → streak becomes 1.
  /// - Same-day completion → record is unchanged (idempotent).
  /// - Consecutive-day completion → streak increments by 1.
  /// - Gap of 2+ days → streak resets to 1; [StreakRecord.longestStreak] is preserved.
  Future<StreakRecord> recordPuzzleCompletion() async {
    final existing = await getStreak();
    final today = _toDateString(_clock());
    final next = _transition(existing, today);
    if (next != existing) {
      await _persist(next);
    }
    return next;
  }

  /// Removes all streak data from persistent storage.
  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCurrentKey);
    await prefs.remove(_kLongestKey);
    await prefs.remove(_kLastDateKey);
  }

  StreakRecord _transition(StreakRecord existing, String today) {
    final last = existing.lastCompletionDate;

    if (last == null) {
      return StreakRecord(
        currentStreak: 1,
        longestStreak: max(1, existing.longestStreak),
        lastCompletionDate: today,
      );
    }

    if (last == today) {
      return existing;
    }

    if (last == _yesterday(today)) {
      final newCurrent = existing.currentStreak + 1;
      return StreakRecord(
        currentStreak: newCurrent,
        longestStreak: max(newCurrent, existing.longestStreak),
        lastCompletionDate: today,
      );
    }

    return StreakRecord(
      currentStreak: 1,
      longestStreak: existing.longestStreak,
      lastCompletionDate: today,
    );
  }

  Future<void> _persist(StreakRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kCurrentKey, record.currentStreak);
    await prefs.setInt(_kLongestKey, record.longestStreak);
    if (record.lastCompletionDate != null) {
      await prefs.setString(_kLastDateKey, record.lastCompletionDate!);
    }
  }

  String _toDateString(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}'
      '-${dt.month.toString().padLeft(2, '0')}'
      '-${dt.day.toString().padLeft(2, '0')}';

  String _yesterday(String isoDate) => _toDateString(
        DateTime.parse(isoDate).subtract(const Duration(days: 1)),
      );
}
