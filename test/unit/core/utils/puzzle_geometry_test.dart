import 'dart:math';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/core/utils/puzzle_geometry.dart';

void main() {
  group('PuzzleGeometry', () {
    test('tabWidth and tabHeight scale with piece dimensions', () {
      expect(PuzzleGeometry.tabWidth(100), 35);
      expect(PuzzleGeometry.tabHeight(200), 70);
    });

    test('trayBounds spans the right half of the screen', () {
      const screen = Size(800, 600);
      final bounds = PuzzleGeometry.trayBounds(screen);
      expect(bounds.left, 420);
      expect(bounds.right, 780);
      expect(bounds.top, 0);
      expect(bounds.bottom, 600);
    });

    test('randomScatterTargets returns one offset per piece', () {
      const screen = Size(800, 600);
      final targets = PuzzleGeometry.randomScatterTargets(
        pieceCount: 4,
        screenSize: screen,
        pieceWidth: 100,
        pieceHeight: 100,
        random: Random(1),
      );
      expect(targets, hasLength(4));
      for (final target in targets) {
        expect(target.dx, greaterThanOrEqualTo(420));
        expect(target.dy, greaterThanOrEqualTo(PuzzleGeometry.edgePad));
      }
    });
  });
}
