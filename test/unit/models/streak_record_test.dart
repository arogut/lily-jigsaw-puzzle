import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/models/streak_record.dart';

void main() {
  group('StreakRecord', () {
    test('initial() returns zero counts and null date', () {
      final record = StreakRecord.initial();
      expect(record.currentStreak, 0);
      expect(record.longestStreak, 0);
      expect(record.lastCompletionDate, isNull);
    });

    test('initial() equals a manually constructed zero record', () {
      expect(
        StreakRecord.initial(),
        const StreakRecord(currentStreak: 0, longestStreak: 0),
      );
    });

    test('copyWith overrides currentStreak and preserves other fields', () {
      const original = StreakRecord(
        currentStreak: 3,
        longestStreak: 7,
        lastCompletionDate: '2026-06-27',
      );
      final copy = original.copyWith(currentStreak: 4, longestStreak: 7);
      expect(copy.currentStreak, 4);
      expect(copy.longestStreak, 7);
      expect(copy.lastCompletionDate, '2026-06-27');
    });

    test('copyWith with all fields replaces all values', () {
      const original = StreakRecord(
        currentStreak: 1,
        longestStreak: 5,
        lastCompletionDate: '2026-01-01',
      );
      final copy = original.copyWith(
        currentStreak: 2,
        longestStreak: 6,
        lastCompletionDate: '2026-01-02',
      );
      expect(copy.currentStreak, 2);
      expect(copy.longestStreak, 6);
      expect(copy.lastCompletionDate, '2026-01-02');
    });

    test('copyWith with no arguments returns equal record', () {
      const original = StreakRecord(
        currentStreak: 3,
        longestStreak: 5,
        lastCompletionDate: '2026-06-01',
      );
      final copy = original.copyWith();
      expect(copy, original);
    });

    test('given_negative_currentStreak_when_constructed_then_assert_fires', () {
      expect(
        () => StreakRecord(currentStreak: -1, longestStreak: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('given_negative_longestStreak_when_constructed_then_assert_fires', () {
      expect(
        () => StreakRecord(currentStreak: 0, longestStreak: -1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('given_longestStreak_less_than_currentStreak_when_constructed_then_assert_fires', () {
      expect(
        () => StreakRecord(currentStreak: 5, longestStreak: 3),
        throwsA(isA<AssertionError>()),
      );
    });

    test('equality holds for records with identical values', () {
      const a = StreakRecord(
        currentStreak: 2,
        longestStreak: 5,
        lastCompletionDate: '2026-06-27',
      );
      const b = StreakRecord(
        currentStreak: 2,
        longestStreak: 5,
        lastCompletionDate: '2026-06-27',
      );
      expect(a, equals(b));
    });

    test('inequality when fields differ', () {
      const a = StreakRecord(currentStreak: 1, longestStreak: 1);
      const b = StreakRecord(currentStreak: 2, longestStreak: 2);
      expect(a, isNot(equals(b)));
    });

    test('hashCode is consistent for equal records', () {
      const a = StreakRecord(currentStreak: 3, longestStreak: 7, lastCompletionDate: '2026-06-01');
      const b = StreakRecord(currentStreak: 3, longestStreak: 7, lastCompletionDate: '2026-06-01');
      expect(a.hashCode, b.hashCode);
    });
  });
}
