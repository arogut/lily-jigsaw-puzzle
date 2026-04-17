import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/l10n/app_localizations.dart';
import 'package:lily_jigsaw_puzzle/l10n/app_localizations_de.dart';
import 'package:lily_jigsaw_puzzle/l10n/app_localizations_en.dart';
import 'package:lily_jigsaw_puzzle/l10n/app_localizations_es.dart';
import 'package:lily_jigsaw_puzzle/l10n/app_localizations_pl.dart';

void _exerciseAllStrings(AppLocalizations l10n) {
  expect(l10n.appTitle, isNotEmpty);
  expect(l10n.choosePuzzle, isNotEmpty);
  expect(l10n.quit, isNotEmpty);
  expect(l10n.back, isNotEmpty);
  expect(l10n.pickDifficulty, isNotEmpty);
  expect(l10n.easy, isNotEmpty);
  expect(l10n.medium, isNotEmpty);
  expect(l10n.hard, isNotEmpty);
  expect(l10n.difficultyTitle, isNotEmpty);
  expect(l10n.difficultyPiecesDesc(9, 3), isNotEmpty);
  expect(l10n.youDidIt, isNotEmpty);
  expect(l10n.puzzleComplete, isNotEmpty);
  expect(l10n.playAgain, isNotEmpty);
  expect(l10n.newPuzzle, isNotEmpty);
  expect(l10n.settings, isNotEmpty);
  expect(l10n.settingsTitle, isNotEmpty);
  expect(l10n.mathQuestion(3, 4), isNotEmpty);
  expect(l10n.mathHint, isNotEmpty);
  expect(l10n.confirm, isNotEmpty);
  expect(l10n.wrongAnswer, isNotEmpty);
  expect(l10n.language, isNotEmpty);
  expect(l10n.resetProgress, isNotEmpty);
  expect(l10n.progressReset, isNotEmpty);
  expect(l10n.imageCat, isNotEmpty);
  expect(l10n.imageDog, isNotEmpty);
  expect(l10n.imageForest, isNotEmpty);
  expect(l10n.imageCity, isNotEmpty);
  expect(l10n.imageLion, isNotEmpty);
  expect(l10n.imageSea, isNotEmpty);
  expect(l10n.imageElephant, isNotEmpty);
  expect(l10n.imageSquirrel, isNotEmpty);
  expect(l10n.imageHedgehog, isNotEmpty);
  expect(l10n.langPolish, isNotEmpty);
  expect(l10n.langEnglish, isNotEmpty);
  expect(l10n.langGerman, isNotEmpty);
  expect(l10n.langSpanish, isNotEmpty);
}

void main() {
  group('AppLocalizations delegate', () {
    test('shouldReload returns false', () {
      expect(
        AppLocalizations.delegate.shouldReload(AppLocalizations.delegate),
        isFalse,
      );
    });

    test('lookupAppLocalizations returns correct locale classes', () {
      expect(lookupAppLocalizations(const Locale('de')), isA<AppLocalizationsDe>());
      expect(lookupAppLocalizations(const Locale('en')), isA<AppLocalizationsEn>());
      expect(lookupAppLocalizations(const Locale('es')), isA<AppLocalizationsEs>());
      expect(lookupAppLocalizations(const Locale('pl')), isA<AppLocalizationsPl>());
    });

    test('lookupAppLocalizations throws for unsupported locale', () {
      expect(
        () => lookupAppLocalizations(const Locale('xx')),
        throwsA(isA<FlutterError>()),
      );
    });
  });

  group('AppLocalizationsEn', () {
    test('provides all string translations', () {
      _exerciseAllStrings(AppLocalizationsEn());
    });

    test('locale name is en', () {
      expect(AppLocalizationsEn().localeName, 'en');
    });

    test('mathQuestion formats with parameters', () {
      final result = AppLocalizationsEn().mathQuestion(1, 2);
      expect(result, contains('1'));
      expect(result, contains('2'));
    });
  });

  group('AppLocalizationsDe', () {
    test('provides all string translations', () {
      _exerciseAllStrings(AppLocalizationsDe());
    });

    test('locale name is de', () {
      expect(AppLocalizationsDe().localeName, 'de');
    });

    test('mathQuestion formats with parameters', () {
      final result = AppLocalizationsDe().mathQuestion(5, 6);
      expect(result, contains('5'));
      expect(result, contains('6'));
    });
  });

  group('AppLocalizationsEs', () {
    test('provides all string translations', () {
      _exerciseAllStrings(AppLocalizationsEs());
    });

    test('locale name is es', () {
      expect(AppLocalizationsEs().localeName, 'es');
    });

    test('mathQuestion formats with parameters', () {
      final result = AppLocalizationsEs().mathQuestion(7, 8);
      expect(result, contains('7'));
      expect(result, contains('8'));
    });
  });

  group('AppLocalizationsPl', () {
    test('provides all string translations', () {
      _exerciseAllStrings(AppLocalizationsPl());
    });

    test('locale name is pl', () {
      expect(AppLocalizationsPl().localeName, 'pl');
    });

    test('mathQuestion formats with parameters', () {
      final result = AppLocalizationsPl().mathQuestion(2, 9);
      expect(result, contains('2'));
      expect(result, contains('9'));
    });
  });
}
