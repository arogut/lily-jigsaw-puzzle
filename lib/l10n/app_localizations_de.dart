// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Lily\'s Puzzle';

  @override
  String get choosePuzzle => 'Wähle ein Puzzle!';

  @override
  String get quit => 'Beenden';

  @override
  String get back => 'Zurück';

  @override
  String get pickDifficulty => 'Schwierigkeit wählen';

  @override
  String get easy => 'Leicht';

  @override
  String get medium => 'Mittel';

  @override
  String get hard => 'Schwer';

  @override
  String get easyDesc => '9 Teile (3×3)';

  @override
  String get mediumDesc => '25 Teile (5×5)';

  @override
  String get hardDesc => '49 Teile (7×7)';

  @override
  String get youDidIt => 'Geschafft!';

  @override
  String get puzzleComplete => 'Puzzle fertig!';

  @override
  String get playAgain => 'Nochmal spielen';

  @override
  String get newPuzzle => 'Neues Puzzle';

  @override
  String get settings => 'Einstellungen';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String mathQuestion(int a, int b) {
    return 'Löse: $a + $b = ?';
  }

  @override
  String get mathHint => 'Antwort eingeben';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get wrongAnswer => 'Falsche Antwort!';

  @override
  String get language => 'Sprache';

  @override
  String get resetProgress => 'Fortschritt zurücksetzen';

  @override
  String get progressReset => 'Fortschritt zurückgesetzt!';

  @override
  String get imageCat => 'Katze';

  @override
  String get imageDog => 'Hund';

  @override
  String get imageForest => 'Wald';

  @override
  String get imageCity => 'Stadt';

  @override
  String get imageLion => 'Löwe';

  @override
  String get imageSea => 'Meer';

  @override
  String get imageElephant => 'Elefant';

  @override
  String get imageSquirrel => 'Eichhörnchen';

  @override
  String get imageHedgehog => 'Igel';

  @override
  String get langPolish => 'Polski';

  @override
  String get langEnglish => 'English';

  @override
  String get langGerman => 'Deutsch';

  @override
  String get langSpanish => 'Español';

  @override
  String get hint => 'Tipp';
}
