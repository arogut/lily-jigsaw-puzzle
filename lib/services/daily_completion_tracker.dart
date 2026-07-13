import 'package:lily_jigsaw_puzzle/core/constants/celebration_constants.dart';
import 'package:lily_jigsaw_puzzle/services/preferences_store.dart';

/// Persists and advances the within-day puzzle completion counter.
class DailyCompletionTracker {
  /// Creates a [DailyCompletionTracker].
  DailyCompletionTracker({this._store});

  final PreferencesStore? _store;

  Future<PreferencesStore> get _prefs async =>
      _store ?? await PreferencesStore.load();

  /// Returns the current within-day count for [date], then increments it.
  Future<int> consumeNext(DateTime date) async {
    final prefs = await _prefs;
    final today = _isoDate(date);
    final storedDate = prefs.getString(CelebrationConstants.dailyDateKey);
    var count = prefs.getInt(CelebrationConstants.dailyCountKey) ?? 0;

    if (storedDate != today) {
      count = 0;
    }

    final current = count;
    await prefs.setString(CelebrationConstants.dailyDateKey, today);
    await prefs.setInt(CelebrationConstants.dailyCountKey, count + 1);
    return current;
  }

  /// Returns the current within-day count for [date] without incrementing.
  Future<int> peek(DateTime date) async {
    final prefs = await _prefs;
    final today = _isoDate(date);
    final storedDate = prefs.getString(CelebrationConstants.dailyDateKey);
    if (storedDate != today) return 0;
    return prefs.getInt(CelebrationConstants.dailyCountKey) ?? 0;
  }

  /// Clears stored date and count.
  Future<void> reset() async {
    final prefs = await _prefs;
    await prefs.remove(CelebrationConstants.dailyDateKey);
    await prefs.remove(CelebrationConstants.dailyCountKey);
  }

  String _isoDate(DateTime date) =>
      DateTime(date.year, date.month, date.day).toIso8601String().split('T').first;
}
