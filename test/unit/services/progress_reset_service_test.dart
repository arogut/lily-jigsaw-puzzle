import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/core/constants/celebration_constants.dart';
import 'package:lily_jigsaw_puzzle/services/completion_service.dart';
import 'package:lily_jigsaw_puzzle/services/daily_completion_tracker.dart';
import 'package:lily_jigsaw_puzzle/services/preferences_store.dart';
import 'package:lily_jigsaw_puzzle/services/progress_reset_service.dart';
import 'package:lily_jigsaw_puzzle/services/streak_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ProgressResetService', () {
    test('resetAll clears stars, streak data, and daily completion tracker', () async {
      final store = await PreferencesStore.load();
      await CompletionService(store: store).recordCompletion('uuid-1', 3);
      await StreakService(store: store).recordPuzzleCompletion();
      final tracker = DailyCompletionTracker(store: store);
      await tracker.consumeNext(DateTime(2026, 7, 13));

      await ProgressResetService(
        completionService: CompletionService(store: store),
        streakService: StreakService(store: store),
        dailyCompletionTracker: tracker,
      ).resetAll();

      expect(await CompletionService(store: store).getStars('uuid-1'), 0);
      expect((await StreakService(store: store).getStreak()).currentStreak, 0);
      expect(store.getString(CelebrationConstants.dailyDateKey), isNull);
      expect(store.getInt(CelebrationConstants.dailyCountKey), isNull);
      expect(await tracker.consumeNext(DateTime(2026, 7, 13)), 0);
    });
  });
}
