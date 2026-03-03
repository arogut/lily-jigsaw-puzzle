import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/game_state.dart';
import '../models/puzzle_image.dart';
import '../painters/jigsaw_piece_painter.dart';
import '../widgets/puzzle_piece_widget.dart';

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

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  GameState? _gameState;
  ui.Image? _uiImage;

  late AnimationController _scatterController;
  List<Offset>? _assembledPositions;
  List<Offset>? _scatterTargets;

  @override
  void initState() {
    super.initState();
    _scatterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _loadImage();
  }

  Future<void> _loadImage() async {
    final data = await rootBundle.load(widget.selectedImage.assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    if (!mounted) return;
    setState(() {
      _uiImage = frame.image;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_uiImage != null && _gameState == null) {
      _initGame();
    }
  }

  void _initGame() {
    final size = MediaQuery.of(context).size;
    final boardSize = Size(size.width, size.height);

    _gameState = GameState(
      puzzleImage: _uiImage!,
      gridSize: widget.gridSize,
      boardSize: boardSize,
    );

    // Store assembled positions
    _assembledPositions = _gameState!.pieces.map((p) => p.targetPosition).toList();

    // Start assembled phase: show image intact for 1 second, then scatter
    Future.delayed(const Duration(seconds: 1), _startScatter);
  }

  void _startScatter() {
    if (!mounted || _gameState == null) return;
    final size = MediaQuery.of(context).size;
    _scatterTargets = _gameState!.computeScatterTargets(size);
    _gameState!.phase = GamePhase.scattering;

    _scatterController.reset();
    _scatterController.addListener(_onScatterTick);
    _scatterController.addStatusListener(_onScatterStatus);
    _scatterController.forward();
  }

  void _onScatterTick() {
    if (_gameState == null || _scatterTargets == null || _assembledPositions == null) return;
    final t = _scatterController.value;
    final n = _gameState!.pieces.length;

    for (int i = 0; i < n; i++) {
      final slotWidth = 1.0 / n;
      final startI = i * slotWidth;
      final endI = (startI + slotWidth * 1.5).clamp(0.0, 1.0);
      final localT = endI == startI
          ? 1.0
          : ((t - startI) / (endI - startI)).clamp(0.0, 1.0);
      final curved = Curves.easeInOut.transform(localT);
      final pos = Offset.lerp(_assembledPositions![i], _scatterTargets![i], curved)!;
      _gameState!.setPiecePosition(i, pos);
    }
    setState(() {});
  }

  void _onScatterStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _gameState!.beginPlaying();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _scatterController.removeListener(_onScatterTick);
    _scatterController.removeStatusListener(_onScatterStatus);
    _scatterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _uiImage == null
          ? const Center(child: CircularProgressIndicator())
          : _buildGame(),
    );
  }

  Widget _buildGame() {
    // Trigger game init on first build after image loads
    if (_gameState == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _gameState == null) _initGame();
      });
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        _buildPuzzleStack(),
        if (_gameState!.phase == GamePhase.won) _buildWinOverlay(),
      ],
    );
  }

  Widget _buildPuzzleStack() {
    final gs = _gameState!;
    final tabW = gs.pieceWidth * JigsawPiecePainter.tabFraction;
    final tabH = gs.pieceHeight * JigsawPiecePainter.tabFraction;

    return Stack(
      children: [
        for (int i = 0; i < gs.pieces.length; i++)
          Builder(builder: (context) {
            final piece = gs.pieces[i];
            return Positioned(
              left: piece.currentPosition.dx - tabW,
              top: piece.currentPosition.dy - tabH,
              child: PuzzlePieceWidget(
                key: ValueKey('${piece.row}_${piece.col}'),
                piece: piece,
                image: _uiImage!,
                pieceWidth: gs.pieceWidth,
                pieceHeight: gs.pieceHeight,
                onDragStart: () {
                  gs.startDrag(i);
                  setState(() {});
                },
                onDragUpdate: (delta) {
                  gs.updateDrag(delta);
                  setState(() {});
                },
                onDragEnd: () {
                  gs.endDrag();
                  setState(() {});
                },
              ),
            );
          }),
      ],
    );
  }

  Widget _buildWinOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 12),
                const Text(
                  'Puzzle Complete!',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _restartGame,
                  child: const Text('Play Again'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('Choose Another Puzzle'),
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
