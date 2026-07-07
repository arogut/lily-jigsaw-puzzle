import 'package:lily_jigsaw_puzzle/services/completion_service.dart';
import 'package:lily_jigsaw_puzzle/services/streak_service.dart';

/// Clears all player progress stored locally on the device.
class ProgressResetService {
  /// Creates a [ProgressResetService].
  ProgressResetService({
    CompletionService? completionService,
    StreakService? streakService,
  })  : _completionService = completionService ?? CompletionService(),
        _streakService = streakService ?? StreakService();

  final CompletionService _completionService;
  final StreakService _streakService;

  /// Removes all star counts and streak data.
  Future<void> resetAll() async {
    await _completionService.resetAll();
    await _streakService.resetAll();
  }
}
