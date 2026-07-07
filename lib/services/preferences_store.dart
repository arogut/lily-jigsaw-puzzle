import 'package:shared_preferences/shared_preferences.dart';

/// Typed wrapper around [SharedPreferences] to avoid repeating get/save boilerplate.
class PreferencesStore {
  /// Creates a [PreferencesStore] backed by [prefs].
  const PreferencesStore(this._prefs);

  final SharedPreferences _prefs;

  /// Loads a [PreferencesStore] from the platform default instance.
  static Future<PreferencesStore> load() async =>
      PreferencesStore(await SharedPreferences.getInstance());

  /// Returns the stored integer for [key], or null when absent.
  int? getInt(String key) => _prefs.getInt(key);

  /// Returns the stored bool for [key], or null when absent.
  bool? getBool(String key) => _prefs.getBool(key);

  /// Returns the stored string for [key], or null when absent.
  String? getString(String key) => _prefs.getString(key);

  /// Returns all keys currently in storage.
  Set<String> get keys => _prefs.getKeys();

  /// Persists [value] under [key].
  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);

  /// Persists [value] under [key].
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  /// Persists [value] under [key].
  Future<void> setString(String key, String value) => _prefs.setString(key, value);

  /// Removes the entry for [key].
  Future<void> remove(String key) => _prefs.remove(key);
}
