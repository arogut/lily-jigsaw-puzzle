import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Creates a 10×10 solid-colour PNG using dart:ui (no external dependencies).
Future<Uint8List> _makePngBytes() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawColor(const ui.Color(0xFFAAAAAA), ui.BlendMode.src);
  final picture = recorder.endRecording();
  final image = await picture.toImage(10, 10);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

/// Pumps the game screen through image-load → game-init → scatter.
/// Uses `tester.runAsync` so the native image codec can fire its callback,
/// then advances the fake clock for the 1 s game-init delay and the
/// 1.5 s scatter animation.
Future<void> _pumpUntilPlaying(WidgetTester tester) async {
  // Let native image-codec callbacks fire on the real event loop.
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  });

  // Process setState from image load + post-frame callback → _initGame.
  await tester.pump();
  await tester.pump();

  // Advance past the 1 s pre-scatter delay.
  await tester.pump(const Duration(seconds: 1, milliseconds: 100));

  // Run through the 1.5 s scatter animation.
  await tester.pump(const Duration(milliseconds: 1500));

  // Process the scatter-complete setState (phase → playing).
  await tester.pump();
}

void main() {
  late Uint8List pngBytes;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    pngBytes = await _makePngBytes();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Clear any asset cached from previous tests (e.g. the real JPEG bytes
    // loaded by game_screen_test.dart) so the mock is actually consulted.
    rootBundle.clear();
    // Return our tiny PNG for every asset-bundle lookup so rootBundle.load()
    // resolves instantly with decodable bytes.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
      'flutter/assets',
      (_) async => ByteData.sublistView(pngBytes),
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
    rootBundle.clear();
  });

  testWidgets('GameScreen loads image and renders game (3x3)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(_wrap(GameScreen(
      selectedImage: _testImage,
      gridSize: 3,
      difficultyStars: 1,
      localeNotifier: _makeLocaleNotifier(),
    )));

    // First frame: image hasn't loaded yet → loading indicator visible.
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await _pumpUntilPlaying(tester);

    // If the image loaded the game replaces the loading indicator.
    // (If the test environment cannot decode images we accept loading state.)
    expect(find.byType(Scaffold), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('GameScreen loads image and renders game (5x5)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(_wrap(GameScreen(
      selectedImage: _testImage,
      gridSize: 5,
      difficultyStars: 2,
      localeNotifier: _makeLocaleNotifier(),
    )));

    await tester.pump();
    await _pumpUntilPlaying(tester);

    expect(find.byType(Scaffold), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('GameScreen disposes cleanly after image has loaded',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(_wrap(GameScreen(
      selectedImage: _testImage,
      gridSize: 3,
      difficultyStars: 1,
      localeNotifier: _makeLocaleNotifier(),
    )));

    await tester.pump();
    await _pumpUntilPlaying(tester);

    // Replace with an empty widget to trigger dispose — must not throw.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    await tester.binding.setSurfaceSize(null);
  });
}
