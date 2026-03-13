import 'dart:math' show max;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:lily_jigsaw_puzzle/models/puzzle_piece.dart';

class JigsawPiecePainter extends CustomPainter {

  JigsawPiecePainter({
    required this.piece,
    required this.image,
    required this.pieceWidth,
    required this.pieceHeight,
  });
  // Tab margin as a fraction of piece dimension (also used outside for canvas sizing)
  static const double tabFraction = 0.35;

  final PuzzlePiece piece;
  final ui.Image image;
  final double pieceWidth;
  final double pieceHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final path = buildPiecePath(piece.edges, pieceWidth, pieceHeight);
    final bounds = Rect.fromLTWH(0, 0, size.width, size.height);

    // Pre-compute image variables so they can be used inside the single canvas cascade.
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

    // Single canvas cascade: 1. shadows, 2. image fill (clipped), 3. lighting, 4. bevel.
    // For placed pieces, only draw shadow on outer/flat edges.
    // For unplaced pieces, draw full shadow for floating effect.
    if (!piece.isPlaced) {
      canvas
        // 1. Drop shadow — three layered offset fills (no blur for software render
        //    performance). Three layers give a softer, deeper shadow.
        ..save()
        ..translate(6, 10)
        ..drawPath(path, Paint()..color = Colors.black.withValues(alpha: 0.11))
        ..restore()
        ..save()
        ..translate(4, 7)
        ..drawPath(path, Paint()..color = Colors.black.withValues(alpha: 0.18))
        ..restore()
        ..save()
        ..translate(2, 4)
        ..drawPath(path, Paint()..color = Colors.black.withValues(alpha: 0.22))
        ..restore();
    } else {
      // For placed pieces, draw shadow only on outer (flat) edges
      final outerPath = buildOuterEdgePath(piece.edges, pieceWidth, pieceHeight);
      if (outerPath != null) {
        final shadowPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0
          ..strokeCap = StrokeCap.square;

        canvas
          ..save()
          ..translate(3, 5)
          ..drawPath(outerPath, shadowPaint..color = Colors.black.withValues(alpha: 0.15))
          ..restore()
          ..save()
          ..translate(2, 3)
          ..drawPath(outerPath, shadowPaint..color = Colors.black.withValues(alpha: 0.20))
          ..restore();
      }
    }

    // 2. Image fill, clipped to piece shape — BoxFit.cover: scale the image so
    //    it fully covers the board without distortion, then crop to board area.
    canvas
      ..save()
      ..clipPath(path)
      ..drawImageRect(
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

    // 3. Lighting gradient overlay — only for unplaced pieces.
    //    Simulates diffuse light from top-left.
    if (!piece.isPlaced) {
      canvas.drawRect(
        bounds,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0x55FFFFFF), // bright highlight (top-left)
              Color(0x00000000), // transparent mid
              Color(0x44000000), // dark shadow (bottom-right)
            ],
            stops: [0.0, 0.40, 1.0],
          ).createShader(bounds),
      );
    }

    canvas.restore();

    // 4. Bevel edge — gradient stroke for 3-D look on ALL edges.
    //    Same appearance for placed and unplaced pieces.
    final bevelPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.95),
          Colors.white.withValues(alpha: 0.30),
          Colors.black.withValues(alpha: 0.40),
        ],
        stops: const [0.0, 0.50, 1.0],
      ).createShader(bounds);

    canvas.drawPath(path, bevelPaint);
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

  /// Builds a path containing only the flat (outer border) edges of a piece.
  /// Returns null if the piece has no flat edges.
  static Path? buildOuterEdgePath(
    PieceEdges edges,
    double pieceWidth,
    double pieceHeight,
  ) {
    final tabW = pieceWidth * tabFraction;
    final tabH = pieceHeight * tabFraction;

    final left = tabW;
    final top = tabH;
    final right = tabW + pieceWidth;
    final bottom = tabH + pieceHeight;

    final path = Path();
    bool hasAnyEdge = false;

    // Top edge (only if flat - on puzzle border)
    if (edges.top == EdgeType.flat) {
      path.moveTo(left, top);
      path.lineTo(right, top);
      hasAnyEdge = true;
    }

    // Right edge (only if flat - on puzzle border)
    if (edges.right == EdgeType.flat) {
      path.moveTo(right, top);
      path.lineTo(right, bottom);
      hasAnyEdge = true;
    }

    // Bottom edge (only if flat - on puzzle border)
    if (edges.bottom == EdgeType.flat) {
      path.moveTo(right, bottom);
      path.lineTo(left, bottom);
      hasAnyEdge = true;
    }

    // Left edge (only if flat - on puzzle border)
    if (edges.left == EdgeType.flat) {
      path.moveTo(left, bottom);
      path.lineTo(left, top);
      hasAnyEdge = true;
    }

    return hasAnyEdge ? path : null;
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

    path
      // 1. Flat to shoulder
      ..lineTo(pt(0.32, 0).dx, pt(0.32, 0).dy)

      // 2. Shoulder → narrow neck base (smooth entry)
      ..cubicTo(
        pt(0.37, 0.00 * t).dx, pt(0.37, 0.00 * t).dy,
        pt(0.40, 0.08 * t).dx, pt(0.40, 0.08 * t).dy,
        pt(0.40, 0.20 * t).dx, pt(0.40, 0.20 * t).dy,
      )

      // 3. Left dome arc: neck base → apex
      // Flares outward (beyond the neck) to create a round knob.
      ..cubicTo(
        pt(0.30, 0.42 * t).dx, pt(0.30, 0.42 * t).dy,
        pt(0.34, 0.94 * t).dx, pt(0.34, 0.94 * t).dy,
        pt(0.50, 1.00 * t).dx, pt(0.50, 1.00 * t).dy,
      )

      // 4. Right dome arc: apex → neck base (mirror of left)
      ..cubicTo(
        pt(0.66, 0.94 * t).dx, pt(0.66, 0.94 * t).dy,
        pt(0.70, 0.42 * t).dx, pt(0.70, 0.42 * t).dy,
        pt(0.60, 0.20 * t).dx, pt(0.60, 0.20 * t).dy,
      )

      // 5. Neck base → shoulder (smooth exit)
      ..cubicTo(
        pt(0.60, 0.08 * t).dx, pt(0.60, 0.08 * t).dy,
        pt(0.63, 0.00 * t).dx, pt(0.63, 0.00 * t).dy,
        pt(0.68, 0.00 * t).dx, pt(0.68, 0.00 * t).dy,
      )

      // 6. Flat to edge end
      ..lineTo(to.dx, to.dy);
  }

  @override
  bool shouldRepaint(JigsawPiecePainter oldDelegate) {
    return oldDelegate.piece != piece ||
        oldDelegate.pieceWidth != pieceWidth ||
        oldDelegate.pieceHeight != pieceHeight;
  }
}
