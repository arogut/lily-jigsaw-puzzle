import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/puzzle_piece.dart';

class JigsawPiecePainter extends CustomPainter {
  // Tab margin as a fraction of piece dimension (also used outside for canvas sizing)
  static const double tabFraction = 0.28;

  final PuzzlePiece piece;
  final ui.Image image;
  final double pieceWidth;
  final double pieceHeight;

  JigsawPiecePainter({
    required this.piece,
    required this.image,
    required this.pieceWidth,
    required this.pieceHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = buildPiecePath(piece.edges, pieceWidth, pieceHeight);
    final bounds = Rect.fromLTWH(0, 0, size.width, size.height);

    // 1. Drop shadow — layered offset fill, no blur (blur is too expensive for
    //    software rendering and kills performance on the emulator with 49 pieces).
    canvas.save();
    canvas.translate(4, 7);
    canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: 0.18));
    canvas.restore();
    canvas.save();
    canvas.translate(2, 4);
    canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: 0.22));
    canvas.restore();

    // 2. Image fill, clipped to piece shape
    canvas.save();
    canvas.clipPath(path);

    final imgW = image.width.toDouble();
    final imgH = image.height.toDouble();
    final cellW = imgW / piece.gridSize;
    final cellH = imgH / piece.gridSize;
    final srcTabW = cellW * tabFraction;
    final srcTabH = cellH * tabFraction;

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(
        piece.col * cellW - srcTabW,
        piece.row * cellH - srcTabH,
        cellW + 2 * srcTabW,
        cellH + 2 * srcTabH,
      ),
      bounds,
      Paint(),
    );

    // 3. Lighting gradient overlay — simulates light from top-left
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x38FFFFFF),
            Color(0x00000000),
            Color(0x30000000),
          ],
          stops: [0.0, 0.45, 1.0],
        ).createShader(bounds),
    );

    canvas.restore();

    // 4. White border — childish, visible against any background
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  /// Builds the full jigsaw piece path. Origin is (0,0); the piece body starts
  /// at (tabW, tabH). This is static so shadow painters can reuse it.
  static Path buildPiecePath(
    PieceEdges edges,
    double pieceWidth,
    double pieceHeight,
  ) {
    final tabW = pieceWidth * tabFraction;
    final tabH = pieceHeight * tabFraction;
    final path = Path();

    final left = tabW;
    final top = tabH;
    final right = tabW + pieceWidth;
    final bottom = tabH + pieceHeight;

    path.moveTo(left, top);

    // Top edge (left → right): tab protrudes upward
    _drawEdge(
      path,
      from: Offset(left, top),
      to: Offset(right, top),
      edgeType: edges.top,
      tab: tabH,
      isHorizontal: true,
      tabSign: -1,
    );

    // Right edge (top → bottom): tab protrudes rightward
    _drawEdge(
      path,
      from: Offset(right, top),
      to: Offset(right, bottom),
      edgeType: edges.right,
      tab: tabW,
      isHorizontal: false,
      tabSign: 1,
    );

    // Bottom edge (right → left): tab protrudes downward
    _drawEdge(
      path,
      from: Offset(right, bottom),
      to: Offset(left, bottom),
      edgeType: edges.bottom,
      tab: tabH,
      isHorizontal: true,
      tabSign: 1,
    );

    // Left edge (bottom → top): tab protrudes leftward
    _drawEdge(
      path,
      from: Offset(left, bottom),
      to: Offset(left, top),
      edgeType: edges.left,
      tab: tabW,
      isHorizontal: false,
      tabSign: -1,
    );

    path.close();
    return path;
  }

  /// Draws one edge from [from] to [to] with a jigsaw tab or blank.
  ///
  /// Improved knob shape:
  ///   flat ── shoulder ── narrow neck (22% tab) ── circular dome (2 beziers) ── narrow neck ── shoulder ── flat
  static void _drawEdge(
    Path path, {
    required Offset from,
    required Offset to,
    required EdgeType edgeType,
    required double tab,
    required bool isHorizontal,
    required int tabSign,
  }) {
    if (edgeType == EdgeType.flat) {
      path.lineTo(to.dx, to.dy);
      return;
    }

    // Tab protrudes outward; blank protrudes inward (flipped sign).
    final sign = edgeType == EdgeType.tab ? tabSign : -tabSign;

    Offset pt(double along, double perp) {
      if (isHorizontal) {
        return Offset(
          from.dx + along * (to.dx - from.dx),
          from.dy + perp * sign,
        );
      } else {
        return Offset(
          from.dx + perp * sign,
          from.dy + along * (to.dy - from.dy),
        );
      }
    }

    final t = tab;

    // Flat to shoulder start
    path.lineTo(pt(0.17, 0).dx, pt(0.17, 0).dy);

    // Shoulder rise to narrow neck
    path.cubicTo(
      pt(0.20, 0.00 * t).dx, pt(0.20, 0.00 * t).dy,
      pt(0.25, 0.22 * t).dx, pt(0.25, 0.22 * t).dy,
      pt(0.29, 0.22 * t).dx, pt(0.29, 0.22 * t).dy,
    );

    // Left dome arc (neck → apex) — creates near-circular shape
    path.cubicTo(
      pt(0.33, 0.22 * t).dx, pt(0.33, 0.22 * t).dy,
      pt(0.36, 1.00 * t).dx, pt(0.36, 1.00 * t).dy,
      pt(0.50, 1.00 * t).dx, pt(0.50, 1.00 * t).dy,
    );

    // Right dome arc (apex → neck)
    path.cubicTo(
      pt(0.64, 1.00 * t).dx, pt(0.64, 1.00 * t).dy,
      pt(0.67, 0.22 * t).dx, pt(0.67, 0.22 * t).dy,
      pt(0.71, 0.22 * t).dx, pt(0.71, 0.22 * t).dy,
    );

    // Shoulder fall back to edge
    path.cubicTo(
      pt(0.75, 0.22 * t).dx, pt(0.75, 0.22 * t).dy,
      pt(0.80, 0.00 * t).dx, pt(0.80, 0.00 * t).dy,
      pt(0.83, 0.00 * t).dx, pt(0.83, 0.00 * t).dy,
    );

    // Flat to edge end
    path.lineTo(to.dx, to.dy);
  }

  @override
  bool shouldRepaint(JigsawPiecePainter oldDelegate) {
    return oldDelegate.piece != piece ||
        oldDelegate.pieceWidth != pieceWidth ||
        oldDelegate.pieceHeight != pieceHeight;
  }
}
