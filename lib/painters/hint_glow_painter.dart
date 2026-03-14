import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';

import 'package:lily_jigsaw_puzzle/models/puzzle_piece.dart';
import 'package:lily_jigsaw_puzzle/painters/jigsaw_piece_painter.dart';

class HintGlowPainter extends CustomPainter {

  HintGlowPainter({
    required this.pieces,
    required this.pieceWidth,
    required this.pieceHeight,
    required this.animation,
  }) : super(repaint: animation);
  final List<PuzzlePiece> pieces;
  final double pieceWidth;
  final double pieceHeight;
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final hintedPiece = pieces.where((p) => p.isHinted).firstOrNull;
    if (hintedPiece == null) return;

    final pulse = sin(animation.value * 2 * pi) * 0.5 + 0.5;
    final tabW = pieceWidth * JigsawPiecePainter.tabFraction;
    final tabH = pieceHeight * JigsawPiecePainter.tabFraction;

    // Golden glow at the piece's current position
    final pieceCx = hintedPiece.currentPosition.dx + pieceWidth / 2;
    final pieceCy = hintedPiece.currentPosition.dy + pieceHeight / 2;
    final glowAlpha = (80 + pulse * 120).toInt();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(pieceCx, pieceCy),
          width: pieceWidth + tabW * 2 + 12,
          height: pieceHeight + tabH * 2 + 12,
        ),
        const Radius.circular(12),
      ),
      Paint()
        ..color = Color.fromARGB(glowAlpha, 255, 200, 0)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 18 + pulse * 10),
    );

    // Green glow at the target position (board slot)
    final targetCx = hintedPiece.targetPosition.dx + pieceWidth / 2;
    final targetCy = hintedPiece.targetPosition.dy + pieceHeight / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(targetCx, targetCy),
          width: pieceWidth + 12,
          height: pieceHeight + 12,
        ),
        const Radius.circular(12),
      ),
      Paint()
        ..color = Color.fromARGB(glowAlpha, 0, 220, 80)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 18 + pulse * 10),
    );
  }

  @override
  bool shouldRepaint(HintGlowPainter oldDelegate) =>
      oldDelegate.pieces != pieces ||
      oldDelegate.pieceWidth != pieceWidth ||
      oldDelegate.pieceHeight != pieceHeight;
}
