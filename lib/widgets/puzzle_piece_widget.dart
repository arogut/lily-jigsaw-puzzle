import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/puzzle_piece.dart';
import '../painters/jigsaw_piece_painter.dart';

class PuzzlePieceWidget extends StatefulWidget {
  final PuzzlePiece piece;
  final ui.Image image;
  final double pieceWidth;
  final double pieceHeight;
  final VoidCallback onDragStart;
  final void Function(Offset delta) onDragUpdate;
  final VoidCallback onDragEnd;

  const PuzzlePieceWidget({
    super.key,
    required this.piece,
    required this.image,
    required this.pieceWidth,
    required this.pieceHeight,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  @override
  State<PuzzlePieceWidget> createState() => _PuzzlePieceWidgetState();
}

class _PuzzlePieceWidgetState extends State<PuzzlePieceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _snapController;
  late Animation<double> _scaleAnim;
  bool _wasPlaced = false;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _snapController, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(PuzzlePieceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_wasPlaced && widget.piece.isPlaced) {
      _snapController.forward(from: 0);
    }
    _wasPlaced = widget.piece.isPlaced;
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabW = widget.pieceWidth * JigsawPiecePainter.tabFraction;
    final tabH = widget.pieceHeight * JigsawPiecePainter.tabFraction;
    final canvasW = widget.pieceWidth + 2 * tabW;
    final canvasH = widget.pieceHeight + 2 * tabH;

    return GestureDetector(
      onPanStart: widget.piece.isPlaced ? null : (_) => widget.onDragStart(),
      onPanUpdate: widget.piece.isPlaced ? null : (d) => widget.onDragUpdate(d.delta),
      onPanEnd: widget.piece.isPlaced ? null : (_) => widget.onDragEnd(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: CustomPaint(
          size: Size(canvasW, canvasH),
          painter: JigsawPiecePainter(
            piece: widget.piece,
            image: widget.image,
            pieceWidth: widget.pieceWidth,
            pieceHeight: widget.pieceHeight,
          ),
        ),
      ),
    );
  }
}
