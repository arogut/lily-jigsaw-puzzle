import 'package:lily_jigsaw_puzzle/services/completion_service.dart';
import 'package:lily_jigsaw_puzzle/services/daily_completion_tracker.dart';
import 'package:lily_jigsaw_puzzle/services/streak_service.dart';

/// Clears all player progress stored locally on the device.
class ProgressResetService {
  /// Creates a [ProgressResetService].
  ProgressResetService({
    CompletionService? completionService,
    StreakService? streakService,
    DailyCompletionTracker? dailyCompletionTracker,
  })  : _completionService = completionService ?? CompletionService(),
        _streakService = streakService ?? StreakService(),
        _dailyCompletionTracker =
            dailyCompletionTracker ?? DailyCompletionTracker();

  final CompletionService _completionService;
  final StreakService _streakService;
  final DailyCompletionTracker _dailyCompletionTracker;

  /// Removes all star counts, streak data, and celebration tracker state.
  Future<void> resetAll() async {
    await _completionService.resetAll();
    await _streakService.resetAll();
    await _dailyCompletionTracker.reset();
  }
}
