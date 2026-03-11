import 'package:flutter/material.dart';

class BoardGridPainter extends CustomPainter {
  const BoardGridPainter(this.gridSize);

  final int gridSize;

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / gridSize;
    final cellH = size.height / gridSize;

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.30)
      ..strokeWidth = 1.0;
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.50)
      ..strokeWidth = 0;

    for (var r = 0; r <= gridSize; r++) {
      final y = r * cellH;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    for (var c = 0; c <= gridSize; c++) {
      final x = c * cellW;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (var r = 0; r <= gridSize; r++) {
      for (var c = 0; c <= gridSize; c++) {
        canvas.drawCircle(Offset(c * cellW, r * cellH), 2.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(BoardGridPainter old) => old.gridSize != gridSize;
}
