// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Puzzle de Lily';

  @override
  String get choosePuzzle => '¡Elige un Puzzle!';

  @override
  String get quit => 'Salir';

  @override
  String get back => 'Volver';

  @override
  String get pickDifficulty => 'Elige Dificultad';

  @override
  String get easy => 'Fácil';

  @override
  String get medium => 'Medio';

  @override
  String get hard => 'Difícil';

  @override
  String get easyDesc => '9 piezas (3×3)';

  @override
  String get mediumDesc => '25 piezas (5×5)';

  @override
  String get hardDesc => '49 piezas (7×7)';

  @override
  String get youDidIt => '¡Lo lograste!';

  @override
  String get puzzleComplete => '¡Puzzle completo!';

  @override
  String get playAgain => 'Jugar de nuevo';

  @override
  String get newPuzzle => 'Nuevo Puzzle';

  @override
  String get settings => 'Configuración';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String mathQuestion(int a, int b) {
    return 'Resuelve: $a + $b = ?';
  }

  @override
  String get mathHint => 'Ingresa tu respuesta';

  @override
  String get confirm => 'Confirmar';

  @override
  String get wrongAnswer => '¡Respuesta incorrecta!';

  @override
  String get language => 'Idioma';

  @override
  String get resetProgress => 'Reiniciar Progreso';

  @override
  String get progressReset => '¡Progreso reiniciado!';

  @override
  String get imageCat => 'Gato';

  @override
  String get imageDog => 'Perro';

  @override
  String get imageForest => 'Bosque';

  @override
  String get imageCity => 'Ciudad';

  @override
  String get imageLion => 'León';

  @override
  String get imageSea => 'Mar';

  @override
  String get imageElephant => 'Elefante';

  @override
  String get imageSquirrel => 'Ardilla';

  @override
  String get imageHedgehog => 'Erizo';

  @override
  String get langPolish => 'Polski';

  @override
  String get langEnglish => 'English';

  @override
  String get langGerman => 'Deutsch';

  @override
  String get langSpanish => 'Español';
}
