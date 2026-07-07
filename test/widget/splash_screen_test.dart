import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/l10n/app_localizations.dart';
import 'package:lily_jigsaw_puzzle/main.dart';
import 'package:lily_jigsaw_puzzle/screens/image_selection_screen.dart';
import 'package:lily_jigsaw_puzzle/screens/splash_screen.dart';
import 'package:lily_jigsaw_puzzle/services/difficulty_settings_service.dart';
import 'package:lily_jigsaw_puzzle/services/hint_settings_service.dart';

LocaleNotifier _makeLocaleNotifier() => LocaleNotifier(const Locale('en'));

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: child,
    );

void main() {
  testWidgets('SplashScreen navigates to image selection after delay', (tester) async {
    await tester.pumpWidget(_wrap(SplashScreen(
      localeNotifier: _makeLocaleNotifier(),
      difficultySettings: DifficultySettings(easy: 3, medium: 4, hard: 5),
      hintSettings: HintSettings(immediateMode: false, unlockDelaySeconds: 10),
    )));

    await tester.pump();
    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 5000));
    await tester.pumpAndSettle();

    expect(find.byType(ImageSelectionScreen), findsOneWidget);
  });
}
