import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:lily_jigsaw_puzzle/models/puzzle_piece.dart';
import 'package:lily_jigsaw_puzzle/painters/jigsaw_piece_painter.dart';

class AllPiecesPainter extends CustomPainter {
  AllPiecesPainter({
    required this.pieces,
    required this.image,
    required this.pieceWidth,
    required this.pieceHeight,
    required ValueNotifier<int> repaintNotifier,
    this.hasActiveHint = false,
  }) : super(repaint: repaintNotifier);

  final List<PuzzlePiece> pieces;
  final ui.Image image;
  final double pieceWidth;
  final double pieceHeight;
  final bool hasActiveHint;

  @override
  void paint(Canvas canvas, Size size) {
    final tabW = pieceWidth * JigsawPiecePainter.tabFraction;
    final tabH = pieceHeight * JigsawPiecePainter.tabFraction;
    final pieceCanvasSize = Size(pieceWidth + 2 * tabW, pieceHeight + 2 * tabH);

    void drawPiece(PuzzlePiece piece) {
      final dimmed = hasActiveHint && !piece.isHinted && !piece.isPlaced;
      if (dimmed) {
        canvas.saveLayer(null, Paint()..color = const Color(0xCC000000));
      } else {
        canvas.save();
      }

      // Apply lift scale centred on the piece body so it scales in place.
      final cx = piece.currentPosition.dx + pieceWidth / 2;
      final cy = piece.currentPosition.dy + pieceHeight / 2;
      canvas
        ..translate(cx, cy)
        ..scale(piece.scale, piece.scale)
        ..translate(-(tabW + pieceWidth / 2), -(tabH + pieceHeight / 2));

      JigsawPiecePainter(
        piece: piece,
        image: image,
        pieceWidth: pieceWidth,
        pieceHeight: pieceHeight,
      ).paint(canvas, pieceCanvasSize);
      canvas.restore();
    }

    PuzzlePiece? hintedPiece;
    for (final piece in pieces) {
      if (piece.isHinted && !piece.isPlaced) {
        hintedPiece = piece;
      } else {
        drawPiece(piece);
      }
    }
    if (hintedPiece != null) drawPiece(hintedPiece);
  }

  @override
  bool shouldRepaint(AllPiecesPainter old) => true;
}
