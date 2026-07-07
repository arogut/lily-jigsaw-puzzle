import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:lily_jigsaw_puzzle/models/game_state.dart';
import 'package:lily_jigsaw_puzzle/models/hint_slot_state.dart';
import 'package:lily_jigsaw_puzzle/models/streak_record.dart';
import 'package:lily_jigsaw_puzzle/services/completion_service.dart';
import 'package:lily_jigsaw_puzzle/services/hint_settings_service.dart';
import 'package:lily_jigsaw_puzzle/services/sound_service.dart';
import 'package:lily_jigsaw_puzzle/services/streak_service.dart';

/// Orchestrates hint timers, app lifecycle, and win/completion flow for a game session.
class GameController extends ChangeNotifier {
  /// Creates a [GameController] for the given [hintSettings].
  GameController({
    required this.hintSettings,
    this.onHintTimerElapsed,
    CompletionService? completionService,
    StreakService? streakService,
    SoundService? soundService,
  })  : _completionService = completionService ?? CompletionService(),
        _streakService = streakService ?? StreakService(),
        _soundService = soundService ?? SoundService();

  final HintSettings hintSettings;

  /// Called when the idle hint timer elapses and a slot becomes available.
  final VoidCallback? onHintTimerElapsed;

  final CompletionService _completionService;
  final StreakService _streakService;
  final SoundService _soundService;

  Timer? _hintTimer;
  int _timerRemainingMs = 0;

  /// Streak data populated when the puzzle is won.
  StreakRecord? streakRecord;

  /// When false, the hint area has finished its exit animation.
  bool showingHintArea = true;

  /// Cancels any active hint unlock timer.
  void cancelHintTimer() => _cancelHintTimer();

  /// Cancels timers. Call from the owning screen's [State.dispose].
  void disposeController() {
    _hintTimer?.cancel();
  }

  /// Resets session-scoped controller state for a new game.
  void resetSession() {
    _cancelHintTimer();
    _timerRemainingMs = 0;
    streakRecord = null;
    showingHintArea = true;
    notifyListeners();
  }

  /// Starts the first hint unlock timer after the scatter animation completes.
  void onScatterComplete() {
    if (!hintSettings.immediateMode) {
      _startHintTimer(hintSettings.unlockDelaySeconds * 1000);
    }
  }

  /// Updates hint timers after a piece is successfully placed.
  void onSuccessfulSnap(GameState gs) {
    if (hintSettings.immediateMode) return;
    if (gs.isHintedPiecePlaced && gs.currentHintSlot == HintSlotState.waiting) {
      _cancelHintTimer();
      _startHintTimer(hintSettings.unlockDelaySeconds * 1000);
    } else if (!gs.isHintedPiecePlaced) {
      _resetHintTimer(gs);
    }
  }

  /// Resets the idle hint timer after a wrong board placement.
  void onWrongBoardDrop(GameState gs) {
    if (!hintSettings.immediateMode) _resetHintTimer(gs);
  }

  /// Activates a hint slot. Returns true when all hints are exhausted.
  bool onHintTapped(GameState gs) {
    gs.activateHint();
    _cancelHintTimer();
    if (gs.currentHintSlot == null) {
      unawaited(_soundService.playHintsExhausted());
      return true;
    }
    notifyListeners();
    return false;
  }

  /// Plays the hint-available sound and notifies listeners.
  void onHintSlotAvailable() {
    unawaited(_soundService.playHintAvailable());
    notifyListeners();
  }

  /// Records completion stars and updates the streak.
  Future<void> recordWin(String imageUuid, int difficultyStars) async {
    await _completionService.recordCompletion(imageUuid, difficultyStars);
    streakRecord = await _streakService.recordPuzzleCompletion();
    notifyListeners();
  }

  /// Pauses or resumes the hint timer based on app lifecycle changes.
  void onLifecycleChange(AppLifecycleState state, GameState? gs) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pauseHintTimer();
    } else if (state == AppLifecycleState.resumed) {
      _resumeHintTimer(gs);
    }
  }

  void markHintAreaHidden() {
    showingHintArea = false;
    notifyListeners();
  }

  void _startHintTimer(int delayMs) {
    _hintTimer?.cancel();
    _timerRemainingMs = delayMs;
    _hintTimer = Timer(Duration(milliseconds: delayMs), () {
      _timerRemainingMs = 0;
      onHintTimerElapsed?.call();
      notifyListeners();
    });
  }

  void _cancelHintTimer() {
    _hintTimer?.cancel();
    _hintTimer = null;
  }

  void _resetHintTimer(GameState gs) {
    _cancelHintTimer();
    if (hintSettings.immediateMode ||
        gs.hasActiveHint ||
        gs.currentHintSlot != HintSlotState.waiting) {
      return;
    }
    _startHintTimer(hintSettings.unlockDelaySeconds * 1000);
  }

  void _pauseHintTimer() {
    final timer = _hintTimer;
    if (timer == null || !timer.isActive) return;
    timer.cancel();
    _hintTimer = null;
  }

  void _resumeHintTimer(GameState? gs) {
    if (gs == null ||
        hintSettings.immediateMode ||
        gs.hasActiveHint ||
        gs.currentHintSlot != HintSlotState.waiting ||
        _timerRemainingMs <= 0) {
      return;
    }
    _startHintTimer(_timerRemainingMs);
  }
}
