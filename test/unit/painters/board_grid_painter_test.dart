import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/painters/board_grid_painter.dart';

void main() {
  group('BoardGridPainter', () {
    test('paints without error for 3x3 grid', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const painter = BoardGridPainter(3);
      painter.paint(canvas, const Size(300, 300));
      recorder.endRecording().dispose();
    });

    test('paints without error for 5x5 grid', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const painter = BoardGridPainter(5);
      painter.paint(canvas, const Size(500, 500));
      recorder.endRecording().dispose();
    });

    test('paints without error for 7x7 grid', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const painter = BoardGridPainter(7);
      painter.paint(canvas, const Size(700, 700));
      recorder.endRecording().dispose();
    });

    test('shouldRepaint returns true when gridSize changes', () {
      const old = BoardGridPainter(3);
      const next = BoardGridPainter(5);
      expect(next.shouldRepaint(old), isTrue);
    });

    test('shouldRepaint returns false when gridSize is unchanged', () {
      const p1 = BoardGridPainter(3);
      const p2 = BoardGridPainter(3);
      expect(p2.shouldRepaint(p1), isFalse);
    });

    test('non-const constructor is callable at runtime', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      // Use a runtime value so const is not possible, exercising the constructor.
      final gridSize = 3 + 1;
      final painter = BoardGridPainter(gridSize);
      painter.paint(canvas, const Size(400, 400));
      recorder.endRecording().dispose();
    });
  });
}
