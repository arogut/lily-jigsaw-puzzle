import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/controllers/game_controller.dart';
import 'package:lily_jigsaw_puzzle/services/hint_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GameController', () {
    test('resetSession clears streak and restores hint area', () {
      final controller = GameController(
        hintSettings: HintSettings(immediateMode: true, unlockDelaySeconds: 10),
      )..showingHintArea = false;

      controller.resetSession();
      expect(controller.showingHintArea, isTrue);
      expect(controller.streakRecord, isNull);
    });

    test('onScatterComplete does not fire callback in immediate mode', () {
      var fired = false;
      final controller = GameController(
        hintSettings: HintSettings(immediateMode: true, unlockDelaySeconds: 1),
        onHintTimerElapsed: () => fired = true,
      );

      controller.onScatterComplete();
      expect(fired, isFalse);
    });

    test('markHintAreaHidden updates showingHintArea', () {
      final controller = GameController(
        hintSettings: HintSettings(immediateMode: true, unlockDelaySeconds: 10),
      );

      controller.markHintAreaHidden();
      expect(controller.showingHintArea, isFalse);
    });
  });
}
