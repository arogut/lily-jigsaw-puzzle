import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:lily_jigsaw_puzzle/services/preferences_store.dart';

/// Stores and persists the grid size (rows = columns) for each difficulty level.
///
/// Constraints enforced on every update:
/// - All values between [minGridSize] and [maxGridSize] inclusive.
/// - [easyGridSize] < [mediumGridSize] < [hardGridSize].
class DifficultySettings extends ChangeNotifier {
  /// Creates a [DifficultySettings] with the given grid sizes.
  ///
  /// Sizes must satisfy [minGridSize] ≤ easy < medium < hard ≤ [maxGridSize].
  factory DifficultySettings({
    required int easy,
    required int medium,
    required int hard,
    PreferencesStore? store,
  }) =>
      DifficultySettings._(
        easy: easy,
        medium: medium,
        hard: hard,
        store: store,
      );

  DifficultySettings._({
    required this._easy,
    required this._medium,
    required this._hard,
    PreferencesStore? store,
  }) : _store = store;

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

  final PreferencesStore? _store;
  int _easy;
  int _medium;
  int _hard;

  Future<PreferencesStore> get _prefs async =>
      _store ?? await PreferencesStore.load();

  /// Grid size for the easy difficulty level.
  int get easyGridSize => _easy;

  /// Grid size for the medium difficulty level.
  int get mediumGridSize => _medium;

  /// Grid size for the hard difficulty level.
  int get hardGridSize => _hard;

  /// Loads persisted settings from [PreferencesStore], using defaults for any
  /// missing or invalid values.
  static Future<DifficultySettings> load({PreferencesStore? store}) async {
    final prefs = store ?? await PreferencesStore.load();
    var easy = prefs.getInt(_keyEasy) ?? defaultEasy;
    var medium = prefs.getInt(_keyMedium) ?? defaultMedium;
    var hard = prefs.getInt(_keyHard) ?? defaultHard;

    // Reset to defaults if stored values violate constraints.
    if (easy < minGridSize || medium <= easy || hard <= medium || hard > maxGridSize) {
      easy = defaultEasy;
      medium = defaultMedium;
      hard = defaultHard;
    }

    return DifficultySettings(easy: easy, medium: medium, hard: hard, store: prefs);
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
    final prefs = await _prefs;
    await prefs.setInt(_keyEasy, _easy);
    await prefs.setInt(_keyMedium, _medium);
    await prefs.setInt(_keyHard, _hard);
  }
}
