import 'dart:async';
import 'dart:math' show Random, cos, pi, sin;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lily_jigsaw_puzzle/l10n/app_localizations.dart';
import 'package:lily_jigsaw_puzzle/main.dart';
import 'package:lily_jigsaw_puzzle/models/game_state.dart';
import 'package:lily_jigsaw_puzzle/models/puzzle_image.dart';
import 'package:lily_jigsaw_puzzle/models/puzzle_piece.dart';
import 'package:lily_jigsaw_puzzle/painters/jigsaw_piece_painter.dart';
import 'package:lily_jigsaw_puzzle/services/completion_service.dart';
import 'package:lily_jigsaw_puzzle/widgets/game_button.dart';

const _kEdgePad = 20.0;

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
  List<_ConfettiParticle> _confettiParticles = const [];
  bool _showWinOverlay = false;

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

  void _startScatter() {
    if (!mounted || _gameState == null) return;
    final size = MediaQuery.of(context).size;
    _scatterTargets = _gameState!.computeScatterTargets(size);

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
      _gameState!.beginPlaying();
      setState(() {}); // phase change → shadow layer updates
    }
  }

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
    _scatterController
      ..removeListener(_onScatterTick)
      ..removeStatusListener(_onScatterStatus)
      ..dispose();
    _returnController
      ..removeListener(_onReturnTick)
      ..dispose();
    _confettiController.dispose();
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF87CEEB), Color(0xFFB39DDB), Color(0xFFFFABD0)],
          stops: [0.0, 0.50, 1.0],
        ),
      ),
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
          child: CustomPaint(painter: _BoardGridPainter(gs.gridSize)),
        ),

        // ── Shadow hints ────────────────────────────────────────────────────
        if (gs.phase == GamePhase.scattering || gs.phase == GamePhase.playing)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _BoardShadowPainter(
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
                  Color(0xFFFF6B9D),
                  Color(0xFFFFD93D),
                  Color(0xFF6BCB77),
                  Color(0xFF4D96FF),
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
                ? (_) {
                    if (gs.draggingIndex == null) return;
                    final piece = gs.pieces[gs.draggingIndex!];
                    const snapThreshold = 40.0;
                    if ((piece.currentPosition - piece.targetPosition)
                            .distance <=
                        snapThreshold) {
                      // Snapped into place
                      gs.endDrag();
                      if (gs.phase == GamePhase.won) {
                        unawaited(_recordCompletion());
                        _startConfetti();
                      } else {
                        setState(() {}); // update tray label
                      }
                    } else if (_dragCrossedLeft) {
                      // Piece was dragged to the board side but not placed — shake + fly-back
                      unawaited(HapticFeedback.mediumImpact());
                      gs.endDragNoPlace();
                      _startReturnAnimation(piece);
                    } else {
                      // Piece never left the tray — drop where it is, but
                      // animate back if it was dragged outside the screen.
                      final droppedPiece = gs.pieces[gs.draggingIndex!];
                      gs.endDragNoPlace();
                      if (!_snapToTrayIfOutside(
                          droppedPiece, MediaQuery.of(context).size)) {
                        _paintTick.value++;
                      }
                    }
                  }
                : null,
            child: CustomPaint(
              painter: _AllPiecesPainter(
                pieces: gs.pieces,
                image: _uiImage!,
                pieceWidth: gs.pieceWidth,
                pieceHeight: gs.pieceHeight,
                repaintNotifier: _paintTick,
              ),
            ),
          ),
        ),

        // ── Tray label ──────────────────────────────────────────────────────
        Positioned(
          right: _kEdgePad, top: _kEdgePad,
          child: _TrayLabel(
            placed: gs.pieces.where((p) => p.isPlaced).length,
            total: gs.pieces.length,
          ),
        ),

        // ── Back button ─────────────────────────────────────────────────────
        Positioned(
          left: 8, top: 8,
          child: GameButton(
            label: l10n.back,
            icon: Icons.arrow_back_rounded,
            color: const Color(0xFF9B59B6),
            width: 120,
            height: 44,
            fontSize: 15,
            onPressed: () =>
                Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ),

        // ── Confetti ────────────────────────────────────────────────────────
        if (gs.phase == GamePhase.won && !_showWinOverlay)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ConfettiPainter(
                  particles: _confettiParticles,
                  animation: _confettiController,
                ),
              ),
            ),
          ),

        // ── Win overlay ─────────────────────────────────────────────────────
        if (gs.phase == GamePhase.won && _showWinOverlay) _buildWinOverlay(l10n),
      ],
    );
  }

  Widget _buildWinOverlay(AppLocalizations l10n) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xBB000040), Color(0xBB000020)],
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF8FF), Color(0xFFFFEEFF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B9D).withValues(alpha: 0.50),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: const Color(0xFFFF6B9D).withValues(alpha: 0.50),
                width: 2.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 72)),
                const SizedBox(height: 10),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      l10n.youDidIt,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 5
                          ..color = const Color(0xFF6A1B9A),
                      ),
                    ),
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [Color(0xFFFFD93D), Color(0xFFFF6B9D)],
                      ).createShader(b),
                      child: Text(
                        l10n.youDidIt,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.puzzleComplete,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6A1B9A).withValues(alpha: 0.70),
                  ),
                ),
                const SizedBox(height: 28),
                GameButton(
                  label: l10n.playAgain,
                  icon: Icons.replay_rounded,
                  color: const Color(0xFF6BCB77),
                  shadowColor: const Color(0xFF3A9E48),
                  width: 220,
                  height: 56,
                  onPressed: _restartGame,
                ),
                const SizedBox(height: 12),
                GameButton(
                  label: l10n.newPuzzle,
                  icon: Icons.home_rounded,
                  color: const Color(0xFF4D96FF),
                  shadowColor: const Color(0xFF2460CC),
                  width: 220,
                  height: 56,
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _restartGame() {
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

  /// If the piece center has gone outside the visible screen bounds,
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
    _confettiParticles = _generateConfetti(250);
    setState(() {}); // show confetti layer
    _confettiController.reset();
    unawaited(_confettiController.forward().then((_) {
      if (mounted) setState(() => _showWinOverlay = true);
    }));
  }

  List<_ConfettiParticle> _generateConfetti(int count) {
    final rng = Random();
    const colors = [
      Color(0xFFFF6B6B), Color(0xFFFFD93D), Color(0xFF6BCB77),
      Color(0xFF4D96FF), Color(0xFFFF6B9D), Color(0xFFB39DDB),
      Color(0xFFFFAB40), Color(0xFF00E5FF), Color(0xFFFFFFFF),
    ];
    return List.generate(count, (_) => _ConfettiParticle(
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

// ── Single-canvas painter for ALL puzzle pieces ────────────────────────────────

class _AllPiecesPainter extends CustomPainter {

  _AllPiecesPainter({
    required this.pieces,
    required this.image,
    required this.pieceWidth,
    required this.pieceHeight,
    required ValueNotifier<int> repaintNotifier,
  }) : super(repaint: repaintNotifier);
  final List<PuzzlePiece> pieces;
  final ui.Image image;
  final double pieceWidth;
  final double pieceHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final tabW = pieceWidth * JigsawPiecePainter.tabFraction;
    final tabH = pieceHeight * JigsawPiecePainter.tabFraction;
    final pieceCanvasSize = Size(pieceWidth + 2 * tabW, pieceHeight + 2 * tabH);

    for (final piece in pieces) {
      canvas
        ..save()
        ..translate(
          piece.currentPosition.dx - tabW,
          piece.currentPosition.dy - tabH,
        );
      JigsawPiecePainter(
        piece: piece,
        image: image,
        pieceWidth: pieceWidth,
        pieceHeight: pieceHeight,
      ).paint(canvas, pieceCanvasSize);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_AllPiecesPainter old) => true;
}

// ── Board grid ghost painter ──────────────────────────────────────────────────

class _BoardGridPainter extends CustomPainter {
  const _BoardGridPainter(this.gridSize);
  final int gridSize;

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / gridSize;
    final cellH = size.height / gridSize;

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.30)
      ..strokeWidth = 1.0;
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.50)
      ..strokeWidth = 0;

    for (var r = 0; r <= gridSize; r++) {
      final y = r * cellH;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    for (var c = 0; c <= gridSize; c++) {
      final x = c * cellW;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (var r = 0; r <= gridSize; r++) {
      for (var c = 0; c <= gridSize; c++) {
        canvas.drawCircle(Offset(c * cellW, r * cellH), 2.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_BoardGridPainter old) => old.gridSize != gridSize;
}

// ── Board shadow hints painter ────────────────────────────────────────────────

class _BoardShadowPainter extends CustomPainter {

  const _BoardShadowPainter({
    required this.pieces,
    required this.pieceWidth,
    required this.pieceHeight,
  });
  final List<PuzzlePiece> pieces;
  final double pieceWidth;
  final double pieceHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final tabW = pieceWidth * JigsawPiecePainter.tabFraction;
    final tabH = pieceHeight * JigsawPiecePainter.tabFraction;

    for (final piece in pieces) {
      if (piece.isPlaced) continue;
      canvas
        ..save()
        ..translate(
          piece.targetPosition.dx - tabW,
          piece.targetPosition.dy - tabH,
        );
      final path = JigsawPiecePainter.buildPiecePath(
        piece.edges, pieceWidth, pieceHeight,
      );
      canvas
        ..drawPath(path, Paint()..color = const Color(0x40000000))
        ..drawPath(
          path,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_BoardShadowPainter old) {
    if (old.pieces.length != pieces.length) return true;
    for (var i = 0; i < pieces.length; i++) {
      if (old.pieces[i].isPlaced != pieces[i].isPlaced) return true;
    }
    return false;
  }
}

// ── Tray piece counter label ──────────────────────────────────────────────────

class _TrayLabel extends StatelessWidget {
  const _TrayLabel({required this.placed, required this.total});
  final int placed;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '$placed / $total',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: Color(0xFF6A1B9A),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Confetti ──────────────────────────────────────────────────────────────────

class _ConfettiParticle {        // rectangle (true) or oval (false)

  const _ConfettiParticle({
    required this.x,
    required this.speed,
    required this.startDelay,
    required this.color,
    required this.size,
    required this.rotSpeed,
    required this.wobblePhase,
    required this.isRect,
  });
  final double x;           // 0–1 horizontal start fraction
  final double speed;       // rise-speed multiplier
  final double startDelay;  // 0–1 fraction of total duration before appearing
  final Color color;
  final double size;
  final double rotSpeed;    // full rotations over the animation
  final double wobblePhase; // horizontal wobble phase offset (radians)
  final bool isRect;
}

class _ConfettiPainter extends CustomPainter {

  _ConfettiPainter({required this.particles, required this.animation})
      : super(repaint: animation);
  final List<_ConfettiParticle> particles;
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value; // 0.0 → 1.0 over 5 s
    for (final p in particles) {
      if (t < p.startDelay) continue;
      final pt = ((t - p.startDelay) / (1.0 - p.startDelay)).clamp(0.0, 1.0);

      // Fade out in the last 25 % of the animation.
      final alpha = pt > 0.75 ? (1.0 - pt) / 0.25 : 1.0;

      final px = p.x * size.width +
          sin(pt * 4 * pi + p.wobblePhase) * 28 +
          cos(pt * 2.5 * pi + p.wobblePhase * 0.7) * 14;
      // Shoot UP from the bottom
      final py = size.height + 28.0 - pt * p.speed * (size.height + 56);
      final rot = pt * 2 * pi * p.rotSpeed;

      canvas
        ..save()
        ..translate(px, py)
        ..rotate(rot);
      final paint = Paint()..color = p.color.withValues(alpha: alpha);
      if (p.isRect) {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.45),
          paint,
        );
      } else {
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.55),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => true;
}
