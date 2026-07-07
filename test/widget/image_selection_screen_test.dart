import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/l10n/app_localizations.dart';
import 'package:lily_jigsaw_puzzle/main.dart';
import 'package:lily_jigsaw_puzzle/screens/image_selection_screen.dart';
import 'package:lily_jigsaw_puzzle/services/difficulty_settings_service.dart';
import 'package:lily_jigsaw_puzzle/services/hint_settings_service.dart';

LocaleNotifier _makeLocaleNotifier() => LocaleNotifier(const Locale('en'));

void main() {
  testWidgets('ImageSelectionScreen exposes semantic labels for puzzle cards', (tester) async {
    late AppLocalizations l10n;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context)!;
            return ImageSelectionScreen(
              localeNotifier: _makeLocaleNotifier(),
              difficultySettings: DifficultySettings(easy: 3, medium: 4, hard: 5),
              hintSettings: HintSettings(immediateMode: false, unlockDelaySeconds: 10),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(l10n.puzzleCardLabel(1)), findsOneWidget);
  });
}
