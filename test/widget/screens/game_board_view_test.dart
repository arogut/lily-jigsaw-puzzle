import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lily_jigsaw_puzzle/l10n/app_localizations.dart';
import 'package:lily_jigsaw_puzzle/models/game_state.dart';
import 'package:lily_jigsaw_puzzle/painters/confetti_painter.dart';
import 'package:lily_jigsaw_puzzle/screens/game_board_view.dart';
import 'package:lily_jigsaw_puzzle/widgets/win_overlay.dart';

Future<ui.Image> _createTestImage() async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    const Rect.fromLTWH(0, 0, 64, 64),
    Paint()..color = const Color(0xFFFF0000),
  );
  final picture = recorder.endRecording();
  return picture.toImage(64, 64);
}

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: child,
    );

/// Test harness that owns [AnimationController]s so [GameBoardView] can be
/// pumped without a [StatefulWidget] ancestor providing a [TickerProvider].
class _BoardViewHarness extends StatefulWidget {
  const _BoardViewHarness({
    required this.gameState,
    required this.uiImage,
    this.showWinOverlay = false,
    this.onBack,
    this.onPlayAgain,
    this.onNewPuzzle,
    this.onHint,
  });

  final GameState gameState;
  final ui.Image uiImage;
  final bool showWinOverlay;
  final VoidCallback? onBack;
  final VoidCallback? onPlayAgain;
  final VoidCallback? onNewPuzzle;
  final VoidCallback? onHint;

  @override
  State<_BoardViewHarness> createState() => _BoardViewHarnessState();
}

class _BoardViewHarnessState extends State<_BoardViewHarness>
    with TickerProviderStateMixin {
  late AnimationController _hintController;
  late AnimationController _confettiController;
  final _paintTick = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
  }

  @override
  void dispose() {
    _hintController.dispose();
    _confettiController.dispose();
    _paintTick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: GameBoardView(
          gameState: widget.gameState,
          uiImage: widget.uiImage,
          paintTick: _paintTick,
          hintController: _hintController,
          confettiParticles: const [],
          confettiController: _confettiController,
          showWinOverlay: widget.showWinOverlay,
          onBack: widget.onBack ?? () {},
          onPlayAgain: widget.onPlayAgain ?? () {},
          onNewPuzzle: widget.onNewPuzzle ?? () {},
          onHint: widget.onHint,
        ),
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ui.Image testImage;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    testImage = await _createTestImage();
  });

  GameState makePlayingState() {
    final gs = GameState(
      puzzleImage: testImage,
      gridSize: 3,
      boardSize: const Size(300, 300),
      boardOffset: const Offset(20, 20),
    );
    gs.beginPlaying();
    return gs;
  }

  Future<void> pump(
    WidgetTester tester,
    GameState gs, {
    bool showWinOverlay = false,
    VoidCallback? onBack,
    VoidCallback? onPlayAgain,
    VoidCallback? onNewPuzzle,
    VoidCallback? onHint,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(_wrap(_BoardViewHarness(
      gameState: gs,
      uiImage: testImage,
      showWinOverlay: showWinOverlay,
      onBack: onBack,
      onPlayAgain: onPlayAgain,
      onNewPuzzle: onNewPuzzle,
      onHint: onHint,
    )));
    await tester.pump();
  }

  group('GameBoardView', () {
    testWidgets('shows back button in playing phase', (tester) async {
      final gs = makePlayingState();
      await pump(tester, gs);
      expect(find.text('Back'), findsOneWidget);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('shows hint button in playing phase', (tester) async {
      final gs = makePlayingState();
      await pump(tester, gs, onHint: () {});
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('back button invokes onBack callback when tapped', (tester) async {
      var called = false;
      final gs = makePlayingState();
      await pump(tester, gs, onBack: () => called = true);
      await tester.tap(find.text('Back'));
      await tester.pump();
      expect(called, isTrue);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('shows WinOverlay when phase is won and showWinOverlay is true',
        (tester) async {
      final gs = makePlayingState();
      // Place all pieces except the last one, then drag the last to its target.
      for (var i = 1; i < gs.pieces.length; i++) {
        gs.pieces[i].isPlaced = true;
      }
      gs.startDrag(0);
      gs.pieces.last.currentPosition = gs.pieces.last.targetPosition;
      gs.endDrag(); // phase transitions to won
      await pump(tester, gs, showWinOverlay: true);
      expect(find.byType(WinOverlay), findsOneWidget);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('does not show WinOverlay when showWinOverlay is false',
        (tester) async {
      final gs = makePlayingState();
      await pump(tester, gs);
      expect(find.byType(WinOverlay), findsNothing);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('hint button is dimmed when onHint is null', (tester) async {
      final gs = makePlayingState();
      await pump(tester, gs); // onHint = null → Opacity 0.5
      final opacity = tester.widget<Opacity>(
        find.ancestor(
          of: find.byIcon(Icons.lightbulb_outline),
          matching: find.byType(Opacity),
        ).first,
      );
      expect(opacity.opacity, 0.5);
      await tester.binding.setSurfaceSize(null);
    });
  });
}
