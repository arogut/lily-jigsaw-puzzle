import 'package:flutter/material.dart';

import '../models/puzzle_piece.dart';
import 'jigsaw_piece_painter.dart';

/// Draws a 2×2 jigsaw puzzle logo with solid color fills.
/// Used on the splash screen.
class LogoPainter extends CustomPainter {
  final double size;

  const LogoPainter({required this.size});

  static const List<Color> _pieceColors = [
    Color(0xFFFF6B9D), // pink   — top-left
    Color(0xFFFFD93D), // yellow — top-right
    Color(0xFF4D96FF), // blue   — bottom-left
    Color(0xFF6BCB77), // green  — bottom-right
  ];

  // 2×2 pieces whose edges interlock correctly
  static const List<PieceEdges> _logoEdges = [
    // TL: outer top/left are flat; right and bottom have tabs going inward
    PieceEdges(
        top: EdgeType.flat,
        right: EdgeType.tab,
        bottom: EdgeType.tab,
        left: EdgeType.flat),
    // TR: outer top/right are flat; left blank (matches TL right tab)
    PieceEdges(
        top: EdgeType.flat,
        right: EdgeType.flat,
        bottom: EdgeType.tab,
        left: EdgeType.blank),
    // BL: outer left/bottom are flat; top blank (matches TL bottom tab)
    PieceEdges(
        top: EdgeType.blank,
        right: EdgeType.tab,
        bottom: EdgeType.flat,
        left: EdgeType.flat),
    // BR: outer right/bottom are flat; top/left blanks match above tabs
    PieceEdges(
        top: EdgeType.blank,
        right: EdgeType.flat,
        bottom: EdgeType.flat,
        left: EdgeType.blank),
  ];

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final pw = size / 2;
    final ph = size / 2;
    final tabW = pw * JigsawPiecePainter.tabFraction;
    final tabH = ph * JigsawPiecePainter.tabFraction;

    final gridPositions = [
      Offset(0, 0), // TL
      Offset(pw, 0), // TR
      Offset(0, ph), // BL
      Offset(pw, ph), // BR
    ];

    // Centre the 2×2 grid inside the canvas
    final originX = (canvasSize.width - size) / 2;
    final originY = (canvasSize.height - size) / 2;

    canvas.save();
    canvas.translate(originX, originY);

    for (int i = 0; i < 4; i++) {
      final pos = gridPositions[i];
      final path =
          JigsawPiecePainter.buildPiecePath(_logoEdges[i], pw, ph);

      canvas.save();
      canvas.translate(pos.dx - tabW, pos.dy - tabH);

      // Shadow — offset fill without blur for performance
      canvas.save();
      canvas.translate(3, 5);
      canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: 0.28));
      canvas.restore();

      // Solid colour fill
      canvas.drawPath(path, Paint()..color = _pieceColors[i]);

      // Gloss overlay (top-left highlight)
      canvas.save();
      canvas.clipPath(path);
      final bounds = Rect.fromLTWH(0, 0, pw + 2 * tabW, ph + 2 * tabH);
      canvas.drawRect(
        bounds,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x60FFFFFF), Color(0x00FFFFFF)],
            stops: [0.0, 0.55],
          ).createShader(bounds),
      );
      canvas.restore();

      // White border
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.90)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );

      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(LogoPainter old) => old.size != size;
}
