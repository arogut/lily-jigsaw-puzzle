import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';
import 'screens/splash_screen.dart';

class LocaleNotifier extends ChangeNotifier {
  Locale _locale;

  LocaleNotifier(this._locale);

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
    _save(locale.languageCode);
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
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  final localeNotifier = await LocaleNotifier.load();
  runApp(JigsawApp(localeNotifier: localeNotifier));
}

class JigsawApp extends StatelessWidget {
  final LocaleNotifier localeNotifier;

  const JigsawApp({super.key, required this.localeNotifier});

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
              seedColor: const Color(0xFFFF6B9D),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            textTheme: GoogleFonts.nunitoTextTheme(),
          ),
          home: SplashScreen(localeNotifier: localeNotifier),
        );
      },
    );
  }
}
