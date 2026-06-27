import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/models/streak_record.dart';
import 'package:lily_jigsaw_puzzle/services/streak_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

DateTime _date(String iso) => DateTime.parse(iso);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('StreakService.getStreak()', () {
    test('given_empty_prefs_when_getStreak_called_then_returns_initial', () async {
      final record = await StreakService().getStreak();
      expect(record, StreakRecord.initial());
    });
  });

  group('StreakService.recordPuzzleCompletion() — first ever', () {
    test('given_no_prior_completion_when_first_puzzle_completed_then_streak_is_1', () async {
      final svc = StreakService(clock: () => _date('2026-06-27'));
      final record = await svc.recordPuzzleCompletion();
      expect(record.currentStreak, 1);
      expect(record.longestStreak, 1);
      expect(record.lastCompletionDate, '2026-06-27');
    });
  });

  group('StreakService.recordPuzzleCompletion() — same day (idempotent)', () {
    test('given_streak_1_when_second_puzzle_same_day_then_streak_unchanged', () async {
      final svc = StreakService(clock: () => _date('2026-06-27'));
      await svc.recordPuzzleCompletion();
      final record = await svc.recordPuzzleCompletion();
      expect(record.currentStreak, 1);
      expect(record.longestStreak, 1);
      expect(record.lastCompletionDate, '2026-06-27');
    });
  });

  group('StreakService.recordPuzzleCompletion() — consecutive days', () {
    test('given_streak_1_when_completed_on_next_day_then_streak_becomes_2', () async {
      await StreakService(clock: () => _date('2026-06-27')).recordPuzzleCompletion();
      final record =
          await StreakService(clock: () => _date('2026-06-28')).recordPuzzleCompletion();
      expect(record.currentStreak, 2);
      expect(record.longestStreak, 2);
      expect(record.lastCompletionDate, '2026-06-28');
    });

    test('given_streak_5_when_completed_on_next_day_then_longest_updates', () async {
      for (var i = 0; i < 5; i++) {
        await StreakService(clock: () => DateTime(2026, 6, 1 + i)).recordPuzzleCompletion();
      }
      final record =
          await StreakService(clock: () => _date('2026-06-06')).recordPuzzleCompletion();
      expect(record.currentStreak, 6);
      expect(record.longestStreak, 6);
    });
  });

  group('StreakService.recordPuzzleCompletion() — missed days (reset)', () {
    test('given_streak_7_when_gap_of_2_days_then_streak_resets_to_1', () async {
      for (var i = 0; i < 7; i++) {
        await StreakService(clock: () => DateTime(2026, 6, 20 + i)).recordPuzzleCompletion();
      }
      // Last was June 26; skipping June 27; completing on June 28 (2-day gap)
      final record =
          await StreakService(clock: () => _date('2026-06-28')).recordPuzzleCompletion();
      expect(record.currentStreak, 1);
      expect(record.longestStreak, 7);
      expect(record.lastCompletionDate, '2026-06-28');
    });

    test('given_streak_3_when_gap_of_10_days_then_streak_resets_to_1', () async {
      for (var i = 0; i < 3; i++) {
        await StreakService(clock: () => DateTime(2026, 6, 1 + i)).recordPuzzleCompletion();
      }
      final record =
          await StreakService(clock: () => _date('2026-06-20')).recordPuzzleCompletion();
      expect(record.currentStreak, 1);
      expect(record.longestStreak, 3);
    });

    test('longest_streak_is_preserved_after_reset', () async {
      for (var i = 0; i < 3; i++) {
        await StreakService(clock: () => DateTime(2026, 6, 1 + i)).recordPuzzleCompletion();
      }
      final record =
          await StreakService(clock: () => _date('2026-06-10')).recordPuzzleCompletion();
      expect(record.currentStreak, 1);
      expect(record.longestStreak, 3);
    });
  });

  group('StreakService — clock injection', () {
    test('given_custom_clock_when_completing_then_date_matches_injected_date', () async {
      final svc = StreakService(clock: () => DateTime(2000, 1, 15));
      final record = await svc.recordPuzzleCompletion();
      expect(record.lastCompletionDate, '2000-01-15');
    });

    test('single_digit_month_and_day_are_zero_padded', () async {
      final svc = StreakService(clock: () => DateTime(2026, 3, 5));
      final record = await svc.recordPuzzleCompletion();
      expect(record.lastCompletionDate, '2026-03-05');
    });
  });

  group('StreakService.resetAll()', () {
    test('given_existing_streak_when_resetAll_then_getStreak_returns_initial', () async {
      final svc = StreakService(clock: () => _date('2026-06-27'));
      await svc.recordPuzzleCompletion();
      await svc.resetAll();
      final record = await svc.getStreak();
      expect(record, StreakRecord.initial());
    });
  });
}
