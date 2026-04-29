// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Lily\'s Puzzle';

  @override
  String get choosePuzzle => 'Choose a Puzzle!';

  @override
  String get quit => 'Quit';

  @override
  String get back => 'Back';

  @override
  String get pickDifficulty => 'Pick Difficulty';

  @override
  String get easy => 'Easy';

  @override
  String get medium => 'Medium';

  @override
  String get hard => 'Hard';

  @override
  String get difficultyTitle => 'Difficulty';

  @override
  String difficultyPiecesDesc(int count, int n) {
    return '$count pieces ($n×$n)';
  }

  @override
  String get youDidIt => 'You Did It!';

  @override
  String get puzzleComplete => 'Puzzle complete!';

  @override
  String get playAgain => 'Play Again';

  @override
  String get newPuzzle => 'New Puzzle';

  @override
  String get settings => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String mathQuestion(int a, int b) {
    return 'Solve: $a + $b = ?';
  }

  @override
  String get mathHint => 'Enter your answer';

  @override
  String get confirm => 'Confirm';

  @override
  String get wrongAnswer => 'Wrong answer!';

  @override
  String get language => 'Language';

  @override
  String get resetProgress => 'Reset Progress';

  @override
  String get progressReset => 'Progress reset!';

  @override
  String get imageCat => 'Cat';

  @override
  String get imageDog => 'Dog';

  @override
  String get imageForest => 'Forest';

  @override
  String get imageCity => 'City';

  @override
  String get imageLion => 'Lion';

  @override
  String get imageSea => 'Sea';

  @override
  String get imageElephant => 'Elephant';

  @override
  String get imageSquirrel => 'Squirrel';

  @override
  String get imageHedgehog => 'Hedgehog';

  @override
  String get langPolish => 'Polski';

  @override
  String get langEnglish => 'English';

  @override
  String get langGerman => 'Deutsch';

  @override
  String get langSpanish => 'Español';

  @override
  String get hint => 'Hint';
}
