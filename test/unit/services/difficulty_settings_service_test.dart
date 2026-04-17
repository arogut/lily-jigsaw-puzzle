import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/services/difficulty_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DifficultySettings constants', () {
    test('minGridSize is 2', () {
      expect(DifficultySettings.minGridSize, 2);
    });

    test('maxGridSize is 9', () {
      expect(DifficultySettings.maxGridSize, 9);
    });

    test('defaults satisfy easy < medium < hard', () {
      expect(DifficultySettings.defaultEasy, lessThan(DifficultySettings.defaultMedium));
      expect(DifficultySettings.defaultMedium, lessThan(DifficultySettings.defaultHard));
    });

    test('defaults are within min/max bounds', () {
      expect(DifficultySettings.defaultEasy, greaterThanOrEqualTo(DifficultySettings.minGridSize));
      expect(DifficultySettings.defaultHard, lessThanOrEqualTo(DifficultySettings.maxGridSize));
    });
  });

  group('DifficultySettings.load', () {
    test('returns default values when no data stored', () async {
      final settings = await DifficultySettings.load();
      expect(settings.easyGridSize, DifficultySettings.defaultEasy);
      expect(settings.mediumGridSize, DifficultySettings.defaultMedium);
      expect(settings.hardGridSize, DifficultySettings.defaultHard);
    });

    test('loads persisted values', () async {
      SharedPreferences.setMockInitialValues({
        'difficulty_easy': 2,
        'difficulty_medium': 5,
        'difficulty_hard': 8,
      });
      final settings = await DifficultySettings.load();
      expect(settings.easyGridSize, 2);
      expect(settings.mediumGridSize, 5);
      expect(settings.hardGridSize, 8);
    });

    test('resets to defaults when stored values violate constraints', () async {
      SharedPreferences.setMockInitialValues({
        'difficulty_easy': 7,
        'difficulty_medium': 5,
        'difficulty_hard': 3,
      });
      final settings = await DifficultySettings.load();
      expect(settings.easyGridSize, DifficultySettings.defaultEasy);
      expect(settings.mediumGridSize, DifficultySettings.defaultMedium);
      expect(settings.hardGridSize, DifficultySettings.defaultHard);
    });

    test('resets to defaults when easy is below minimum', () async {
      SharedPreferences.setMockInitialValues({
        'difficulty_easy': 1,
        'difficulty_medium': 4,
        'difficulty_hard': 5,
      });
      final settings = await DifficultySettings.load();
      expect(settings.easyGridSize, DifficultySettings.defaultEasy);
    });

    test('resets to defaults when hard exceeds maximum', () async {
      SharedPreferences.setMockInitialValues({
        'difficulty_easy': 3,
        'difficulty_medium': 4,
        'difficulty_hard': 10,
      });
      final settings = await DifficultySettings.load();
      expect(settings.hardGridSize, DifficultySettings.defaultHard);
    });
  });

  group('DifficultySettings.setEasy', () {
    test('updates easy grid size when value is valid', () async {
      final settings = await DifficultySettings.load();
      settings.setEasy(2);
      expect(settings.easyGridSize, 2);
    });

    test('ignores value equal to medium', () async {
      final settings = await DifficultySettings.load();
      final medium = settings.mediumGridSize;
      settings.setEasy(medium);
      expect(settings.easyGridSize, DifficultySettings.defaultEasy);
    });

    test('ignores value greater than medium', () async {
      final settings = await DifficultySettings.load();
      final medium = settings.mediumGridSize;
      settings.setEasy(medium + 1);
      expect(settings.easyGridSize, DifficultySettings.defaultEasy);
    });

    test('ignores value below minimum', () async {
      final settings = await DifficultySettings.load();
      settings.setEasy(1);
      expect(settings.easyGridSize, DifficultySettings.defaultEasy);
    });

    test('notifies listeners on valid change', () async {
      final settings = await DifficultySettings.load();
      var notified = false;
      settings
        ..addListener(() => notified = true)
        ..setEasy(2);
      expect(notified, isTrue);
    });

    test('does not notify listeners on invalid change', () async {
      final settings = await DifficultySettings.load();
      var notified = false;
      settings
        ..addListener(() => notified = true)
        ..setEasy(999);
      expect(notified, isFalse);
    });
  });

  group('DifficultySettings.setMedium', () {
    test('updates medium grid size when value is valid', () async {
      final settings = DifficultySettings(easy: 2, medium: 5, hard: 9)..setMedium(4);
      expect(settings.mediumGridSize, 4);
    });

    test('ignores value equal to easy', () async {
      final settings = DifficultySettings(easy: 3, medium: 5, hard: 7)..setMedium(3);
      expect(settings.mediumGridSize, 5);
    });

    test('ignores value less than easy', () async {
      final settings = DifficultySettings(easy: 3, medium: 5, hard: 7)..setMedium(2);
      expect(settings.mediumGridSize, 5);
    });

    test('ignores value equal to hard', () async {
      final settings = DifficultySettings(easy: 3, medium: 5, hard: 7)..setMedium(7);
      expect(settings.mediumGridSize, 5);
    });

    test('ignores value greater than hard', () async {
      final settings = DifficultySettings(easy: 3, medium: 5, hard: 7)..setMedium(8);
      expect(settings.mediumGridSize, 5);
    });

    test('notifies listeners on valid change', () async {
      final settings = DifficultySettings(easy: 2, medium: 5, hard: 9);
      var notified = false;
      settings
        ..addListener(() => notified = true)
        ..setMedium(4);
      expect(notified, isTrue);
    });
  });

  group('DifficultySettings.setHard', () {
    test('updates hard grid size when value is valid', () async {
      final settings = DifficultySettings(easy: 3, medium: 5, hard: 7)..setHard(9);
      expect(settings.hardGridSize, 9);
    });

    test('ignores value equal to medium', () async {
      final settings = DifficultySettings(easy: 3, medium: 5, hard: 7)..setHard(5);
      expect(settings.hardGridSize, 7);
    });

    test('ignores value less than medium', () async {
      final settings = DifficultySettings(easy: 3, medium: 5, hard: 7)..setHard(4);
      expect(settings.hardGridSize, 7);
    });

    test('ignores value exceeding maximum', () async {
      final settings = DifficultySettings(easy: 3, medium: 5, hard: 7)..setHard(10);
      expect(settings.hardGridSize, 7);
    });

    test('notifies listeners on valid change', () async {
      final settings = DifficultySettings(easy: 3, medium: 5, hard: 7);
      var notified = false;
      settings
        ..addListener(() => notified = true)
        ..setHard(9);
      expect(notified, isTrue);
    });
  });

  group('DifficultySettings ordering invariant', () {
    test('easy < medium < hard is always maintained', () async {
      final settings = await DifficultySettings.load();
      expect(settings.easyGridSize, lessThan(settings.mediumGridSize));
      expect(settings.mediumGridSize, lessThan(settings.hardGridSize));
    });
  });

  group('DifficultySettings persistence round-trip', () {
    test('setEasy persists value across a subsequent load', () async {
      final settings = await DifficultySettings.load();
      settings.setEasy(2);
      // Allow the unawaited _save() to complete.
      await Future<void>.delayed(Duration.zero);
      final reloaded = await DifficultySettings.load();
      expect(reloaded.easyGridSize, 2);
    });

    test('setMedium persists value across a subsequent load', () async {
      SharedPreferences.setMockInitialValues({
        'difficulty_easy': 3,
        'difficulty_medium': 4,
        'difficulty_hard': 9,
      });
      final settings = await DifficultySettings.load();
      settings.setMedium(6);
      await Future<void>.delayed(Duration.zero);
      final reloaded = await DifficultySettings.load();
      expect(reloaded.mediumGridSize, 6);
    });

    test('setHard persists value across a subsequent load', () async {
      SharedPreferences.setMockInitialValues({
        'difficulty_easy': 3,
        'difficulty_medium': 4,
        'difficulty_hard': 5,
      });
      final settings = await DifficultySettings.load();
      settings.setHard(8);
      await Future<void>.delayed(Duration.zero);
      final reloaded = await DifficultySettings.load();
      expect(reloaded.hardGridSize, 8);
    });
  });
}
