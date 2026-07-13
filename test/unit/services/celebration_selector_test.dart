import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/core/constants/celebration_constants.dart';
import 'package:lily_jigsaw_puzzle/models/celebration_style.dart';
import 'package:lily_jigsaw_puzzle/services/celebration_selector.dart';

void main() {
  group('CelebrationSelector.dayOffset', () {
    test('given_same_date_when_called_twice_then_same_offset', () {
      final date = DateTime(2026, 7, 13);
      expect(CelebrationSelector.dayOffset(date), CelebrationSelector.dayOffset(date));
    });

    test('given_consecutive_dates_when_called_then_offsets_differ_by_1_mod_3', () {
      final day1 = DateTime(2026, 7, 13);
      final day2 = DateTime(2026, 7, 14);
      final offset1 = CelebrationSelector.dayOffset(day1);
      final offset2 = CelebrationSelector.dayOffset(day2);
      expect((offset2 - offset1) % 3, 1);
    });

    test('given_known_reference_date_when_called_then_matches_expected', () {
      final date = DateTime(2026, 7, 13);
      final localDate = DateTime(date.year, date.month, date.day);
      final expected =
          localDate.difference(CelebrationConstants.offsetEpoch).inDays % 3;
      expect(CelebrationSelector.dayOffset(date), expected);
    });
  });

  group('CelebrationSelector.styleFor', () {
    final referenceDate = DateTime(2026, 7, 13);

    test('given_count_0_when_styleFor_then_returns_expected_style', () {
      final offset = CelebrationSelector.dayOffset(referenceDate);
      final expected = CelebrationStyleId.standardStyles[offset];
      expect(CelebrationSelector.styleFor(referenceDate, 0), expected);
    });

    test('given_incrementing_count_when_styleFor_then_cycles_all_3_styles', () {
      final styles = <CelebrationStyleId>{
        for (var i = 0; i < 3; i++)
          CelebrationSelector.styleFor(referenceDate, i),
      };
      expect(styles, CelebrationStyleId.standardStyles.toSet());
    });

    test('given_count_3_when_styleFor_then_wraps_to_same_as_count_0', () {
      expect(
        CelebrationSelector.styleFor(referenceDate, 3),
        CelebrationSelector.styleFor(referenceDate, 0),
      );
    });

    test('given_any_date_and_count_when_styleFor_then_never_returns_milestone', () {
      for (var day = 0; day < 30; day++) {
        final date = DateTime(2026).add(Duration(days: day));
        for (var count = 0; count < 100; count++) {
          expect(
            CelebrationSelector.styleFor(date, count),
            isNot(CelebrationStyleId.milestone),
          );
        }
      }
    });
  });
}
