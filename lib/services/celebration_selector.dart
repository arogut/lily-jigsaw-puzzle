import 'package:lily_jigsaw_puzzle/core/constants/celebration_constants.dart';
import 'package:lily_jigsaw_puzzle/models/celebration_style.dart';

/// Pure-function helper for celebration style selection.
abstract final class CelebrationSelector {
  /// Days since [CelebrationConstants.offsetEpoch], modulo standard style count.
  static int dayOffset(DateTime date) {
    final localDate = DateTime(date.year, date.month, date.day);
    final days = localDate.difference(CelebrationConstants.offsetEpoch).inDays;
    return days % CelebrationStyleId.standardStyles.length;
  }

  /// Returns the style for the N-th completion ([dailyCount]) on [date].
  static CelebrationStyleId styleFor(DateTime date, int dailyCount) {
    final index = (dayOffset(date) + dailyCount) %
        CelebrationStyleId.standardStyles.length;
    return CelebrationStyleId.standardStyles[index];
  }
}
