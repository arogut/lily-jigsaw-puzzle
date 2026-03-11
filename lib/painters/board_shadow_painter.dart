import 'package:flutter/material.dart';
import 'package:lily_jigsaw_puzzle/models/puzzle_piece.dart';
import 'package:lily_jigsaw_puzzle/painters/jigsaw_piece_painter.dart';

class BoardShadowPainter extends CustomPainter {
  const BoardShadowPainter({
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
        piece.edges,
        pieceWidth,
        pieceHeight,
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
  bool shouldRepaint(BoardShadowPainter old) {
    if (old.pieces.length != pieces.length) return true;
    for (var i = 0; i < pieces.length; i++) {
      if (old.pieces[i].isPlaced != pieces[i].isPlaced) return true;
    }
    return false;
  }
}
