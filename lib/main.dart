import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lily_jigsaw_puzzle/core/app_theme.dart';
import 'package:lily_jigsaw_puzzle/l10n/app_localizations.dart';
import 'package:lily_jigsaw_puzzle/screens/splash_screen.dart';
import 'package:lily_jigsaw_puzzle/services/difficulty_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleNotifier extends ChangeNotifier {

  LocaleNotifier(this._locale);
  Locale _locale;

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
    unawaited(_save(locale.languageCode));
  }

  Future<void> _save(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', code);
  }

  static Future<LocaleNotifier> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('locale') ?? 'pl';
    return LocaleNotifier(Locale(code));
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  final localeNotifier = await LocaleNotifier.load();
  final difficultySettings = await DifficultySettings.load();
  runApp(JigsawApp(localeNotifier: localeNotifier, difficultySettings: difficultySettings));
}

class JigsawApp extends StatelessWidget {

  const JigsawApp({
    required this.localeNotifier,
    required this.difficultySettings,
    super.key,
  });
  final LocaleNotifier localeNotifier;
  final DifficultySettings difficultySettings;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: localeNotifier,
      builder: (context, _) {
        return MaterialApp(
          title: "Lily's Puzzle",
          debugShowCheckedModeBanner: false,
          locale: localeNotifier.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.hotPink,
            ),
            useMaterial3: true,
            textTheme: GoogleFonts.nunitoTextTheme(),
          ),
          home: SplashScreen(
            localeNotifier: localeNotifier,
            difficultySettings: difficultySettings,
          ),
        );
      },
    );
  }
}
