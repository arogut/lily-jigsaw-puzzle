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
    final glowAlpha = (80 + pulse * 120).toInt();
    final path = JigsawPiecePainter.buildPiecePath(
      hintedPiece.edges, pieceWidth, pieceHeight,
    );

    // Golden glow at the piece's current position
    canvas
      ..save()
      ..translate(
        hintedPiece.currentPosition.dx - tabW,
        hintedPiece.currentPosition.dy - tabH,
      )
      ..drawPath(
        path,
        Paint()
          ..color = Color.fromARGB(glowAlpha, 255, 200, 0)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + pulse * 3),
      )
      ..drawPath(
        path,
        Paint()
          ..color = const Color.fromARGB(220, 255, 200, 0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5,
      )
      ..restore();

    // Green glow at the target position (board slot)
    canvas
      ..save()
      ..translate(
        hintedPiece.targetPosition.dx - tabW,
        hintedPiece.targetPosition.dy - tabH,
      )
      ..drawPath(
        path,
        Paint()
          ..color = Color.fromARGB(glowAlpha, 0, 220, 80)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + pulse * 3),
      )
      ..drawPath(
        path,
        Paint()
          ..color = const Color.fromARGB(220, 0, 220, 80)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(HintGlowPainter oldDelegate) =>
      oldDelegate.pieces != pieces ||
      oldDelegate.pieceWidth != pieceWidth ||
      oldDelegate.pieceHeight != pieceHeight;
}
