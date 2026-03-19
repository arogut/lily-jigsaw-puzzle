import 'dart:async';
import 'dart:math' show Random, pi, sin;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter/services.dart';

import 'package:lily_jigsaw_puzzle/core/app_theme.dart';
import 'package:lily_jigsaw_puzzle/l10n/app_localizations.dart';
import 'package:lily_jigsaw_puzzle/main.dart';
import 'package:lily_jigsaw_puzzle/models/game_state.dart';
import 'package:lily_jigsaw_puzzle/models/puzzle_image.dart';
import 'package:lily_jigsaw_puzzle/models/puzzle_piece.dart';
import 'package:lily_jigsaw_puzzle/painters/all_pieces_painter.dart';
import 'package:lily_jigsaw_puzzle/painters/board_grid_painter.dart';
import 'package:lily_jigsaw_puzzle/painters/board_shadow_painter.dart';
import 'package:lily_jigsaw_puzzle/painters/confetti_painter.dart';
import 'package:lily_jigsaw_puzzle/painters/hint_glow_painter.dart';
import 'package:lily_jigsaw_puzzle/painters/jigsaw_piece_painter.dart';
import 'package:lily_jigsaw_puzzle/services/completion_service.dart';
import 'package:lily_jigsaw_puzzle/services/sound_service.dart';
import 'package:lily_jigsaw_puzzle/widgets/game_button.dart';
import 'package:lily_jigsaw_puzzle/widgets/tray_label.dart';
import 'package:lily_jigsaw_puzzle/widgets/win_overlay.dart';

const _kEdgePad = 20.0;

// Physics scatter settles for this long before playing phase begins.
const _kScatterSettleMs = 1200;

class GameScreen extends StatefulWidget {

  const GameScreen({
    required this.selectedImage, required this.gridSize, required this.localeNotifier, super.key,
  });
  final PuzzleImageData selectedImage;
  final int gridSize;
  final LocaleNotifier localeNotifier;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
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

  // Physics simulation ticker (momentum, gravity, bounce, flip animations).
  late Ticker _physicsTicker;
  Duration? _lastPhysicsTime;

