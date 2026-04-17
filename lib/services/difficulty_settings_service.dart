import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores and persists the grid size (rows = columns) for each difficulty level.
///
/// Constraints enforced on every update:
/// - All values between [minGridSize] and [maxGridSize] inclusive.
/// - [easyGridSize] < [mediumGridSize] < [hardGridSize].
class DifficultySettings extends ChangeNotifier {
  /// Creates a [DifficultySettings] with the given grid sizes.
  ///
  /// Sizes must satisfy [minGridSize] ≤ easy < medium < hard ≤ [maxGridSize].
  DifficultySettings({
    required int easy,
    required int medium,
    required int hard,
  })  : _easy = easy,
        _medium = medium,
        _hard = hard;

  /// Minimum allowed grid size (rows / columns).
  static const int minGridSize = 2;

  /// Maximum allowed grid size (rows / columns).
  static const int maxGridSize = 9;

  /// Default grid size for the easy difficulty level.
  static const int defaultEasy = 3;

  /// Default grid size for the medium difficulty level.
  static const int defaultMedium = 4;

  /// Default grid size for the hard difficulty level.
  static const int defaultHard = 5;

  static const _keyEasy = 'difficulty_easy';
  static const _keyMedium = 'difficulty_medium';
  static const _keyHard = 'difficulty_hard';

  int _easy;
  int _medium;
  int _hard;

  /// Grid size for the easy difficulty level.
  int get easyGridSize => _easy;

  /// Grid size for the medium difficulty level.
  int get mediumGridSize => _medium;

  /// Grid size for the hard difficulty level.
  int get hardGridSize => _hard;

  /// Loads persisted settings from [SharedPreferences], using defaults for any
  /// missing or invalid values.
  static Future<DifficultySettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    var easy = prefs.getInt(_keyEasy) ?? defaultEasy;
    var medium = prefs.getInt(_keyMedium) ?? defaultMedium;
    var hard = prefs.getInt(_keyHard) ?? defaultHard;

    // Reset to defaults if stored values violate constraints.
    if (easy < minGridSize || medium <= easy || hard <= medium || hard > maxGridSize) {
      easy = defaultEasy;
      medium = defaultMedium;
      hard = defaultHard;
    }

    return DifficultySettings(easy: easy, medium: medium, hard: hard);
  }

  /// Sets the easy grid size.
  ///
  /// Has no effect if [value] is outside [[minGridSize], [mediumGridSize] - 1].
  void setEasy(int value) {
    if (value < minGridSize || value >= _medium) return;
    _easy = value;
    notifyListeners();
    unawaited(_save());
  }

  /// Sets the medium grid size.
  ///
  /// Has no effect if [value] is outside [[easyGridSize] + 1, [hardGridSize] - 1].
  void setMedium(int value) {
    if (value <= _easy || value >= _hard) return;
    _medium = value;
    notifyListeners();
    unawaited(_save());
  }

  /// Sets the hard grid size.
  ///
  /// Has no effect if [value] is outside [[mediumGridSize] + 1, [maxGridSize]].
  void setHard(int value) {
    if (value <= _medium || value > maxGridSize) return;
    _hard = value;
    notifyListeners();
    unawaited(_save());
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyEasy, _easy);
    await prefs.setInt(_keyMedium, _medium);
    await prefs.setInt(_keyHard, _hard);
  }
}
