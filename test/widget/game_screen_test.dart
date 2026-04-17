import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lily_jigsaw_puzzle/l10n/app_localizations.dart';
import 'package:lily_jigsaw_puzzle/main.dart';
import 'package:lily_jigsaw_puzzle/models/puzzle_image.dart';
import 'package:lily_jigsaw_puzzle/screens/game_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

LocaleNotifier _makeLocaleNotifier() => LocaleNotifier(const Locale('en'));

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: child,
    );

const _testImage = PuzzleImageData(
  assetPath: 'assets/images/puzzle-1.jpg',
  name: 'Cat',
  uuid: 'test-uuid-cat',
);

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('GameScreen shows loading indicator before image loads', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(
      _wrap(GameScreen(
        selectedImage: _testImage,
        gridSize: 3,
        difficultyStars: 1,
        localeNotifier: _makeLocaleNotifier(),
      )),
    );
    // First frame always shows loading indicator since image is async
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // Drain pending timers / animations
    await tester.pump(const Duration(seconds: 10));
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('GameScreen pumps through full timeline without exception (3x3)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(
      _wrap(GameScreen(
        selectedImage: _testImage,
        gridSize: 3,
        difficultyStars: 1,
        localeNotifier: _makeLocaleNotifier(),
      )),
    );
    // Advance through: image load → 1 s delay → 1 500 ms scatter animation
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 200));
    // Verify the widget is still alive (either loading or game state)
    expect(find.byType(Scaffold), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('GameScreen disposes cleanly after pumping (3x3)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(
      _wrap(GameScreen(
        selectedImage: _testImage,
        gridSize: 3,
        difficultyStars: 1,
        localeNotifier: _makeLocaleNotifier(),
      )),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 1600));
    // Replace with empty container to trigger dispose
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('GameScreen pumps through full timeline without exception (5x5)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(
      _wrap(GameScreen(
        selectedImage: _testImage,
        gridSize: 5,
        difficultyStars: 2,
        localeNotifier: _makeLocaleNotifier(),
      )),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(Scaffold), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });
}
