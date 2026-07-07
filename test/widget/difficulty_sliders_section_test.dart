import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/l10n/app_localizations.dart';
import 'package:lily_jigsaw_puzzle/screens/difficulty_sliders_section.dart';
import 'package:lily_jigsaw_puzzle/services/difficulty_settings_service.dart';

void main() {
  testWidgets('DifficultySlidersSection shows three difficulty sliders', (tester) async {
    final settings = DifficultySettings(easy: 3, medium: 4, hard: 5);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: DifficultySlidersSection(settings: settings),
        ),
      ),
    );

    expect(find.byType(Slider), findsNWidgets(3));
    expect(find.text('3×3'), findsOneWidget);
    expect(find.text('4×4'), findsOneWidget);
    expect(find.text('5×5'), findsOneWidget);
  });
}
