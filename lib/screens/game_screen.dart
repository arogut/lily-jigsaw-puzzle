import 'dart:async';
import 'dart:math' show Random, pi, sin;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter/services.dart';

import 'package:lily_jigsaw_puzzle/core/app_theme.dart';
import 'package:lily_jigsaw_puzzle/main.dart';
import 'package:lily_jigsaw_puzzle/models/game_state.dart';
import 'package:lily_jigsaw_puzzle/models/hint_slot_state.dart';
import 'package:lily_jigsaw_puzzle/models/puzzle_image.dart';
import 'package:lily_jigsaw_puzzle/models/puzzle_piece.dart';
import 'package:lily_jigsaw_puzzle/painters/confetti_painter.dart';
import 'package:lily_jigsaw_puzzle/painters/jigsaw_piece_painter.dart';
import 'package:lily_jigsaw_puzzle/screens/game_board_view.dart';
import 'package:lily_jigsaw_puzzle/services/completion_service.dart';
import 'package:lily_jigsaw_puzzle/services/hint_settings_service.dart';
import 'package:lily_jigsaw_puzzle/services/sound_service.dart';

class GameScreen extends StatefulWidget {

  const GameScreen({
    required this.selectedImage,
    required this.gridSize,
    required this.difficultyStars,
    required this.localeNotifier,
    required this.hintSettings,
    super.key,
  });
  final PuzzleImageData selectedImage;
  final int gridSize;

  /// Stars awarded for completing this difficulty (1 = easy, 2 = medium, 3 = hard).
  final int difficultyStars;
  final LocaleNotifier localeNotifier;

  /// Hint unlock configuration for this session.
  final HintSettings hintSettings;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  GameState? _gameState;
  ui.Image? _uiImage;

  late AnimationController _scatterController;
  late AnimationController _returnController;
  List<Offset>? _assembledPositions;
  List<Offset>? _scatterTargets;

  // Return-animation state — set when a piece is dropped in the wrong spot.
  PuzzlePiece? _returningPiece;
  Offset _returnFromPos = Offset.zero;
  Offset _returnToPos = Offset.zero;

  // Drag tracking: did the piece cross to the left (board) side during drag?
  bool _dragCrossedLeft = false;

  // Incrementing this repaint notifier repaints only the piece canvas without
  // triggering a full widget-tree rebuild.
  final _paintTick = ValueNotifier<int>(0);

  // Confetti
  late AnimationController _confettiController;
  List<ConfettiParticle> _confettiParticles = const [];
  bool _showWinOverlay = false;

  // Hint glow animation
  late AnimationController _hintController;

  // Hint available pop animation
  late AnimationController _hintAvailableController;
  late Animation<double> _hintAvailableAnimation;

  // Hints exhausted exit animation
  late AnimationController _hintsExhaustedController;
  late Animation<double> _hintsExhaustedAnimation;
  bool _showingHintArea = true;

  // Physics simulation ticker (momentum, gravity, bounce, flip animations).
  late Ticker _physicsTicker;
  Duration? _lastPhysicsTime;

  // Hint timer fields.
  Timer? _hintTimer;
  int _timerRemainingMs = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scatterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _returnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _returnController.addListener(_onReturnTick);
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    unawaited(_hintController.repeat());

