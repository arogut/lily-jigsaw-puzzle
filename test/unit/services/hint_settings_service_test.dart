import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/services/hint_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HintSettings constants', () {
    test('defaultDelay is 10', () {
      expect(HintSettings.defaultDelay, 10);
    });
  });

  group('HintSettings.load', () {
    test('returns defaults when nothing stored', () async {
      final settings = await HintSettings.load();
      expect(settings.immediateMode, isFalse);
      expect(settings.unlockDelaySeconds, HintSettings.defaultDelay);
    });

    test('loads persisted immediateMode true', () async {
      SharedPreferences.setMockInitialValues({'hint_immediate_mode': true});
      final settings = await HintSettings.load();
      expect(settings.immediateMode, isTrue);
    });

    test('loads persisted unlockDelaySeconds', () async {
      SharedPreferences.setMockInitialValues({'hint_unlock_delay_seconds': 30});
      final settings = await HintSettings.load();
      expect(settings.unlockDelaySeconds, 30);
    });

    test('resets delay to default when stored value is zero', () async {
      SharedPreferences.setMockInitialValues({'hint_unlock_delay_seconds': 0});
      final settings = await HintSettings.load();
      expect(settings.unlockDelaySeconds, HintSettings.defaultDelay);
    });

    test('resets delay to default when stored value is negative', () async {
      SharedPreferences.setMockInitialValues({
        'hint_unlock_delay_seconds': -5,
      });
      final settings = await HintSettings.load();
      expect(settings.unlockDelaySeconds, HintSettings.defaultDelay);
    });
  });

  group('HintSettings.setImmediateMode', () {
    test('updates immediateMode to true', () async {
      final settings = await HintSettings.load();
      settings.setImmediateMode(value: true);
      expect(settings.immediateMode, isTrue);
    });

    test('updates immediateMode to false', () async {
      SharedPreferences.setMockInitialValues({'hint_immediate_mode': true});
      final settings = await HintSettings.load();
      settings.setImmediateMode(value: false);
      expect(settings.immediateMode, isFalse);
    });

    test('notifies listeners on change', () async {
      final settings = await HintSettings.load();
      var notified = false;
      settings
        ..addListener(() => notified = true)
        ..setImmediateMode(value: true);
      expect(notified, isTrue);
    });

    test('persists value across subsequent load', () async {
      final settings = await HintSettings.load();
      settings.setImmediateMode(value: true);
      await Future<void>.delayed(Duration.zero);
      final reloaded = await HintSettings.load();
      expect(reloaded.immediateMode, isTrue);
    });
  });

  group('HintSettings.setUnlockDelay', () {
    test('updates delay when positive', () async {
      final settings = await HintSettings.load();
      settings.setUnlockDelay(value: 30);
      expect(settings.unlockDelaySeconds, 30);
    });

    test('ignores zero value', () async {
      final settings = await HintSettings.load();
      settings.setUnlockDelay(value: 0);
      expect(settings.unlockDelaySeconds, HintSettings.defaultDelay);
    });

    test('ignores negative value', () async {
      final settings = await HintSettings.load();
      settings.setUnlockDelay(value: -1);
      expect(settings.unlockDelaySeconds, HintSettings.defaultDelay);
    });

    test('notifies listeners on valid change', () async {
      final settings = await HintSettings.load();
      var notified = false;
      settings
        ..addListener(() => notified = true)
        ..setUnlockDelay(value: 20);
      expect(notified, isTrue);
    });

    test('does not notify listeners on invalid change', () async {
      final settings = await HintSettings.load();
      var notified = false;
      settings
        ..addListener(() => notified = true)
        ..setUnlockDelay(value: 0);
      expect(notified, isFalse);
    });

    test('persists value across subsequent load', () async {
      final settings = await HintSettings.load();
      settings.setUnlockDelay(value: 45);
      await Future<void>.delayed(Duration.zero);
      final reloaded = await HintSettings.load();
      expect(reloaded.unlockDelaySeconds, 45);
    });
  });
}
