import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/models/puzzle_piece.dart';
import 'package:lily_jigsaw_puzzle/painters/all_pieces_painter.dart';

PuzzlePiece _makePiece({int row = 0, int col = 0}) => PuzzlePiece(
      row: row,
      col: col,
      gridSize: 3,
      edges: const PieceEdges(
        top: EdgeType.flat,
        right: EdgeType.tab,
        bottom: EdgeType.blank,
        left: EdgeType.flat,
      ),
      targetPosition: Offset(col * 100.0, row * 100.0),
      currentPosition: Offset(col * 100.0 + 300, row * 100.0),
    );

void main() {
  group('AllPiecesPainter', () {
    late ui.Image testImage;

    setUpAll(() async {
      testImage = await createTestImage(width: 100, height: 100);
    });

    tearDownAll(() {
      testImage.dispose();
    });

    test('paints empty pieces list without error', () {
      final notifier = ValueNotifier<int>(0);
      final painter = AllPiecesPainter(
        pieces: const [],
        image: testImage,
        pieceWidth: 100,
        pieceHeight: 100,
        repaintNotifier: notifier,
      );
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(800, 600));
      recorder.endRecording().dispose();
      notifier.dispose();
    });

    test('paints single piece without error', () {
      final notifier = ValueNotifier<int>(0);
      final painter = AllPiecesPainter(
        pieces: [_makePiece()],
        image: testImage,
        pieceWidth: 100,
        pieceHeight: 100,
        repaintNotifier: notifier,
      );
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(800, 600));
      recorder.endRecording().dispose();
      notifier.dispose();
    });

    test('paints multiple pieces without error', () {
      final notifier = ValueNotifier<int>(0);
      final pieces = [
        _makePiece(row: 0, col: 0),
        _makePiece(row: 0, col: 1),
        _makePiece(row: 1, col: 0),
      ];
      final painter = AllPiecesPainter(
        pieces: pieces,
        image: testImage,
        pieceWidth: 100,
        pieceHeight: 100,
        repaintNotifier: notifier,
      );
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(800, 600));
      recorder.endRecording().dispose();
      notifier.dispose();
    });

    test('shouldRepaint always returns true', () {
      final notifier = ValueNotifier<int>(0);
      final painter = AllPiecesPainter(
        pieces: const [],
        image: testImage,
        pieceWidth: 100,
        pieceHeight: 100,
        repaintNotifier: notifier,
      );
      expect(painter.shouldRepaint(painter), isTrue);
      notifier.dispose();
    });
  });
}
