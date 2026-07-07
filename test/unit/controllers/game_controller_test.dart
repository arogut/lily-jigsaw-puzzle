import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/controllers/game_controller.dart';
import 'package:lily_jigsaw_puzzle/models/streak_record.dart';
import 'package:lily_jigsaw_puzzle/services/completion_service.dart';
import 'package:lily_jigsaw_puzzle/services/hint_settings_service.dart';
import 'package:lily_jigsaw_puzzle/services/streak_service.dart';

class _DeferredCompletionService extends CompletionService {
  _DeferredCompletionService(this._completer);

  final Completer<void> _completer;

  @override
  Future<void> recordCompletion(String imageUuid, int stars) =>
      _completer.future;
}

class _DeferredStreakService extends StreakService {
  _DeferredStreakService(this._completer);

  final Completer<StreakRecord> _completer;

  @override
  Future<StreakRecord> recordPuzzleCompletion() => _completer.future;
}

void main() {
  group('GameController', () {
    test('resetSession clears streak and restores hint area', () {
      final controller = GameController(
        hintSettings: HintSettings(immediateMode: true, unlockDelaySeconds: 10),
      )
        ..showingHintArea = false
        ..resetSession();

      expect(controller.showingHintArea, isTrue);
      expect(controller.streakRecord, isNull);
    });

    test('onScatterComplete does not fire callback in immediate mode', () {
      var fired = false;
      GameController(
        hintSettings: HintSettings(immediateMode: true, unlockDelaySeconds: 1),
        onHintTimerElapsed: () => fired = true,
      ).onScatterComplete();

      expect(fired, isFalse);
    });

    test('markHintAreaHidden updates showingHintArea', () {
      final controller = GameController(
        hintSettings: HintSettings(immediateMode: true, unlockDelaySeconds: 10),
      )..markHintAreaHidden();

      expect(controller.showingHintArea, isFalse);
    });

    test('recordWin does not notify listeners after dispose', () async {
      final completionCompleter = Completer<void>();
      final streakCompleter = Completer<StreakRecord>();
      final controller = GameController(
        hintSettings: HintSettings(immediateMode: true, unlockDelaySeconds: 10),
        completionService: _DeferredCompletionService(completionCompleter),
        streakService: _DeferredStreakService(streakCompleter),
      );

      var notified = false;
      controller.addListener(() => notified = true);

      final recordFuture = controller.recordWin('uuid', 1);
      controller.dispose();

      completionCompleter.complete();
      streakCompleter.complete(const StreakRecord(
        currentStreak: 1,
        longestStreak: 1,
        lastCompletionDate: '2026-07-07',
      ));

      await recordFuture;

      expect(notified, isFalse);
      expect(controller.streakRecord, isNull);
    });
  });
}
