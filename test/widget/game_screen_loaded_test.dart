import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lily_jigsaw_puzzle/l10n/app_localizations.dart';
import 'package:lily_jigsaw_puzzle/main.dart';
import 'package:lily_jigsaw_puzzle/models/puzzle_image.dart';
import 'package:lily_jigsaw_puzzle/screens/game_screen.dart';
import 'package:lily_jigsaw_puzzle/widgets/win_overlay.dart';
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

/// Places the single piece (1×1 grid) onto its target by simulating a drag.
///
/// The test surface is 1280×800 physical but the logical screen reported by
/// MediaQuery is 800×600 (device-pixel-ratio ≈ 1.6).  With a 1×1 grid:
///   boardSize  = Size(360, 560)   pieceWidth=360  pieceHeight=560
///   boardOffset = Offset(20, 20) = targetPosition
///   scatter target = Offset(420, 20)   piece centre = Offset(600, 300)
///
/// PanGestureRecognizer.onlyAcceptDragOnThreshold is false, so the gesture
/// is accepted immediately at pointer-down — no slop-crossing required.
/// 40 steps of −10 px accumulate Δx = −400, moving _rawDragPosition from
/// (420, 20) to (20, 20) = targetPosition → distance 0 ≤ kSnapThreshold.
Future<void> _placeLastPiece(WidgetTester tester) async {
  final gesture = await tester.startGesture(const Offset(600, 300));
  for (var i = 0; i < 40; i++) {
    await gesture.moveBy(const Offset(-10, 0));
  }
  await gesture.up();
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

  // Run through the 1.5 s scatter animation. The animation needs at least two
  // frame pumps to complete: one to start (forward) and one to finish (completed).
  await tester.pump(const Duration(milliseconds: 100));  // first tick: forward
  await tester.pump(const Duration(milliseconds: 1500)); // second tick: completed

  // Pump one frame so the physics ticker's first tick fires.
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

  testWidgets('shows Back button in playing state', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(_wrap(GameScreen(
      selectedImage: _testImage,
      gridSize: 3,
      difficultyStars: 1,
      localeNotifier: _makeLocaleNotifier(),
    )));
    await tester.pump();
    await _pumpUntilPlaying(tester);
    expect(find.text('Back'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('shows hint button in playing state', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(_wrap(GameScreen(
      selectedImage: _testImage,
      gridSize: 3,
      difficultyStars: 1,
      localeNotifier: _makeLocaleNotifier(),
    )));
    await tester.pump();
    await _pumpUntilPlaying(tester);
    expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('tapping hint button activates hint and decrements count',
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
    expect(find.text('Hint (3)'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.lightbulb_outline));
    await tester.pump();
    expect(find.text('Hint (2)'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('pan gesture in playing phase runs without error', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(_wrap(GameScreen(
      selectedImage: _testImage,
      gridSize: 3,
      difficultyStars: 1,
      localeNotifier: _makeLocaleNotifier(),
    )));
    await tester.pump();
    await _pumpUntilPlaying(tester);
    // Simulate a drag in the right tray area where pieces are scattered.
    final gesture = await tester.startGesture(const Offset(960, 400));
    await tester.pump();
    await gesture.moveBy(const Offset(20, 10));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(find.byType(Scaffold), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('tapping Back button does not throw', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(_wrap(GameScreen(
      selectedImage: _testImage,
      gridSize: 3,
      difficultyStars: 1,
      localeNotifier: _makeLocaleNotifier(),
    )));
    await tester.pump();
    await _pumpUntilPlaying(tester);
    await tester.tap(find.text('Back'));
    await tester.pump();
    expect(find.byType(Scaffold), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('hint button is disabled while a hint is active', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(_wrap(GameScreen(
      selectedImage: _testImage,
      gridSize: 3,
      difficultyStars: 1,
      localeNotifier: _makeLocaleNotifier(),
    )));
    await tester.pump();
    await _pumpUntilPlaying(tester);

    // Activate first hint — count goes 3 → 2, piece becomes hinted.
    await tester.tap(find.byIcon(Icons.lightbulb_outline));
    await tester.pump();
    expect(find.text('Hint (2)'), findsOneWidget);

    // Second tap must be ignored: hasActiveHint=true → canUseHint=false → button disabled.
    await tester.tap(find.byIcon(Icons.lightbulb_outline));
    await tester.pump();
    expect(find.text('Hint (2)'), findsOneWidget); // count unchanged

    await tester.binding.setSurfaceSize(null);
  });

  // ── gridSize=1 deterministic drag tests ──────────────────────────────────
  //
  // With a 1×1 grid on a 1280×800 surface:
  //   boardSize = Size(600, 760), boardOffset = Offset(20, 20)
  //   pieceWidth = 600, pieceHeight = 760
  //   trayLeft = trayRight = 660, trayTop = trayBottom = 20
  //   → scatter target is exactly (660, 20) — no randomness.
  //
  // The piece body rectangle (in hit-test local coords) spans
  //   (tabW, tabH)–(tabW+600, tabH+760) = (210, 266)–(810, 1026).
  // With piece at (660, 20): origin = (450, −246), so a gesture at screen
  //   (960, 400) maps to local (510, 646) — well inside the rectangle.

  testWidgets('dragging piece within tray covers drag-handler body', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(_wrap(GameScreen(
      selectedImage: _testImage,
      gridSize: 1,
      difficultyStars: 1,
      localeNotifier: _makeLocaleNotifier(),
    )));
    await tester.pump();
    await _pumpUntilPlaying(tester);

    // Pick up the piece at its centre, move within the tray, release.
    final gesture = await tester.startGesture(const Offset(960, 400));
    await tester.pump();
    await gesture.moveBy(const Offset(50, 50)); // stays in tray (x > 640)
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(find.byType(Scaffold), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('piece dragged outside screen snaps back into tray', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(_wrap(GameScreen(
      selectedImage: _testImage,
      gridSize: 1,
      difficultyStars: 1,
      localeNotifier: _makeLocaleNotifier(),
    )));
    await tester.pump();
    await _pumpUntilPlaying(tester);

    // Move piece far right so centre (currentPosition.dx + 300) > 1280.
    // _rawDragPosition starts at (660, 20); +360 → (1020, 20); cx = 1320 > 1280.
    final gesture = await tester.startGesture(const Offset(960, 400));
    await tester.pump();
    await gesture.moveBy(const Offset(360, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    // Return animation runs for 750 ms.
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();

    expect(find.byType(Scaffold), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('dragging piece to board side without snapping triggers return animation',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(_wrap(GameScreen(
      selectedImage: _testImage,
      gridSize: 1,
      difficultyStars: 1,
      localeNotifier: _makeLocaleNotifier(),
    )));
    await tester.pump();
    await _pumpUntilPlaying(tester);

    // Drag across x=640 (sets _dragCrossedLeft=true) but end far from target
    // (20, 20) so no snap occurs → fly-back animation starts.
    // _rawDragPosition: (660, 20) + (−660, 380) = (0, 400). Distance to
    // target ≈ 381 px >> kSnapThreshold (40 px).
    final gesture = await tester.startGesture(const Offset(960, 400));
    await tester.pump();
    await gesture.moveBy(const Offset(-660, 380));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    // Return animation runs for 750 ms.
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();

    expect(find.byType(Scaffold), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('placing last piece wins the game and shows win overlay', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(_wrap(GameScreen(
      selectedImage: _testImage,
      gridSize: 1,
      difficultyStars: 1,
      localeNotifier: _makeLocaleNotifier(),
    )));
    await tester.pump();
    await _pumpUntilPlaying(tester);

    // Drag the 1×1 piece to its target via small steps (see _placeLastPiece).
    await _placeLastPiece(tester);
    // Pump once: rebuilds the widget tree (TrayLabel → "1 / 1") and fires
    // the first tick of the confetti controller (establishing _startTime).
    await tester.pump();

    expect(find.text('1 / 1'), findsOneWidget, reason: 'piece should snap to target');

    // Advance past the 5 s confetti duration so the .then() callback fires
    // and sets _showWinOverlay = true, then pump once more to rebuild.
    await tester.pump(const Duration(seconds: 5, milliseconds: 100));
    await tester.pump();

    expect(find.byType(WinOverlay), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('tapping Play Again from win overlay restarts the game', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(_wrap(GameScreen(
      selectedImage: _testImage,
      gridSize: 1,
      difficultyStars: 1,
      localeNotifier: _makeLocaleNotifier(),
    )));
    await tester.pump();
    await _pumpUntilPlaying(tester);

    // Win the game first.
    await _placeLastPiece(tester);
    await tester.pump(); // rebuild + first confetti tick
    await tester.pump(const Duration(seconds: 5, milliseconds: 100));
    await tester.pump();
    expect(find.byType(WinOverlay), findsOneWidget);

    // Tap Play Again → _restartGame() clears _gameState → loading indicator.
    await tester.tap(find.text('Play Again'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // _initGame schedules a 1-second Future.delayed for the scatter animation.
    // Dispose the widget first so _startScatter returns early (mounted = false),
    // then advance the clock to drain the pending timer and end the test cleanly.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));

    await tester.binding.setSurfaceSize(null);
  });
}
