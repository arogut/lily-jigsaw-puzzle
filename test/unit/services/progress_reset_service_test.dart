import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/services/completion_service.dart';
import 'package:lily_jigsaw_puzzle/services/preferences_store.dart';
import 'package:lily_jigsaw_puzzle/services/progress_reset_service.dart';
import 'package:lily_jigsaw_puzzle/services/streak_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ProgressResetService', () {
    test('resetAll clears stars and streak data', () async {
      final store = await PreferencesStore.load();
      await CompletionService(store: store).recordCompletion('uuid-1', 3);
      await StreakService(store: store).recordPuzzleCompletion();

      await ProgressResetService(
        completionService: CompletionService(store: store),
        streakService: StreakService(store: store),
      ).resetAll();

      expect(await CompletionService(store: store).getStars('uuid-1'), 0);
      expect((await StreakService(store: store).getStreak()).currentStreak, 0);
    });
  });
}
