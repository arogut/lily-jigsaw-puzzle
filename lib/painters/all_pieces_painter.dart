import 'dart:math' show cos, pi;
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
    this.logoImage,
  }) : super(repaint: repaintNotifier);

  final List<PuzzlePiece> pieces;
  final ui.Image image;
  final double pieceWidth;
  final double pieceHeight;
  final bool hasActiveHint;

  /// Optional app logo drawn grayed-out on the back face of pieces.
  final ui.Image? logoImage;

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

      // Combined scale: lift effect (piece.scale) × horizontal flip squeeze.
      // The flip squeeze maps flipProgress ∈ [0,1] to |cos(π·t)| ∈ [1,0,1],
      // which creates the horizontal-squeeze illusion of a flip without rotation.
      final flipScaleX = piece.flipProgress < 1.0
          ? cos(piece.flipProgress * pi).abs()
          : 1.0;
      final sx = piece.scale * flipScaleX;
      final sy = piece.scale;

      // Apply transforms centred on the piece body centre so the piece scales
      // in place rather than from the top-left corner.
      //   1. Translate to piece body centre.
      //   2. Scale (lift + flip).
      //   3. Translate so the painter's top-left lands at the correct position.
      final cx = piece.currentPosition.dx + pieceWidth / 2;
      final cy = piece.currentPosition.dy + pieceHeight / 2;
      canvas
        ..translate(cx, cy)
        ..scale(sx, sy)
        ..translate(-(tabW + pieceWidth / 2), -(tabH + pieceHeight / 2));

      JigsawPiecePainter(
        piece: piece,
        image: image,
        pieceWidth: pieceWidth,
        pieceHeight: pieceHeight,
        logoImage: logoImage,
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
