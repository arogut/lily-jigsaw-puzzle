import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/game_state.dart';
import '../models/puzzle_image.dart';
import '../models/puzzle_piece.dart';
import '../painters/jigsaw_piece_painter.dart';
import '../widgets/game_button.dart';

class GameScreen extends StatefulWidget {
  final PuzzleImageData selectedImage;
  final int gridSize;

  const GameScreen({
    super.key,
    required this.selectedImage,
    required this.gridSize,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  GameState? _gameState;
  ui.Image? _uiImage;

  late AnimationController _scatterController;
  List<Offset>? _assembledPositions;
  List<Offset>? _scatterTargets;

  // Incrementing this repaint notifier repaints only the piece canvas without
  // triggering a full widget-tree rebuild. This is the key to avoiding 90
  // setState() calls per second during the scatter and drag animations.
  final _paintTick = ValueNotifier<int>(0);


  @override
  void initState() {
    super.initState();
    _scatterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_uiImage == null) _loadImage();
    if (_uiImage != null && _gameState == null) _initGame();
  }

  Future<void> _loadImage() async {
    final size = MediaQuery.of(context).size;
    // Decode at board size only — keeps the ui.Image small so each of the
    // 49 piece draws in the single-canvas painter doesn't reference a huge
    // source texture.
    final targetW = (size.width / 2).round().clamp(64, 2048);
    final targetH = size.height.round().clamp(64, 2048);

    final data = await rootBundle.load(widget.selectedImage.assetPath);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: targetW,
      targetHeight: targetH,
    );
    final frame = await codec.getNextFrame();
    if (!mounted) return;
    setState(() => _uiImage = frame.image);
  }

  void _initGame() {
    final size = MediaQuery.of(context).size;
    final boardSize = Size(size.width / 2, size.height);

    _gameState = GameState(
      puzzleImage: _uiImage!,
      gridSize: widget.gridSize,
      boardSize: boardSize,
    );
    _assembledPositions =
        _gameState!.pieces.map((p) => p.targetPosition).toList();

    Future.delayed(const Duration(seconds: 1), _startScatter);
  }

  void _startScatter() {
    if (!mounted || _gameState == null) return;
    final size = MediaQuery.of(context).size;
    _scatterTargets = _gameState!.computeScatterTargets(size);

    // setState only for the phase change (hides/shows shadow layer).
    setState(() => _gameState!.phase = GamePhase.scattering);

    _scatterController.reset();
    _scatterController.addListener(_onScatterTick);
    _scatterController.addStatusListener(_onScatterStatus);
    _scatterController.forward();
  }

