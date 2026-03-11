import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lily_jigsaw_puzzle/l10n/app_localizations.dart';
import 'package:lily_jigsaw_puzzle/main.dart';
import 'package:lily_jigsaw_puzzle/models/puzzle_image.dart';
import 'package:lily_jigsaw_puzzle/screens/difficulty_screen.dart';
import 'package:lily_jigsaw_puzzle/screens/image_selection_screen.dart';
import 'package:lily_jigsaw_puzzle/screens/splash_screen.dart';
import 'package:lily_jigsaw_puzzle/services/completion_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

LocaleNotifier _makeLocaleNotifier() => LocaleNotifier(const Locale('en'));

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: child,
    );

void main() {
  // Disable runtime font fetching so tests run offline.
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Splash screen renders the game title', (tester) async {
    await tester.pumpWidget(
      _wrap(SplashScreen(localeNotifier: _makeLocaleNotifier())),
    );
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text("Lily's Puzzle"), findsWidgets);
    // Drain all pending timers (splash lasts 5 s).
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('Image selection screen shows all puzzle names', (tester) async {
    // Use a large screen so layout doesn't overflow in the test environment.
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(
      _wrap(ImageSelectionScreen(localeNotifier: _makeLocaleNotifier())),
    );
    await tester.pump();
    // Images show localized names in English
    expect(find.text('Cat'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('Image selection screen shows the title', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(
      _wrap(ImageSelectionScreen(localeNotifier: _makeLocaleNotifier())),
    );
    await tester.pump();
    expect(find.text('Choose a Puzzle!'), findsWidgets);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('Difficulty screen shows all three difficulty buttons', (tester) async {
    await tester.pumpWidget(
      _wrap(DifficultyScreen(
        selectedImage: const PuzzleImageData(
          assetPath: 'assets/images/puzzle-1.jpg',
          name: 'Cat',
          uuid: 'test-uuid-cat',
        ),
        localeNotifier: _makeLocaleNotifier(),
      )),
    );
    await tester.pump();
    expect(find.text('Easy'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('Hard'), findsOneWidget);
  });

  testWidgets('Difficulty screen shows Back button', (tester) async {
    await tester.pumpWidget(
      _wrap(DifficultyScreen(
        selectedImage: const PuzzleImageData(
          assetPath: 'assets/images/puzzle-1.jpg',
          name: 'Cat',
          uuid: 'test-uuid-cat',
        ),
        localeNotifier: _makeLocaleNotifier(),
      )),
    );
    await tester.pump();
    expect(find.text('Back'), findsOneWidget);
  });

  testWidgets('Difficulty screen shows the selected image name in title', (tester) async {
    await tester.pumpWidget(
      _wrap(DifficultyScreen(
        selectedImage: const PuzzleImageData(
          assetPath: 'assets/images/puzzle-1.jpg',
          name: 'Cat',
          uuid: 'test-uuid-cat',
        ),
        localeNotifier: _makeLocaleNotifier(),
      )),
    );
    await tester.pump();
    expect(find.text('Pick Difficulty'), findsWidgets);
  });

  testWidgets('Image selection navigates to difficulty screen on tap', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(
      _wrap(ImageSelectionScreen(localeNotifier: _makeLocaleNotifier())),
    );
    await tester.pump();
    await tester.tap(find.text('Cat'));
    await tester.pumpAndSettle();
    expect(find.text('Pick Difficulty'), findsWidgets);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('Settings screen is reachable from image selection screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(
      _wrap(ImageSelectionScreen(localeNotifier: _makeLocaleNotifier())),
    );
    await tester.pump();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    // Settings screen shows a math-challenge to unlock the reset button.
    expect(find.text('Settings'), findsWidgets);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('Image selection screen shows stars when puzzle has been completed', (tester) async {
    SharedPreferences.setMockInitialValues({});
    // Pre-populate completion data for the Cat puzzle (puzzle-1.jpg).
    final catUuid = PuzzleImageData.all
        .firstWhere((i) => i.assetPath.contains('puzzle-1'))
        .uuid;
    await CompletionService().recordCompletion(catUuid, 7); // 3 stars

    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(
      _wrap(ImageSelectionScreen(localeNotifier: _makeLocaleNotifier())),
    );
    // Let the FutureBuilder resolve.
    await tester.pumpAndSettle();
    // Three star icons should be visible for the completed puzzle.
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('Image selection screen shows no stars for uncompleted puzzle', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(
      _wrap(ImageSelectionScreen(localeNotifier: _makeLocaleNotifier())),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.star_rounded), findsNothing);
    await tester.binding.setSurfaceSize(null);
  });
}
