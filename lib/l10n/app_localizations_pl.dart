// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'Puzzle Lily';

  @override
  String get choosePuzzle => 'Wybierz Puzzle!';

  @override
  String get quit => 'Wyjdź';

  @override
  String get back => 'Wróć';

  @override
  String get pickDifficulty => 'Wybierz Poziom';

  @override
  String get easy => 'Łatwy';

  @override
  String get medium => 'Średni';

  @override
  String get hard => 'Trudny';

  @override
  String get easyDesc => '9 elementów (3×3)';

  @override
  String get mediumDesc => '25 elementów (5×5)';

  @override
  String get hardDesc => '49 elementów (7×7)';

  @override
  String get youDidIt => 'Udało Się!';

  @override
  String get puzzleComplete => 'Puzzle ukończone!';

  @override
  String get playAgain => 'Zagraj Znowu';

  @override
  String get newPuzzle => 'Nowe Puzzle';

  @override
  String get settings => 'Ustawienia';

  @override
  String get settingsTitle => 'Ustawienia';

  @override
  String mathQuestion(int a, int b) {
    return 'Rozwiąż zadanie: $a + $b = ?';
  }

  @override
  String get mathHint => 'Wpisz odpowiedź';

  @override
  String get confirm => 'Potwierdź';

  @override
  String get wrongAnswer => 'Zła odpowiedź!';

  @override
  String get language => 'Język';

  @override
  String get resetProgress => 'Resetuj Postępy';

  @override
  String get progressReset => 'Postępy zresetowane!';

  @override
  String get imageCat => 'Kot';

  @override
  String get imageDog => 'Pies';

  @override
  String get imageForest => 'Las';

  @override
  String get imageCity => 'Miasto';

  @override
  String get imageLion => 'Lew';

  @override
  String get imageSea => 'Morze';

  @override
  String get imageElephant => 'Słoń';

  @override
  String get imageSquirrel => 'Wiewiórka';

  @override
  String get imageHedgehog => 'Jeż';

  @override
  String get langPolish => 'Polski';

  @override
  String get langEnglish => 'English';

  @override
  String get langGerman => 'Deutsch';

  @override
  String get langSpanish => 'Español';

  @override
  String get hint => 'Podpowiedź';
}
