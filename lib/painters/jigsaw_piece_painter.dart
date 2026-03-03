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
    final tabW = pieceWidth * tabFraction;
    final tabH = pieceHeight * tabFraction;

    final path = _buildPath(tabW, tabH);

    canvas.save();
    canvas.clipPath(path);

    // Map the full canvas (including tab margins) to the corresponding
    // region of the source image, so tab bumps show correct image content.
    final imgW = image.width.toDouble();
    final imgH = image.height.toDouble();
    final cellW = imgW / piece.gridSize;
    final cellH = imgH / piece.gridSize;

    // Image-space equivalent of the tab padding
    final srcTabW = cellW * tabFraction;
    final srcTabH = cellH * tabFraction;

    final srcRect = Rect.fromLTWH(
      piece.col * cellW - srcTabW,
      piece.row * cellH - srcTabH,
      cellW + 2 * srcTabW,
      cellH + 2 * srcTabH,
    );

    // Destination is the entire canvas (including tab margin areas)
    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawImageRect(image, srcRect, dstRect, Paint());
    canvas.restore();

    // Subtle border
    final borderPaint = Paint()
      ..color = Colors.black38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(path, borderPaint);
  }

  Path _buildPath(double tabW, double tabH) {
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
      edgeType: piece.edges.top,
      tab: tabH,
      isHorizontal: true,
      tabSign: -1,
    );

    // Right edge (top → bottom): tab protrudes rightward
    _drawEdge(
      path,
      from: Offset(right, top),
      to: Offset(right, bottom),
      edgeType: piece.edges.right,
      tab: tabW,
      isHorizontal: false,
      tabSign: 1,
    );

    // Bottom edge (right → left): tab protrudes downward
    _drawEdge(
      path,
      from: Offset(right, bottom),
      to: Offset(left, bottom),
      edgeType: piece.edges.bottom,
      tab: tabH,
      isHorizontal: true,
      tabSign: 1,
    );

    // Left edge (bottom → top): tab protrudes leftward
    _drawEdge(
      path,
      from: Offset(left, bottom),
      to: Offset(left, top),
      edgeType: piece.edges.left,
      tab: tabW,
      isHorizontal: false,
      tabSign: -1,
    );

    path.close();
    return path;
  }

  /// Draws one edge from [from] to [to] with a jigsaw tab or blank.
  ///
  /// [tab] — max protrusion distance (= tabW or tabH, the canvas margin).
  /// [isHorizontal] — true for top/bottom edges, false for left/right.
  /// [tabSign] — perpendicular direction of a TAB protrusion:
  ///   horizontal: -1 = up, +1 = down
  ///   vertical:   +1 = right, -1 = left
  void _drawEdge(
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

    // pt(along, perp): point at fraction [along] along the edge,
    // offset [perp] in the perpendicular direction (scaled by sign).
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

    // Classic jigsaw knob shape:
    //   flat  ─── shoulder rise ─── neck ──── round head ──── neck ─── shoulder fall ─── flat
    //   0%         20%              30%    32%          68%  70%             80%          100%

    // 1. Flat section to shoulder start
    path.lineTo(pt(0.20, 0).dx, pt(0.20, 0).dy);

    // 2. Shoulder / neck rise: gentle curve up to neck level (0.3t)
    path.cubicTo(
      pt(0.22, 0.00 * t).dx, pt(0.22, 0.00 * t).dy,
      pt(0.28, 0.30 * t).dx, pt(0.28, 0.30 * t).dy,
      pt(0.32, 0.30 * t).dx, pt(0.32, 0.30 * t).dy,
    );

    // 3. Round head dome: sweeps up to full tab height and back down
    path.cubicTo(
      pt(0.36, 1.00 * t).dx, pt(0.36, 1.00 * t).dy,
      pt(0.64, 1.00 * t).dx, pt(0.64, 1.00 * t).dy,
      pt(0.68, 0.30 * t).dx, pt(0.68, 0.30 * t).dy,
    );

    // 4. Shoulder / neck fall: back to edge level
    path.cubicTo(
      pt(0.72, 0.30 * t).dx, pt(0.72, 0.30 * t).dy,
      pt(0.78, 0.00 * t).dx, pt(0.78, 0.00 * t).dy,
      pt(0.80, 0.00 * t).dx, pt(0.80, 0.00 * t).dy,
    );

    // 5. Flat section to edge end
    path.lineTo(to.dx, to.dy);
  }

  @override
  bool shouldRepaint(JigsawPiecePainter oldDelegate) {
    return oldDelegate.piece != piece ||
        oldDelegate.pieceWidth != pieceWidth ||
        oldDelegate.pieceHeight != pieceHeight;
  }
}
