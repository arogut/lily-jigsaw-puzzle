import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/models/puzzle_piece.dart';
import 'package:lily_jigsaw_puzzle/painters/board_shadow_painter.dart';

PuzzlePiece _makePiece({bool isPlaced = false}) => PuzzlePiece(
      row: 0,
      col: 0,
      gridSize: 3,
      edges: const PieceEdges(
        top: EdgeType.flat,
        right: EdgeType.flat,
        bottom: EdgeType.flat,
        left: EdgeType.flat,
      ),
      targetPosition: const Offset(10, 10),
      currentPosition: const Offset(200, 200),
      isPlaced: isPlaced,
    );

void main() {
  group('BoardShadowPainter', () {
    test('paints without error with empty pieces list', () {
      const painter = BoardShadowPainter(
        pieces: [],
        pieceWidth: 100,
        pieceHeight: 100,
      );
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(600, 400));
      recorder.endRecording().dispose();
    });

    test('paints without error with unplaced piece', () {
      final painter = BoardShadowPainter(
        pieces: [_makePiece(isPlaced: false)],
        pieceWidth: 100,
        pieceHeight: 100,
      );
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(600, 400));
      recorder.endRecording().dispose();
    });

    test('skips placed pieces during paint', () {
      final painter = BoardShadowPainter(
        pieces: [
          _makePiece(isPlaced: true),
          _makePiece(isPlaced: false),
        ],
        pieceWidth: 100,
        pieceHeight: 100,
      );
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(600, 400));
      recorder.endRecording().dispose();
    });

    test('shouldRepaint returns true when pieces length differs', () {
      final p1 = BoardShadowPainter(
        pieces: [_makePiece()],
        pieceWidth: 100,
        pieceHeight: 100,
      );
      final p2 = BoardShadowPainter(
        pieces: [_makePiece(), _makePiece()],
        pieceWidth: 100,
        pieceHeight: 100,
      );
      expect(p2.shouldRepaint(p1), isTrue);
    });

    test('shouldRepaint returns true when isPlaced changes', () {
      final p1 = BoardShadowPainter(
        pieces: [_makePiece(isPlaced: false)],
        pieceWidth: 100,
        pieceHeight: 100,
      );
      final p2 = BoardShadowPainter(
        pieces: [_makePiece(isPlaced: true)],
        pieceWidth: 100,
        pieceHeight: 100,
      );
      expect(p2.shouldRepaint(p1), isTrue);
    });

    test('shouldRepaint returns false when placement is unchanged', () {
      final p1 = BoardShadowPainter(
        pieces: [_makePiece(isPlaced: false)],
        pieceWidth: 100,
        pieceHeight: 100,
      );
      final p2 = BoardShadowPainter(
        pieces: [_makePiece(isPlaced: false)],
        pieceWidth: 100,
        pieceHeight: 100,
      );
      expect(p2.shouldRepaint(p1), isFalse);
    });

    test('shouldRepaint returns false for two empty lists', () {
      const p1 = BoardShadowPainter(pieces: [], pieceWidth: 100, pieceHeight: 100);
      const p2 = BoardShadowPainter(pieces: [], pieceWidth: 100, pieceHeight: 100);
      expect(p2.shouldRepaint(p1), isFalse);
    });
  });
}
