import 'package:shared_preferences/shared_preferences.dart';

class CompletionService {
  static const _prefix = 'stars_';

  /// Stars mapping: Easy (gridSize=3) → 1, Medium (gridSize=5) → 2, Hard (gridSize=7) → 3
  static int _starsFor(int gridSize) {
    if (gridSize <= 3) return 1;
    if (gridSize <= 5) return 2;
    return 3;
  }

  Future<void> recordCompletion(String imageUuid, int gridSize) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix$imageUuid';
    final newStars = _starsFor(gridSize);
    final existing = prefs.getInt(key) ?? 0;
    if (newStars > existing) {
      await prefs.setInt(key, newStars);
    }
  }

  Future<int> getStars(String imageUuid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_prefix$imageUuid') ?? 0;
  }

  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
