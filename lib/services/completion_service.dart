import 'package:lily_jigsaw_puzzle/services/preferences_store.dart';

/// Tracks puzzle completion progress using SharedPreferences.
class CompletionService {
  /// Creates a [CompletionService].
  CompletionService({this._store});

  static const _prefix = 'stars_';

  final PreferencesStore? _store;

  Future<PreferencesStore> get _prefs async =>
      _store ?? await PreferencesStore.load();

  /// Records completion for [imageUuid] with the given [stars] count.
  ///
  /// [stars] should be 1 for easy, 2 for medium, and 3 for hard difficulty.
  /// Only updates the stored value if [stars] exceeds the current record.
  Future<void> recordCompletion(String imageUuid, int stars) async {
    final prefs = await _prefs;
    final key = '$_prefix$imageUuid';
    final existing = prefs.getInt(key) ?? 0;
    if (stars > existing) {
      await prefs.setInt(key, stars);
    }
  }

  /// Returns the highest star count recorded for [imageUuid], or 0 if none.
  Future<int> getStars(String imageUuid) async {
    final prefs = await _prefs;
    return prefs.getInt('$_prefix$imageUuid') ?? 0;
  }

  /// Clears all stored star counts.
  Future<void> resetAll() async {
    final prefs = await _prefs;
    final keys = prefs.keys.where((k) => k.startsWith(_prefix)).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
