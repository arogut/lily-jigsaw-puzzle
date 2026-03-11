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
  bool shouldRepaint(AllPiecesPainter old) => true;
}
