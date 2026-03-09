import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('pl'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Lily\'s Puzzle'**
  String get appTitle;

  /// No description provided for @choosePuzzle.
  ///
  /// In en, this message translates to:
  /// **'Choose a Puzzle!'**
  String get choosePuzzle;

  /// No description provided for @quit.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get quit;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @pickDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Pick Difficulty'**
  String get pickDifficulty;

  /// No description provided for @easy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get easy;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @hard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get hard;

  /// No description provided for @easyDesc.
  ///
  /// In en, this message translates to:
  /// **'9 pieces (3×3)'**
  String get easyDesc;

  /// No description provided for @mediumDesc.
  ///
  /// In en, this message translates to:
  /// **'25 pieces (5×5)'**
  String get mediumDesc;

  /// No description provided for @hardDesc.
  ///
  /// In en, this message translates to:
  /// **'49 pieces (7×7)'**
  String get hardDesc;

  /// No description provided for @youDidIt.
  ///
  /// In en, this message translates to:
  /// **'You Did It!'**
  String get youDidIt;

  /// No description provided for @puzzleComplete.
  ///
  /// In en, this message translates to:
  /// **'Puzzle complete!'**
  String get puzzleComplete;

  /// No description provided for @playAgain.
  ///
  /// In en, this message translates to:
  /// **'Play Again'**
  String get playAgain;

  /// No description provided for @newPuzzle.
  ///
  /// In en, this message translates to:
  /// **'New Puzzle'**
  String get newPuzzle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @mathQuestion.
  ///
  /// In en, this message translates to:
  /// **'Solve: {a} + {b} = ?'**
  String mathQuestion(int a, int b);

  /// No description provided for @mathHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your answer'**
  String get mathHint;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @wrongAnswer.
  ///
  /// In en, this message translates to:
  /// **'Wrong answer!'**
  String get wrongAnswer;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @resetProgress.
  ///
  /// In en, this message translates to:
  /// **'Reset Progress'**
  String get resetProgress;

  /// No description provided for @progressReset.
  ///
  /// In en, this message translates to:
  /// **'Progress reset!'**
  String get progressReset;

  /// No description provided for @imageCat.
  ///
  /// In en, this message translates to:
  /// **'Cat'**
  String get imageCat;

  /// No description provided for @imageDog.
  ///
  /// In en, this message translates to:
  /// **'Dog'**
  String get imageDog;

  /// No description provided for @imageForest.
  ///
  /// In en, this message translates to:
  /// **'Forest'**
  String get imageForest;

  /// No description provided for @imageCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get imageCity;

  /// No description provided for @imageLion.
  ///
  /// In en, this message translates to:
  /// **'Lion'**
  String get imageLion;

  /// No description provided for @imageSea.
  ///
  /// In en, this message translates to:
  /// **'Sea'**
  String get imageSea;

  /// No description provided for @imageElephant.
  ///
  /// In en, this message translates to:
  /// **'Elephant'**
  String get imageElephant;

  /// No description provided for @imageSquirrel.
  ///
  /// In en, this message translates to:
  /// **'Squirrel'**
  String get imageSquirrel;

  /// No description provided for @imageHedgehog.
  ///
  /// In en, this message translates to:
  /// **'Hedgehog'**
  String get imageHedgehog;

  /// No description provided for @langPolish.
  ///
  /// In en, this message translates to:
  /// **'Polski'**
  String get langPolish;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @langGerman.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get langGerman;

  /// No description provided for @langSpanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get langSpanish;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
