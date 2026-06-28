import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores and persists the hint unlock configuration.
///
/// - [immediateMode]: when true, all hints are active from session start.
/// - [unlockDelaySeconds]: idle seconds before each hint unlocks (default 10).
class HintSettings extends ChangeNotifier {
  /// Creates a [HintSettings] with the given values.
  factory HintSettings({
    required bool immediateMode,
    required int unlockDelaySeconds,
  }) =>
      HintSettings._(
        immediateMode: immediateMode,
        unlockDelaySeconds: unlockDelaySeconds,
      );

  HintSettings._({
    required this._immediateMode,
    required this._unlockDelaySeconds,
  });

  /// Default idle delay in seconds before a hint unlocks.
  static const int defaultDelay = 10;

  static const _keyImmediate = 'hint_immediate_mode';
  static const _keyDelay = 'hint_unlock_delay_seconds';

  bool _immediateMode;
  int _unlockDelaySeconds;

  /// Whether all hints are available immediately at session start.
  bool get immediateMode => _immediateMode;

  /// Idle seconds the player must wait before the next hint unlocks.
  int get unlockDelaySeconds => _unlockDelaySeconds;

  /// Loads persisted settings, using defaults for missing or invalid values.
  static Future<HintSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final immediate = prefs.getBool(_keyImmediate) ?? false;
    final delay = prefs.getInt(_keyDelay) ?? defaultDelay;
    return HintSettings(
      immediateMode: immediate,
      unlockDelaySeconds: delay > 0 ? delay : defaultDelay,
    );
  }

  /// Sets [immediateMode] and persists the change.
  void setImmediateMode({required bool value}) {
    _immediateMode = value;
    notifyListeners();
    unawaited(_save());
  }

  /// Sets [unlockDelaySeconds] to [value].
  ///
  /// Has no effect if [value] is less than 1.
  void setUnlockDelay({required int value}) {
    if (value < 1) return;
    _unlockDelaySeconds = value;
    notifyListeners();
    unawaited(_save());
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyImmediate, _immediateMode);
    await prefs.setInt(_keyDelay, _unlockDelaySeconds);
  }
}
