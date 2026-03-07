import 'dart:math' show Random, sin, cos, pi;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/game_state.dart';
import '../models/puzzle_image.dart';
import '../models/puzzle_piece.dart';
import '../painters/jigsaw_piece_painter.dart';
import '../widgets/game_button.dart';

const _kEdgePad = 20.0;

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

  // Incrementing this repaint notifier repaints only the piece canvas without
  // triggering a full widget-tree rebuild. This is the key to avoiding 90
  // setState() calls per second during the scatter and drag animations.
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
    if (_uiImage == null) _loadImage();
    if (_uiImage != null && _gameState == null) _initGame();
  }

  Future<void> _loadImage() async {
    final size = MediaQuery.of(context).size;
    // Decode at board width only — no targetHeight so the image aspect ratio is
    // preserved. The painter uses BoxFit.cover to crop to the board area.
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

  /// Tick handler: 0→0.40 shake, 0.40→1.0 fly back to tray.
  void _onReturnTick() {
    final piece = _returningPiece;
    if (piece == null) return;
    final t = _returnController.value;

    if (t <= 0.40) {
      // Shake phase — sinusoidal horizontal wiggle
      final st = t / 0.40;
      final shake = sin(st * pi * 4) * 14.0;
      piece.currentPosition = Offset(_returnFromPos.dx + shake, _returnFromPos.dy);
    } else {
      // Fly-back phase — easeOut curve to tray target
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
    _returnController.forward().then((_) {
      if (mounted) setState(() => _returningPiece = null);
    });
  }

  @override
  void dispose() {
    _scatterController.removeListener(_onScatterTick);
    _scatterController.removeStatusListener(_onScatterStatus);
    _scatterController.dispose();
    _returnController.removeListener(_onReturnTick);
    _returnController.dispose();
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
    final boardW = gs.boardSize.width;
    final boardH = gs.boardSize.height;
    final boardOffX = gs.boardOffset.dx;
    final boardOffY = gs.boardOffset.dy;
    final dividerX = boardOffX + boardW + _kEdgePad; // = screenW/2

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
        // Uses Positioned.fill (full-screen canvas) so piece.targetPosition
        // (which is in screen coords) maps directly to canvas coords.
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
                    final piece = gs.pieces[gs.draggingIndex!];
                    const snapThreshold = 40.0;
                    if ((piece.currentPosition - piece.targetPosition)
                            .distance <=
                        snapThreshold) {
                      gs.endDrag();
                      if (gs.phase == GamePhase.won) {
                        _startConfetti();
                      } else {
                        setState(() {}); // update tray label
                      }
                    } else {
                      HapticFeedback.mediumImpact();
                      gs.endDragNoPlace();
                      _startReturnAnimation(piece);
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
        if (gs.phase == GamePhase.won && _showWinOverlay) _buildWinOverlay(),
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

  // ── Confetti helpers ───────────────────────────────────────────────────────

  void _startConfetti() {
    _confettiParticles = _generateConfetti(120);
    setState(() {}); // show confetti layer
    _confettiController.reset();
    _confettiController.forward().then((_) {
      if (mounted) setState(() => _showWinOverlay = true);
    });
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
      speed: 0.50 + rng.nextDouble() * 0.75,
      startDelay: rng.nextDouble() * 0.30,
      color: colors[rng.nextInt(colors.length)],
      size: 5.0 + rng.nextDouble() * 9.0,
      rotSpeed: 2.0 + rng.nextDouble() * 6.0,
      wobblePhase: rng.nextDouble() * 2 * pi,
      isRect: rng.nextBool(),
    ));
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

// ── Confetti ──────────────────────────────────────────────────────────────────

class _ConfettiParticle {
  final double x;           // 0–1 horizontal start fraction
  final double speed;       // fall-speed multiplier
  final double startDelay;  // 0–1 fraction of total duration before appearing
  final Color color;
  final double size;
  final double rotSpeed;    // full rotations over the animation
  final double wobblePhase; // horizontal wobble phase offset (radians)
  final bool isRect;        // rectangle (true) or oval (false)

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
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final Animation<double> animation;

  _ConfettiPainter({required this.particles, required this.animation})
      : super(repaint: animation);

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
      final py = -28.0 + pt * p.speed * (size.height + 56);
      final rot = pt * 2 * pi * p.rotSpeed;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(rot);
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
