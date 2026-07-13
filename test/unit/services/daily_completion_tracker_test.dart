import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/core/constants/celebration_constants.dart';
import 'package:lily_jigsaw_puzzle/services/daily_completion_tracker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DailyCompletionTracker.consumeNext', () {
    test('given_first_call_today_when_consumeNext_then_returns_0_and_increments',
        () async {
      final tracker = DailyCompletionTracker();
      final date = DateTime(2026, 7, 13);

      expect(await tracker.consumeNext(date), 0);
      expect(await tracker.peek(date), 1);
    });

    test('given_second_call_same_day_when_consumeNext_then_returns_1', () async {
      final tracker = DailyCompletionTracker();
      final date = DateTime(2026, 7, 13);

      await tracker.consumeNext(date);
      expect(await tracker.consumeNext(date), 1);
    });

    test('given_new_day_when_consumeNext_then_resets_to_0', () async {
      final tracker = DailyCompletionTracker();
      await tracker.consumeNext(DateTime(2026, 7, 13));
      await tracker.consumeNext(DateTime(2026, 7, 13));

      expect(await tracker.consumeNext(DateTime(2026, 7, 14)), 0);
    });

    test('given_missing_store_when_consumeNext_then_defaults_to_0', () async {
      final tracker = DailyCompletionTracker();
      expect(await tracker.consumeNext(DateTime(2026, 7, 13)), 0);
    });
  });

  group('DailyCompletionTracker.peek', () {
    test('given_no_completions_when_peek_then_returns_0_without_incrementing',
        () async {
      final tracker = DailyCompletionTracker();
      final date = DateTime(2026, 7, 13);

      expect(await tracker.peek(date), 0);
      expect(await tracker.peek(date), 0);
    });

    test('given_prior_completion_when_peek_then_returns_current_count', () async {
      final tracker = DailyCompletionTracker();
      final date = DateTime(2026, 7, 13);
      await tracker.consumeNext(date);

      expect(await tracker.peek(date), 1);
    });
  });

  group('DailyCompletionTracker.reset', () {
    test('given_existing_data_when_reset_then_subsequent_consumeNext_returns_0',
        () async {
      final tracker = DailyCompletionTracker();
      final date = DateTime(2026, 7, 13);
      await tracker.consumeNext(date);
      await tracker.consumeNext(date);

      await tracker.reset();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(CelebrationConstants.dailyDateKey), isNull);
      expect(prefs.getInt(CelebrationConstants.dailyCountKey), isNull);
      expect(await tracker.consumeNext(date), 0);
    });
  });
}