  void _onScatterTick() {
    if (_gameState == null ||
        _scatterTargets == null ||
        _assembledPositions == null) {
      return;
    }
    final t = _scatterController.value;
    final n = _gameState!.pieces.length;

    for (int i = 0; i < n; i++) {
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
    // Repaint the canvas without rebuilding the widget tree.
    _paintTick.value++;
  }

  void _onScatterStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _gameState!.beginPlaying();
      setState(() {}); // phase change → shadow layer updates
    }
  }

  // Hit-test which unplaced piece (if any) is under [localPos].
  // Tests in reverse list order so the topmost-drawn piece wins.
  int? _hitTestPiece(Offset localPos) {
    final gs = _gameState;
    if (gs == null) return null;
    final tabW = gs.pieceWidth * JigsawPiecePainter.tabFraction;
    final tabH = gs.pieceHeight * JigsawPiecePainter.tabFraction;

    for (int i = gs.pieces.length - 1; i >= 0; i--) {
      final piece = gs.pieces[i];
      if (piece.isPlaced) continue;
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

  @override
  void dispose() {
    _scatterController.removeListener(_onScatterTick);
    _scatterController.removeStatusListener(_onScatterStatus);
    _scatterController.dispose();
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
    final boardW = gs.boardSize.width;

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
          left: 0, top: 0, width: boardW, bottom: 0,
          child: CustomPaint(painter: _BoardGridPainter(gs.gridSize)),
        ),

        // ── Shadow hints ────────────────────────────────────────────────────
        if (gs.phase == GamePhase.scattering || gs.phase == GamePhase.playing)
          Positioned(
            left: 0, top: 0, width: boardW, bottom: 0,
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
          left: boardW - 3, top: 0, bottom: 0, width: 6,
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
        //
        // Previously: 49 PuzzlePieceWidget instances each with their own
        // CustomPaint → Flutter promoted each to a separate compositor layer
        // → 49 texture allocations in SwiftShader → QEMU ran out of memory.
        //
        // Now: one CustomPaint draws all pieces in a single pass. The
        // ValueNotifier repaint signal updates only the canvas without
        // rebuilding the widget tree, which also eliminates 90 setState()
        // calls per second during scatter.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanStart: gs.phase == GamePhase.playing
                ? (d) {
                    final idx = _hitTestPiece(d.localPosition);
                    if (idx != null) {
                      HapticFeedback.lightImpact();
                      gs.startDrag(idx);
                      _paintTick.value++;
                    }
                  }
                : null,
            onPanUpdate: gs.phase == GamePhase.playing
                ? (d) {
                    if (gs.draggingIndex == null) return;
                    gs.updateDrag(d.delta);
                    _paintTick.value++;
                  }
                : null,
            onPanEnd: gs.phase == GamePhase.playing
                ? (_) {
                    if (gs.draggingIndex == null) return;
                    gs.endDrag();
                    setState(() {}); // update tray label and win phase
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
          right: 8, top: 8,
          child: _TrayLabel(
            placed: gs.pieces.where((p) => p.isPlaced).length,
            total: gs.pieces.length,
          ),
        ),

        // ── Back button ─────────────────────────────────────────────────────
        Positioned(
          left: 8, top: 8,
          child: GameButton(
            label: 'Back',
            icon: Icons.arrow_back_rounded,
            color: const Color(0xFF9B59B6),
            width: 120,
            height: 44,
            fontSize: 15,
            onPressed: () =>
                Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ),

        // ── Win overlay ─────────────────────────────────────────────────────
        if (gs.phase == GamePhase.won) _buildWinOverlay(),
      ],
    );
  }

  Widget _buildWinOverlay() {
    return GestureDetector(
      // Absorb touches so the game canvas doesn't receive them while won.
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
                      'You Did It!',
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
                      child: const Text(
                        'You Did It!',
                        style: TextStyle(
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
                  'Puzzle complete!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6A1B9A).withValues(alpha: 0.70),
                  ),
                ),
                const SizedBox(height: 28),
                GameButton(
                  label: 'Play Again',
                  icon: Icons.replay_rounded,
                  color: const Color(0xFF6BCB77),
                  shadowColor: const Color(0xFF3A9E48),
                  width: 220,
                  height: 56,
                  fontSize: 20,
                  onPressed: _restartGame,
                ),
                const SizedBox(height: 12),
                GameButton(
                  label: 'New Puzzle',
                  icon: Icons.home_rounded,
                  color: const Color(0xFF4D96FF),
                  shadowColor: const Color(0xFF2460CC),
                  width: 220,
                  height: 56,
                  fontSize: 20,
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
    _scatterController.removeListener(_onScatterTick);
    _scatterController.removeStatusListener(_onScatterStatus);
    setState(() {
      _gameState = null;
      _assembledPositions = null;
      _scatterTargets = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initGame();
    });
  }
}

// ── Single-canvas painter for ALL puzzle pieces ────────────────────────────────
//
// Drawing all N pieces in one CustomPaint pass means Flutter sees ONE layer
// instead of N layers. With software rendering (SwiftShader), N separate layers
// meant N × screen-sized texture allocations in CPU RAM, which crashed QEMU.

class _AllPiecesPainter extends CustomPainter {
  final List<PuzzlePiece> pieces;
  final ui.Image image;
  final double pieceWidth;
  final double pieceHeight;

  _AllPiecesPainter({
    required this.pieces,
    required this.image,
    required this.pieceWidth,
    required this.pieceHeight,
    required ValueNotifier<int> repaintNotifier,
  }) : super(repaint: repaintNotifier);

  @override
  void paint(Canvas canvas, Size size) {
    final tabW = pieceWidth * JigsawPiecePainter.tabFraction;
    final tabH = pieceHeight * JigsawPiecePainter.tabFraction;
    final pieceCanvasSize = Size(pieceWidth + 2 * tabW, pieceHeight + 2 * tabH);

    for (final piece in pieces) {
      canvas.save();
      canvas.translate(
        piece.currentPosition.dx - tabW,
        piece.currentPosition.dy - tabH,
      );
      // Reuse JigsawPiecePainter's paint() logic in the translated canvas.
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
  final int gridSize;
  const _BoardGridPainter(this.gridSize);

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

    for (int r = 0; r <= gridSize; r++) {
      final y = r * cellH;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    for (int c = 0; c <= gridSize; c++) {
      final x = c * cellW;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (int r = 0; r <= gridSize; r++) {
      for (int c = 0; c <= gridSize; c++) {
        canvas.drawCircle(Offset(c * cellW, r * cellH), 2.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_BoardGridPainter old) => old.gridSize != gridSize;
}

// ── Board shadow hints painter ────────────────────────────────────────────────

class _BoardShadowPainter extends CustomPainter {
  final List<PuzzlePiece> pieces;
  final double pieceWidth;
  final double pieceHeight;

  const _BoardShadowPainter({
    required this.pieces,
    required this.pieceWidth,
    required this.pieceHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final tabW = pieceWidth * JigsawPiecePainter.tabFraction;
    final tabH = pieceHeight * JigsawPiecePainter.tabFraction;

    for (final piece in pieces) {
      if (piece.isPlaced) continue;
      canvas.save();
      canvas.translate(
        piece.targetPosition.dx - tabW,
        piece.targetPosition.dy - tabH,
      );
      final path = JigsawPiecePainter.buildPiecePath(
        piece.edges, pieceWidth, pieceHeight,
      );
      canvas.drawPath(path, Paint()..color = const Color(0x40000000));
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BoardShadowPainter old) {
    if (old.pieces.length != pieces.length) return true;
    for (int i = 0; i < pieces.length; i++) {
      if (old.pieces[i].isPlaced != pieces[i].isPlaced) return true;
    }
    return false;
  }
}

// ── Tray piece counter label ──────────────────────────────────────────────────

class _TrayLabel extends StatelessWidget {
  final int placed;
  final int total;
  const _TrayLabel({required this.placed, required this.total});

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
