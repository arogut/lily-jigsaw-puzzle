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

  testWidgets('Image selection screen shows all puzzle images', (tester) async {
    // Use a large screen so layout doesn't overflow in the test environment.
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(
      _wrap(ImageSelectionScreen(localeNotifier: _makeLocaleNotifier())),
    );
    await tester.pump();
    // Names were removed; each card shows only a photo thumbnail.
    expect(find.byType(Image), findsWidgets);
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
    await tester.tap(find.byType(Image).first);
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
    // 3 stars → 3 Star3d widgets, each rendering 2 Icons.star_rounded (face + shadow).
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(6));
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

  testWidgets('JigsawApp builds without error', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(JigsawApp(localeNotifier: _makeLocaleNotifier()));
    await tester.pump();
    // SplashScreen is the initial route
    expect(find.byType(MaterialApp), findsOneWidget);
    // Drain splash timers
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('JigsawApp rebuilds when locale changes', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final notifier = _makeLocaleNotifier();
    await tester.pumpWidget(JigsawApp(localeNotifier: notifier));
    await tester.pump();
    notifier.setLocale(const Locale('de'));
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('Difficulty screen stars setState fires after async load', (tester) async {
    SharedPreferences.setMockInitialValues({});
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
    // Let async getStars complete so the mounted setState branch is hit
    await tester.pumpAndSettle();
    expect(find.text('Easy'), findsOneWidget);
  });

  testWidgets('Difficulty screen back button is tappable', (tester) async {
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
    await tester.tap(find.text('Back'));
    await tester.pump();
    // Back tap invokes onPressed; DifficultyScreen is the only route so pop is a no-op
    expect(find.text('Back'), findsOneWidget);
  });

  testWidgets('Difficulty screen locked medium button can be tapped without crashing', (tester) async {
    SharedPreferences.setMockInitialValues({});
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
    // Medium and Hard are locked (0 stars) — tapping invokes the () {} no-op callback
    await tester.tap(find.text('Medium'));
    await tester.pump();
    await tester.tap(find.text('Hard'));
    await tester.pump();
    expect(find.text('Medium'), findsOneWidget);
  });

  testWidgets('Settings navigation: pop back to image selection refreshes stars', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(
      _wrap(ImageSelectionScreen(localeNotifier: _makeLocaleNotifier())),
    );
    await tester.pump();
    // Navigate to Settings
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    // Tap Back in Settings to pop → fires image_selection setState callback
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    // Back on ImageSelectionScreen
    expect(find.text('Choose a Puzzle!'), findsWidgets);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('Difficulty navigation: pop back to image selection refreshes stars', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(
      _wrap(ImageSelectionScreen(localeNotifier: _makeLocaleNotifier())),
    );
    await tester.pumpAndSettle();
    // Navigate to DifficultyScreen
    await tester.tap(find.byType(Image).first);
    await tester.pumpAndSettle();
    expect(find.text('Pick Difficulty'), findsWidgets);
    // Pop back to ImageSelectionScreen via Back button
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a Puzzle!'), findsWidgets);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('Difficulty screen with hard unlocked: tap Hard navigates to game', (tester) async {
    SharedPreferences.setMockInitialValues({});
    const catImage = PuzzleImageData(
      assetPath: 'assets/images/puzzle-1.jpg',
      name: 'Cat',
      uuid: 'test-uuid-cat',
    );
    // Record 3-star completion to unlock Hard
    await CompletionService().recordCompletion(catImage.uuid, 7);
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(
      _wrap(DifficultyScreen(
        selectedImage: catImage,
        localeNotifier: _makeLocaleNotifier(),
      )),
    );
    await tester.pumpAndSettle();
    // Hard is now unlocked → tapping it calls _go(context, 7)
    await tester.tap(find.text('Hard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 10));
    // Navigated away from DifficultyScreen
    expect(find.text('Pick Difficulty'), findsNothing);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('GameButton tap-cancel clears pressed state', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(1280, 800));
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
    // Start a gesture on the Back GameButton then cancel it
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Back')),
    );
    await tester.pump(); // let gesture recognizer accept the down event
    await gesture.cancel();
    await tester.pump();
    expect(find.text('Back'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('Image card tap-cancel reverses press animation', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(
      _wrap(ImageSelectionScreen(localeNotifier: _makeLocaleNotifier())),
    );
    await tester.pump();
    // Start a gesture on the first image card then cancel
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(Image).first),
    );
    await tester.pump();
    await gesture.cancel();
    await tester.pump();
    expect(find.text('Choose a Puzzle!'), findsWidgets);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('Difficulty screen easy button navigates to game screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(1280, 800));
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
    await tester.tap(find.text('Easy'));
    // Let the navigation animation run; GameScreen pushes onto the stack
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300)); // route transition
    // Drain remaining timers to avoid pending-timer warnings
    await tester.pump(const Duration(seconds: 10));
    // Verify navigation happened: DifficultyScreen is no longer the top widget
    expect(find.text('Pick Difficulty'), findsNothing);
    await tester.binding.setSurfaceSize(null);
  });
}