  @override
  void initState() {
    super.initState();
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
    final targetW = ((size.width / 2) - 2 * _kEdgePad).round().clamp(64, 2048);

    final data = await rootBundle.load(widget.selectedImage.assetPath);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: targetW,
    );
    final frame = await codec.getNextFrame();
    if (!mounted) return;
    setState(() => _uiImage = frame.image);
  }

  void _initGame() {
    final size = MediaQuery.of(context).size;
    const boardOffset = Offset(_kEdgePad, _kEdgePad);
    final boardSize = Size(
      size.width / 2 - 2 * _kEdgePad,
      size.height - 2 * _kEdgePad,
    );

    _gameState = GameState(
      puzzleImage: _uiImage!,
      gridSize: widget.gridSize,
      boardSize: boardSize,
      boardOffset: boardOffset,
    );
    _assembledPositions =
        _gameState!.pieces.map((p) => p.targetPosition).toList();

    Future.delayed(const Duration(seconds: 1), _startScatter);
  }

  // ── Tray bounds used by physics ──────────────────────────────────────────

  Rect _trayBounds(Size screenSize) => Rect.fromLTRB(
        screenSize.width / 2 + _kEdgePad,
        0,
        screenSize.width - _kEdgePad,
        screenSize.height,
      );

  // ── Scatter: board positions → pile → physics scatter ────────────────────

  void _startScatter() {
    if (!mounted || _gameState == null) return;
    final size = MediaQuery.of(context).size;

    // Animate from board positions to a tight pile at the tray centre.
    _scatterTargets = _gameState!.computePilePositions(size);

    // All pieces start face-down as they scatter off the board.
    for (final piece in _gameState!.pieces) {
      piece
        ..isFaceDown = true
        ..flipProgress = 0.0;
    }

    setState(() => _gameState!.phase = GamePhase.scattering);

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
      // Pieces are now in the pile. Apply explosive outward velocities so the
      // physics ticker scatters them across the tray.
      final size = MediaQuery.of(context).size;
      _gameState!.applyScatterVelocities(size);

      // Start the physics simulation.
      _lastPhysicsTime = null;
      if (!_physicsTicker.isActive) unawaited(_physicsTicker.start());

      // Wait for velocities to settle before entering playing phase.
      Future.delayed(
        const Duration(milliseconds: _kScatterSettleMs),
        () {
          if (mounted && _gameState != null) {
            _gameState!.beginPlaying();
            setState(() {}); // phase change → shadow layer + hint button update
          }
        },
      );
    }
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
    const margin = _kEdgePad;
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
    _paintTick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF9BC8E8),
      body: _uiImage == null ? _buildLoading() : _buildGame(),
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

  Widget _buildGame() {
    if (_gameState == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _gameState == null) _initGame();
      });
      return _buildLoading();
    }

    final gs = _gameState!;
    final l10n = AppLocalizations.of(context)!;
    final boardW = gs.boardSize.width;
    final boardH = gs.boardSize.height;
    final boardOffX = gs.boardOffset.dx;
    final boardOffY = gs.boardOffset.dy;
    final dividerX = boardOffX + boardW + _kEdgePad;
    final screenWidth = MediaQuery.of(context).size.width;
    final canUseHint = gs.phase == GamePhase.playing &&
        gs.hintsRemaining > 0 &&
        !gs.hasActiveHint;

    return Stack(
      children: [
        // ── Panel backgrounds ───────────────────────────────────────────────
        Positioned.fill(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFB8DEFF), Color(0xFF8EC8F8)],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFD8BAFF), Color(0xFFFFABD0)],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Board grid ghost ────────────────────────────────────────────────
        Positioned(
          left: boardOffX, top: boardOffY, width: boardW, height: boardH,
          child: CustomPaint(painter: BoardGridPainter(gs.gridSize)),
        ),

        // ── Shadow hints ────────────────────────────────────────────────────
        if (gs.phase == GamePhase.scattering || gs.phase == GamePhase.playing)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: BoardShadowPainter(
                  pieces: gs.pieces,
                  pieceWidth: gs.pieceWidth,
                  pieceHeight: gs.pieceHeight,
                ),
              ),
            ),
          ),

        // ── Divider ─────────────────────────────────────────────────────────
        Positioned(
          left: dividerX - 3, top: 0, bottom: 0, width: 6,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.hotPink,
                  Color(0xFFFFD93D),
                  AppColors.green,
                  AppColors.blue,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),

        // ── ALL PIECES — single CustomPaint + single GestureDetector ────────
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanStart: gs.phase == GamePhase.playing
                ? (d) {
                    final idx = _hitTestPiece(d.localPosition);
                    if (idx != null) {
                      // When a hint is active, only the hinted piece can be touched.
                      if (gs.hasActiveHint && !gs.pieces[idx].isHinted) return;
                      final piece = gs.pieces[idx];
                      if (piece.isFaceDown) {
                        // Tap on a face-down piece triggers a flip instead of drag.
                        gs.flipPiece(piece);
                        unawaited(HapticFeedback.lightImpact());
                        return;
                      }
                      unawaited(HapticFeedback.lightImpact());
                      gs.startDrag(idx);
                      _dragCrossedLeft = false;
                      _paintTick.value++;
                    }
                  }
                : null,
            onPanUpdate: gs.phase == GamePhase.playing
                ? (d) {
                    if (gs.draggingIndex == null) return;
                    gs.updateDrag(d.delta);
                    // Track whether the piece ever crossed to the board (left) side
                    final piece = gs.pieces[gs.draggingIndex!];
                    if (piece.currentPosition.dx < screenWidth / 2) {
                      _dragCrossedLeft = true;
                    }
                    _paintTick.value++;
                  }
                : null,
            onPanEnd: gs.phase == GamePhase.playing
                ? (d) {
                    if (gs.draggingIndex == null) return;
                    final piece = gs.pieces[gs.draggingIndex!];
                    const snapThreshold = 40.0;
                    if ((piece.currentPosition - piece.targetPosition)
                            .distance <=
                        snapThreshold) {
                      // Snapped into place.
                      gs.endDrag();
                      unawaited(SoundService().playSnap());
                      if (gs.phase == GamePhase.won) {
                        unawaited(_recordCompletion());
                        unawaited(SoundService().playWin());
                        _startConfetti();
                      } else {
                        setState(() {}); // update tray label
                      }
                    } else if (_dragCrossedLeft) {
                      // Piece was dragged to the board side but not placed — shake + fly-back
                      unawaited(HapticFeedback.mediumImpact());
                      unawaited(SoundService().playWrong());
                      gs.endDragNoPlace();
                      _startReturnAnimation(piece);
                    } else {
                      // Piece never left the tray — apply momentum and check group formation.
                      gs.endDragNoPlace();
                      if (!_snapToTrayIfOutside(
                          piece, MediaQuery.of(context).size)) {
                        gs.checkGroupFormation(piece);
                        _paintTick.value++;
                      }
                    }
                  }
                : null,
            child: CustomPaint(
              painter: AllPiecesPainter(
                pieces: gs.pieces,
                image: _uiImage!,
                pieceWidth: gs.pieceWidth,
                pieceHeight: gs.pieceHeight,
                repaintNotifier: _paintTick,
                hasActiveHint: gs.hasActiveHint,
              ),
            ),
          ),
        ),

        // ── Hint glow overlay (on top of pieces so border is visible) ────────
        if (gs.phase == GamePhase.playing && gs.hasActiveHint)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: HintGlowPainter(
                  pieces: gs.pieces,
                  pieceWidth: gs.pieceWidth,
                  pieceHeight: gs.pieceHeight,
                  animation: _hintController,
                ),
              ),
            ),
          ),

        // ── Back button ─────────────────────────────────────────────────────
        Positioned(
          left: 8, top: 8,
          child: GameButton(
            label: l10n.back,
            icon: Icons.arrow_back_rounded,
            color: AppColors.mediumPurple,
            width: 120,
            height: 44,
            fontSize: 15,
            onPressed: () =>
                Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ),

        // ── Right-side controls: hint button + tray label ────────────────────
        Positioned(
          right: _kEdgePad, top: 8,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Opacity(
                  opacity: canUseHint ? 1.0 : 0.5,
                  child: GameButton(
                    label: '${l10n.hint} (${gs.hintsRemaining})',
                    icon: Icons.lightbulb_outline,
                    color: AppColors.amber,
                    width: 120,
                    height: 44,
                    fontSize: 15,
                    enabled: canUseHint,
                    onPressed: canUseHint
                        ? () {
                            gs.activateHint();
                            setState(() {});
                          }
                        : () {},
                  ),
                ),
              ),
              TrayLabel(
                placed: gs.pieces.where((p) => p.isPlaced).length,
                total: gs.pieces.length,
              ),
            ],
          ),
        ),

        // ── Confetti ────────────────────────────────────────────────────────
        if (gs.phase == GamePhase.won && !_showWinOverlay)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: ConfettiPainter(
                  particles: _confettiParticles,
                  animation: _confettiController,
                ),
              ),
            ),
          ),

        // ── Win overlay ─────────────────────────────────────────────────────
        if (gs.phase == GamePhase.won && _showWinOverlay)
          WinOverlay(
            onPlayAgain: _restartGame,
            onNewPuzzle: () =>
                Navigator.of(context).popUntil((r) => r.isFirst),
          ),
      ],
    );
  }

  void _restartGame() {
    _physicsTicker.stop();
    _lastPhysicsTime = null;
    _scatterController
      ..removeListener(_onScatterTick)
      ..removeStatusListener(_onScatterStatus);
    _confettiController.stop();
    setState(() {
      _gameState = null;
      _assembledPositions = null;
      _scatterTargets = null;
      _showWinOverlay = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initGame();
    });
  }

  Future<void> _recordCompletion() async {
    await CompletionService().recordCompletion(
      widget.selectedImage.uuid,
      widget.gridSize,
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
    _confettiParticles = _generateConfetti(250);
    setState(() {}); // show confetti layer
    _confettiController.reset();
    unawaited(_confettiController.forward().then((_) {
      if (mounted) setState(() => _showWinOverlay = true);
    }));
  }

  List<ConfettiParticle> _generateConfetti(int count) {
    final rng = Random();
    const colors = [
      AppColors.red, Color(0xFFFFD93D), AppColors.green,
      AppColors.blue, AppColors.hotPink, AppColors.lavender,
      AppColors.orange, Color(0xFF00E5FF), Colors.white,
    ];
    return List.generate(count, (_) => ConfettiParticle(
      x: rng.nextDouble(),
      speed: 0.40 + rng.nextDouble() * 0.90,
      startDelay: rng.nextDouble() * 0.30,
      color: colors[rng.nextInt(colors.length)],
      size: 6.0 + rng.nextDouble() * 16.0,
      rotSpeed: 2.0 + rng.nextDouble() * 6.0,
      wobblePhase: rng.nextDouble() * 2 * pi,
      isRect: rng.nextBool(),
    ));
  }
}
