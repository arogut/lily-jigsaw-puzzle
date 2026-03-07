import 'dart:math' show max;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/puzzle_piece.dart';

class JigsawPiecePainter extends CustomPainter {
  // Tab margin as a fraction of piece dimension (also used outside for canvas sizing)
  static const double tabFraction = 0.35;

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

    // 2. Image fill, clipped to piece shape — BoxFit.cover: scale the image so
    //    it fully covers the board without distortion, then crop to board area.
    canvas.save();
    canvas.clipPath(path);

    final imgW = image.width.toDouble();
    final imgH = image.height.toDouble();
    final boardW = pieceWidth * piece.gridSize;
    final boardH = pieceHeight * piece.gridSize;

    // Scale to cover: use the larger of the two scale factors so the image
    // fills the board on both axes.
    final scale = max(boardW / imgW, boardH / imgH);

    // The visible sub-rect of the image that maps to the board (centered crop).
    final visW = boardW / scale;
    final visH = boardH / scale;
    final srcOriginX = (imgW - visW) / 2.0;
    final srcOriginY = (imgH - visH) / 2.0;

    // Per-cell source dimensions and tab extension in image coordinates.
    final cellW = visW / piece.gridSize;
    final cellH = visH / piece.gridSize;
    final srcTabW = cellW * tabFraction;
    final srcTabH = cellH * tabFraction;

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(
        srcOriginX + piece.col * cellW - srcTabW,
        srcOriginY + piece.row * cellH - srcTabH,
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

  /// Draws one edge from [from] to [to] with a classic jigsaw tab or blank.
  ///
  /// Shape:  flat ── shoulder ── narrow neck ── round knob dome ── narrow neck ── shoulder ── flat
  ///
  /// The knob is formed by two cubic beziers that flare outward from the narrow
  /// neck, creating a visually circular bump (classic kids-puzzle style).
  ///   • Left arc:  neck-base → apex  (flares out left, then sweeps to apex)
  ///   • Right arc: apex → neck-base  (mirror of left)
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

    // 1. Flat to shoulder
    path.lineTo(pt(0.32, 0).dx, pt(0.32, 0).dy);

    // 2. Shoulder → narrow neck base (smooth entry)
    path.cubicTo(
      pt(0.37, 0.00 * t).dx, pt(0.37, 0.00 * t).dy,
      pt(0.40, 0.08 * t).dx, pt(0.40, 0.08 * t).dy,
      pt(0.40, 0.20 * t).dx, pt(0.40, 0.20 * t).dy,
    );

    // 3. Left dome arc: neck base → apex
    // Flares outward (beyond the neck) to create a round knob.
    path.cubicTo(
      pt(0.30, 0.42 * t).dx, pt(0.30, 0.42 * t).dy,
      pt(0.34, 0.94 * t).dx, pt(0.34, 0.94 * t).dy,
      pt(0.50, 1.00 * t).dx, pt(0.50, 1.00 * t).dy,
    );

    // 4. Right dome arc: apex → neck base (mirror of left)
    path.cubicTo(
      pt(0.66, 0.94 * t).dx, pt(0.66, 0.94 * t).dy,
      pt(0.70, 0.42 * t).dx, pt(0.70, 0.42 * t).dy,
      pt(0.60, 0.20 * t).dx, pt(0.60, 0.20 * t).dy,
    );

    // 5. Neck base → shoulder (smooth exit)
    path.cubicTo(
      pt(0.60, 0.08 * t).dx, pt(0.60, 0.08 * t).dy,
      pt(0.63, 0.00 * t).dx, pt(0.63, 0.00 * t).dy,
      pt(0.68, 0.00 * t).dx, pt(0.68, 0.00 * t).dy,
    );

    // 6. Flat to edge end
    path.lineTo(to.dx, to.dy);
  }

  @override
  bool shouldRepaint(JigsawPiecePainter oldDelegate) {
    return oldDelegate.piece != piece ||
        oldDelegate.pieceWidth != pieceWidth ||
        oldDelegate.pieceHeight != pieceHeight;
  }
}