    _physicsTicker = createTicker(_onPhysicsTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_uiImage == null) unawaited(_loadImage());
    if (_uiImage != null && _gameState == null) _initGame();
  }

  Future<void> _loadImage() async {
    final size = MediaQuery.of(context).size;
    final targetW = ((size.width / 2) - 2 * kEdgePad).round().clamp(64, 2048);

    final data = await rootBundle.load(widget.selectedImage.assetPath);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: targetW,
    );
    final frame = await codec.getNextFrame();

    if (!mounted) return;
    setState(() {
      _uiImage = frame.image;
    });
  }

  void _initGame() {
    final size = MediaQuery.of(context).size;
    const boardOffset = Offset(kEdgePad, kEdgePad);
    final boardSize = Size(
      size.width / 2 - 2 * kEdgePad,
      size.height - 2 * kEdgePad,
    );

    _gameState = GameState(
      puzzleImage: _uiImage!,
      gridSize: widget.gridSize,
      boardSize: boardSize,
      boardOffset: boardOffset,
      immediateMode: widget.hintSettings.immediateMode,
    );
    _assembledPositions =
        _gameState!.pieces.map((p) => p.targetPosition).toList();

    Future.delayed(const Duration(seconds: 1), _startScatter);
  }

  // ── Tray bounds used by physics ──────────────────────────────────────────

  Rect _trayBounds(Size screenSize) => Rect.fromLTRB(
        screenSize.width / 2 + kEdgePad,
        0,
        screenSize.width - kEdgePad,
        screenSize.height,
      );

  // ── Scatter: board positions → pile → physics scatter ────────────────────

  void _startScatter() {
    if (!mounted || _gameState == null) return;
    final size = MediaQuery.of(context).size;

    // Animate from board positions to spread positions across the right tray.
    _scatterTargets = _gameState!.computeScatterTargets(size);

    _gameState!.beginScattering();
    setState(() {}); // phase change → shadow layer + board grid update

    _scatterController
      ..reset()
      ..addListener(_onScatterTick)
      ..addStatusListener(_onScatterStatus);
    unawaited(_scatterController.forward());
  }

  void _onScatterTick() {
    if (_gameState == null ||
        _scatterTargets == null ||
        _assembledPositions == null) {
      return;
    }
    final t = _scatterController.value;
    final n = _gameState!.pieces.length;

    for (var i = 0; i < n; i++) {
      final slotWidth = 1.0 / n;
      final startI = i * slotWidth;
      final endI = (startI + slotWidth * 1.5).clamp(0.0, 1.0);
      final localT =
          endI == startI ? 1.0 : ((t - startI) / (endI - startI)).clamp(0.0, 1.0);
      final curved = Curves.easeInOut.transform(localT);
      _gameState!.setPiecePosition(
        i,
        Offset.lerp(_assembledPositions![i], _scatterTargets![i], curved)!,
      );
    }
    _paintTick.value++;
  }

  void _onScatterStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      // Start the physics simulation for piece momentum during play.
      _lastPhysicsTime = null;
      if (!_physicsTicker.isActive) unawaited(_physicsTicker.start());

      // Transition to playing immediately. Calling setState() here (inside a
      // Ticker/transient-callback phase) is safe: dirty elements are rebuilt
      // by handleDrawFrame() in the same pump, so the hint button becomes
      // enabled within the same pump() call that completes the scatter animation.
      if (mounted && _gameState != null) {
        _gameState!.beginPlaying();
        if (!widget.hintSettings.immediateMode) {
          _startHintTimer(widget.hintSettings.unlockDelaySeconds * 1000);
        }
        setState(() {}); // phase change → shadow layer + hint button update
      }
    }
  }

  // ── Hint timer ────────────────────────────────────────────────────────────

  void _startHintTimer(int delayMs) {
    _hintTimer?.cancel();
    _timerRemainingMs = delayMs;
    _hintTimer = Timer(Duration(milliseconds: delayMs), () {
      if (mounted && _gameState != null) {
        _gameState!.markNextSlotAvailable();
        unawaited(SoundService().playHintAvailable());
        _hintAvailableController.reset();
        unawaited(_hintAvailableController.forward());
        setState(() {});
      }
    });
  }

  void _cancelHintTimer() {
    _hintTimer?.cancel();
    _hintTimer = null;
  }

  void _resetHintTimer() {
    _cancelHintTimer();
    final gs = _gameState;
    if (gs == null ||
        widget.hintSettings.immediateMode ||
        gs.hasActiveHint ||
        gs.currentHintSlot != HintSlotState.waiting) {
      return;
    }
    _startHintTimer(widget.hintSettings.unlockDelaySeconds * 1000);
  }

  void _pauseHintTimer() {
    final timer = _hintTimer;
    if (timer == null || !timer.isActive) return;
    // Capture remaining time; dart:async Timer doesn't expose it directly,
    // so we approximate using the configured delay (conservative: restarts full).
    timer.cancel();
    _hintTimer = null;
  }

  void _resumeHintTimer() {
    final gs = _gameState;
    if (gs == null ||
        widget.hintSettings.immediateMode ||
        gs.hasActiveHint ||
        gs.currentHintSlot != HintSlotState.waiting ||
        _timerRemainingMs <= 0) {
      return;
    }
    _startHintTimer(_timerRemainingMs);
  }

  void _onHintTapped() {
    final gs = _gameState;
    if (gs == null) return;
    gs.activateHint();
    _cancelHintTimer();
    if (gs.currentHintSlot == null) {
      unawaited(SoundService().playHintsExhausted());
      _hintsExhaustedController.reset();
      unawaited(_hintsExhaustedController.forward().then((_) {
        if (mounted) setState(() => _showingHintArea = false);
      }));
    }
    setState(() {});
  }

  // ── Physics tick ─────────────────────────────────────────────────────────

  void _onPhysicsTick(Duration elapsed) {
    if (_gameState == null) return;

    final previous = _lastPhysicsTime;
    _lastPhysicsTime = elapsed;
    if (previous == null) return; // Skip first tick to get a valid dt.

    final dtMicro = elapsed.inMicroseconds - previous.inMicroseconds;
    final dt = (dtMicro / 1e6).clamp(0.0, 0.05);

    final size = MediaQuery.of(context).size;
    final changed = _gameState!.stepPhysics(dt, _trayBounds(size));
    if (changed) _paintTick.value++;
  }

  // ── Hit-test ──────────────────────────────────────────────────────────────

  // Hit-test which unplaced piece (if any) is under [localPos].
  int? _hitTestPiece(Offset localPos) {
    final gs = _gameState;
    if (gs == null) return null;
    final tabW = gs.pieceWidth * JigsawPiecePainter.tabFraction;
    final tabH = gs.pieceHeight * JigsawPiecePainter.tabFraction;

    for (var i = gs.pieces.length - 1; i >= 0; i--) {
      final piece = gs.pieces[i];
      if (piece.isPlaced) continue;
      if (piece == _returningPiece) continue; // untouchable during fly-back
      final origin = Offset(
        piece.currentPosition.dx - tabW,
        piece.currentPosition.dy - tabH,
      );
      final path = JigsawPiecePainter.buildPiecePath(
        piece.edges, gs.pieceWidth, gs.pieceHeight,
      );
      if (path.contains(localPos - origin)) return i;
    }
    return null;
  }

  // ── Drag handlers ─────────────────────────────────────────────────────────

  void _onPanStart(DragStartDetails d) {
    final gs = _gameState!;
    final idx = _hitTestPiece(d.localPosition);
    if (idx == null) return;
    // When a hint is active, only the hinted piece can be touched.
    if (gs.hasActiveHint && !gs.pieces[idx].isHinted) return;
    unawaited(HapticFeedback.lightImpact());
    gs.startDrag(idx);
    _dragCrossedLeft = false;
    _paintTick.value++;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final gs = _gameState!;
    if (gs.draggingIndex == null) return;
    gs.updateDrag(d.delta);
    final piece = gs.pieces[gs.draggingIndex!];
    if (piece.currentPosition.dx < MediaQuery.of(context).size.width / 2) {
      _dragCrossedLeft = true;
    }
    _paintTick.value++;
  }

  void _onPanEnd(DragEndDetails d) {
    final gs = _gameState!;
    if (gs.draggingIndex == null) return;
    final piece = gs.pieces[gs.draggingIndex!];
    if ((piece.currentPosition - piece.targetPosition).distance <= kSnapThreshold) {
      // Snapped into place — capture isHinted BEFORE endDrag() clears it.
      gs.endDrag();
      unawaited(SoundService().playSnap());
      if (gs.phase == GamePhase.won) {
        _cancelHintTimer();
        unawaited(_recordCompletion());
        unawaited(SoundService().playWin());
        _startConfetti();
      } else {
        if (!widget.hintSettings.immediateMode) {
          if (gs.isHintedPiecePlaced &&
              gs.currentHintSlot == HintSlotState.waiting) {
            // The hinted piece was just placed — start the next slot's timer.
            _cancelHintTimer();
            _startHintTimer(widget.hintSettings.unlockDelaySeconds * 1000);
          } else if (!gs.isHintedPiecePlaced) {
            // Regular placement attempt while idle timer is running — reset it.
            _resetHintTimer();
          }
          // FR-018: hinted piece exists but was NOT placed — do NOT start timer.
        }
        setState(() {}); // update tray label
      }
    } else if (_dragCrossedLeft) {
      // Piece was dragged to the board side but not placed — reset idle timer.
      if (!widget.hintSettings.immediateMode) _resetHintTimer();
      unawaited(HapticFeedback.mediumImpact());
      unawaited(SoundService().playWrong());
      gs.endDragNoPlace();
      _startReturnAnimation(piece);
    } else {
      // Piece never left the tray — apply momentum.
      gs.endDragNoPlace();
      if (!_snapToTrayIfOutside(piece, MediaQuery.of(context).size)) {
        _paintTick.value++;
      }
    }
  }

  // ── Return animation ──────────────────────────────────────────────────────

  void _onReturnTick() {
    final piece = _returningPiece;
    if (piece == null) return;
    final t = _returnController.value;

    if (t <= 0.40) {
      final st = t / 0.40;
      final shake = sin(st * pi * 4) * 14.0;
      piece.currentPosition = Offset(_returnFromPos.dx + shake, _returnFromPos.dy);
    } else {
      final rt = Curves.easeOut.transform((t - 0.40) / 0.60);
      piece.currentPosition = Offset.lerp(_returnFromPos, _returnToPos, rt)!;
    }
    _paintTick.value++;
  }

  void _startReturnAnimation(PuzzlePiece piece) {
    final size = MediaQuery.of(context).size;
    final gs = _gameState!;
    const margin = kEdgePad;
    final rng = Random();
    final trayX = (size.width / 2 + margin) +
        rng.nextDouble() *
            (size.width / 2 - margin * 2 - gs.pieceWidth)
                .clamp(0, double.infinity);
    final trayY = margin +
        rng.nextDouble() *
            (size.height - margin * 2 - gs.pieceHeight)
                .clamp(0, double.infinity);

    _returningPiece = piece;
    _returnFromPos = piece.currentPosition;
    _returnToPos = Offset(trayX, trayY);

    _returnController.reset();
    unawaited(_returnController.forward().then((_) {
      if (mounted) setState(() => _returningPiece = null);
    }));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hintTimer?.cancel();
    _physicsTicker.dispose();
    _scatterController
      ..removeListener(_onScatterTick)
      ..removeStatusListener(_onScatterStatus)
      ..dispose();
    _returnController
      ..removeListener(_onReturnTick)
      ..dispose();
    _confettiController.dispose();
    _hintController.dispose();
    _hintAvailableController.dispose();
    _hintsExhaustedController.dispose();
    _paintTick.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pauseHintTimer();
    } else if (state == AppLifecycleState.resumed) {
      _resumeHintTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF9BC8E8),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final img = _uiImage;
    if (img == null) return _buildLoading();

    final gs = _gameState;
    if (gs == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _gameState == null) _initGame();
      });
      return _buildLoading();
    }

    final isPlaying = gs.phase == GamePhase.playing;
    final showHintExitArea =
        isPlaying && gs.currentHintSlot == null && _showingHintArea;

    return GameBoardView(
      gameState: gs,
      uiImage: img,
      paintTick: _paintTick,
      hintController: _hintController,
      confettiParticles: _confettiParticles,
      confettiController: _confettiController,
      showWinOverlay: _showWinOverlay,
      onBack: () => Navigator.of(context).popUntil((r) => r.isFirst),
      onPlayAgain: _restartGame,
      onNewPuzzle: () => Navigator.of(context).popUntil((r) => r.isFirst),
      onPanStart: isPlaying ? _onPanStart : null,
      onPanUpdate: isPlaying ? _onPanUpdate : null,
      onPanEnd: isPlaying ? _onPanEnd : null,
      currentHintSlot: isPlaying ? gs.currentHintSlot : null,
      hintAvailableAnimation: isPlaying ? _hintAvailableAnimation : null,
      hintsExhaustedAnimation:
          showHintExitArea ? _hintsExhaustedAnimation : null,
      showHintArea: showHintExitArea,
      onHint: _onHintTapped,
    );
  }

  Widget _buildLoading() {
    return Container(
      decoration: AppTheme.backgroundDecoration,
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 4),
      ),
    );
  }

  void _restartGame() {
    _cancelHintTimer();
    _timerRemainingMs = 0;
    _physicsTicker.stop();
    _lastPhysicsTime = null;
    _scatterController
      ..removeListener(_onScatterTick)
      ..removeStatusListener(_onScatterStatus);
    _confettiController.stop();
    _hintsExhaustedController.reset();
    setState(() {
      _gameState = null;
      _assembledPositions = null;
      _scatterTargets = null;
      _showWinOverlay = false;
      _showingHintArea = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initGame();
    });
  }

  Future<void> _recordCompletion() async {
    await CompletionService().recordCompletion(
      widget.selectedImage.uuid,
      widget.difficultyStars,
    );
  }

  /// If the piece centre has gone outside the visible screen bounds,
  /// animates it back to a random position in the right-side tray.
  /// Returns true if an animation was started, false if no action was needed.
  bool _snapToTrayIfOutside(PuzzlePiece piece, Size screenSize) {
    final gs = _gameState!;
    final cx = piece.currentPosition.dx + gs.pieceWidth / 2;
    final cy = piece.currentPosition.dy + gs.pieceHeight / 2;
    if (cx <= screenSize.width && cy >= 0 && cy <= screenSize.height) {
      return false;
    }
    _startReturnAnimation(piece);
    return true;
  }

  // ── Confetti helpers ───────────────────────────────────────────────────────

  void _startConfetti() {
    _physicsTicker.stop();
    _confettiParticles = generateConfettiParticles(250);
    setState(() {}); // show confetti layer
    _confettiController.reset();
    unawaited(_confettiController.forward().then((_) {
      if (mounted) setState(() => _showWinOverlay = true);
    }));
  }
}
