import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lily_jigsaw_puzzle/l10n/app_localizations.dart';
import 'package:lily_jigsaw_puzzle/main.dart';
import 'package:lily_jigsaw_puzzle/screens/settings_screen.dart';
import 'package:lily_jigsaw_puzzle/services/difficulty_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

LocaleNotifier _makeLocaleNotifier() => LocaleNotifier(const Locale('en'));
DifficultySettings _makeDifficultySettings() => DifficultySettings(
      easy: DifficultySettings.defaultEasy,
      medium: DifficultySettings.defaultMedium,
      hard: DifficultySettings.defaultHard,
    );

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: child,
    );

/// Parses the sum from the math gate question text "Solve: a + b = ?"
int? _extractSumFromQuestion(WidgetTester tester) {
  final textWidgets = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .where((s) => s.contains('+'))
      .toList();
  if (textWidgets.isEmpty) return null;
  final match = RegExp(r'(\d+) \+ (\d+)').firstMatch(textWidgets.first);
  if (match == null) return null;
  return int.parse(match.group(1)!) + int.parse(match.group(2)!);
}

Future<void> _unlockSettings(WidgetTester tester) async {
  final correctAnswer = _extractSumFromQuestion(tester);
  expect(correctAnswer, isNotNull);
  await tester.enterText(find.byType(TextField), '$correctAnswer');
  await tester.tap(find.text('Confirm'));
  await tester.pump();
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Settings screen shows math gate initially', (tester) async {
    await tester.pumpWidget(
      _wrap(SettingsScreen(
        localeNotifier: _makeLocaleNotifier(),
        difficultySettings: _makeDifficultySettings(),
      )),
    );
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);
  });

  testWidgets('Settings screen shows Back button', (tester) async {
    await tester.pumpWidget(
      _wrap(SettingsScreen(
        localeNotifier: _makeLocaleNotifier(),
        difficultySettings: _makeDifficultySettings(),
      )),
    );
    await tester.pump();
    expect(find.text('Back'), findsOneWidget);
  });

  testWidgets('Settings screen displays math question text', (tester) async {
    await tester.pumpWidget(
      _wrap(SettingsScreen(
        localeNotifier: _makeLocaleNotifier(),
        difficultySettings: _makeDifficultySettings(),
      )),
    );
    await tester.pump();
    // Math question contains a "+" operator
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && (w.data ?? '').contains('+'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Settings screen shows error for wrong answer', (tester) async {
    await tester.pumpWidget(
      _wrap(SettingsScreen(
        localeNotifier: _makeLocaleNotifier(),
        difficultySettings: _makeDifficultySettings(),
      )),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), '999');
    await tester.tap(find.text('Confirm'));
    await tester.pump();
    expect(find.text('Wrong answer!'), findsOneWidget);
    // Drain auto-dismiss timer
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('Settings screen unlocks panel on correct answer', (tester) async {
    await tester.pumpWidget(
      _wrap(SettingsScreen(
        localeNotifier: _makeLocaleNotifier(),
        difficultySettings: _makeDifficultySettings(),
      )),
    );
    await tester.pump();

    await _unlockSettings(tester);

    // Settings panel visible after correct answer
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Reset Progress'), findsAtLeastNWidgets(1));
  });

  testWidgets('Settings panel shows language buttons', (tester) async {
    await tester.pumpWidget(
      _wrap(SettingsScreen(
        localeNotifier: _makeLocaleNotifier(),
        difficultySettings: _makeDifficultySettings(),
      )),
    );
    await tester.pump();

    await _unlockSettings(tester);

    expect(find.text('English'), findsOneWidget);
    expect(find.text('Polski'), findsOneWidget);
    expect(find.text('Deutsch'), findsOneWidget);
  });

  testWidgets('Settings panel shows reset progress confirmation after reset', (tester) async {
    await tester.pumpWidget(
      _wrap(SettingsScreen(
        localeNotifier: _makeLocaleNotifier(),
        difficultySettings: _makeDifficultySettings(),
      )),
    );
    await tester.pump();

    await _unlockSettings(tester);

    await tester.tap(find.text('Reset Progress').last);
    await tester.pumpAndSettle();
    expect(find.text('Progress reset!'), findsOneWidget);
  });

  testWidgets('Settings screen Back button can be tapped', (tester) async {
    await tester.pumpWidget(
      _wrap(SettingsScreen(
        localeNotifier: _makeLocaleNotifier(),
        difficultySettings: _makeDifficultySettings(),
      )),
    );
    await tester.pump();
    await tester.tap(find.text('Back'));
    await tester.pump();
    // Pop is a no-op (only route), screen still present
    expect(find.text('Back'), findsOneWidget);
  });

  testWidgets('Settings screen onSubmitted fires check-answer logic', (tester) async {
    await tester.pumpWidget(
      _wrap(SettingsScreen(
        localeNotifier: _makeLocaleNotifier(),
        difficultySettings: _makeDifficultySettings(),
      )),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), '999');
    // Simulate pressing Enter / Done on the keyboard
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('Wrong answer!'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('Settings panel allows changing locale', (tester) async {
    final localeNotifier = _makeLocaleNotifier();
    await tester.pumpWidget(
      _wrap(SettingsScreen(
        localeNotifier: localeNotifier,
        difficultySettings: _makeDifficultySettings(),
      )),
    );
    await tester.pump();

    await _unlockSettings(tester);

    await tester.tap(find.text('Polski'));
    await tester.pump();
    expect(localeNotifier.locale.languageCode, 'pl');
  });

  testWidgets('Settings panel shows difficulty section with three sliders', (tester) async {
    await tester.pumpWidget(
      _wrap(SettingsScreen(
        localeNotifier: _makeLocaleNotifier(),
        difficultySettings: _makeDifficultySettings(),
      )),
    );
    await tester.pump();

    await _unlockSettings(tester);
    await tester.pump();

    expect(find.text('Difficulty'), findsOneWidget);
    expect(find.byType(Slider), findsNWidgets(3));
  });

  testWidgets('Difficulty sliders show Easy, Medium, Hard labels', (tester) async {
    await tester.pumpWidget(
      _wrap(SettingsScreen(
        localeNotifier: _makeLocaleNotifier(),
        difficultySettings: _makeDifficultySettings(),
      )),
    );
    await tester.pump();

    await _unlockSettings(tester);
    await tester.pump();

    expect(find.text('Easy'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('Hard'), findsOneWidget);
  });

  testWidgets('Difficulty sliders show current grid size values', (tester) async {
    final ds = DifficultySettings(easy: 3, medium: 4, hard: 5);
    await tester.pumpWidget(
      _wrap(SettingsScreen(
        localeNotifier: _makeLocaleNotifier(),
        difficultySettings: ds,
      )),
    );
    await tester.pump();

    await _unlockSettings(tester);
    await tester.pump();

    expect(find.text('3×3'), findsOneWidget);
    expect(find.text('4×4'), findsOneWidget);
    expect(find.text('5×5'), findsOneWidget);
  });
}
