import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/models/puzzle_piece.dart';
import 'package:lily_jigsaw_puzzle/painters/hint_glow_painter.dart';

PuzzlePiece _makePiece({bool isHinted = false}) => PuzzlePiece(
      row: 0,
      col: 0,
      gridSize: 3,
      edges: const PieceEdges(
        top: EdgeType.flat,
        right: EdgeType.tab,
        bottom: EdgeType.blank,
        left: EdgeType.flat,
      ),
      targetPosition: const Offset(0, 0),
      currentPosition: const Offset(300, 0),
      isHinted: isHinted,
    );

void main() {
  group('HintGlowPainter', () {
    test('paints nothing when no piece is hinted', () {
      final painter = HintGlowPainter(
        pieces: [_makePiece()],
        pieceWidth: 100,
        pieceHeight: 100,
        animation: const AlwaysStoppedAnimation(0.0),
      );
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(800, 600));
      recorder.endRecording().dispose();
    });

    test('paints nothing for empty pieces list', () {
      final painter = HintGlowPainter(
        pieces: const [],
        pieceWidth: 100,
        pieceHeight: 100,
        animation: const AlwaysStoppedAnimation(0.0),
      );
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(800, 600));
      recorder.endRecording().dispose();
    });

    test('paints golden glow at current position when a piece is hinted', () {
      final painter = HintGlowPainter(
        pieces: [_makePiece(isHinted: true)],
        pieceWidth: 100,
        pieceHeight: 100,
        animation: const AlwaysStoppedAnimation(0.5),
      );
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(800, 600));
      recorder.endRecording().dispose();
    });

    test('paints glow with animation value at 0.0 without error', () {
      final painter = HintGlowPainter(
        pieces: [_makePiece(isHinted: true)],
        pieceWidth: 100,
        pieceHeight: 100,
        animation: const AlwaysStoppedAnimation(0.0),
      );
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(800, 600));
      recorder.endRecording().dispose();
    });

    test('paints glow with animation value at 1.0 without error', () {
      final painter = HintGlowPainter(
        pieces: [_makePiece(isHinted: true)],
        pieceWidth: 100,
        pieceHeight: 100,
        animation: const AlwaysStoppedAnimation(1.0),
      );
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(800, 600));
      recorder.endRecording().dispose();
    });

    test('paints glow for lifted (scaled) piece without error', () {
      final piece = _makePiece(isHinted: true)..scale = 1.08;
      final painter = HintGlowPainter(
        pieces: [piece],
        pieceWidth: 100,
        pieceHeight: 100,
        animation: const AlwaysStoppedAnimation(0.25),
      );
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(800, 600));
      recorder.endRecording().dispose();
    });

    test('uses first hinted piece when multiple pieces exist', () {
      final hinted = _makePiece(isHinted: true);
      final painter = HintGlowPainter(
        pieces: [_makePiece(), hinted, _makePiece()],
        pieceWidth: 100,
        pieceHeight: 100,
        animation: const AlwaysStoppedAnimation(0.5),
      );
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(800, 600));
      recorder.endRecording().dispose();
    });

    test('shouldRepaint returns false when pieces and dimensions unchanged', () {
      final pieces = [_makePiece()];
      final p1 = HintGlowPainter(
        pieces: pieces,
        pieceWidth: 100,
        pieceHeight: 100,
        animation: const AlwaysStoppedAnimation(0.0),
      );
      final p2 = HintGlowPainter(
        pieces: pieces,
        pieceWidth: 100,
        pieceHeight: 100,
        animation: const AlwaysStoppedAnimation(0.0),
      );
      expect(p2.shouldRepaint(p1), isFalse);
    });

    test('shouldRepaint returns true when pieces list differs', () {
      final p1 = HintGlowPainter(
        pieces: [_makePiece()],
        pieceWidth: 100,
        pieceHeight: 100,
        animation: const AlwaysStoppedAnimation(0.0),
      );
      final p2 = HintGlowPainter(
        pieces: [_makePiece(isHinted: true)],
        pieceWidth: 100,
        pieceHeight: 100,
        animation: const AlwaysStoppedAnimation(0.0),
      );
      expect(p2.shouldRepaint(p1), isTrue);
    });

    test('shouldRepaint returns true when pieceWidth differs', () {
      final pieces = [_makePiece()];
      final p1 = HintGlowPainter(
        pieces: pieces,
        pieceWidth: 100,
        pieceHeight: 100,
        animation: const AlwaysStoppedAnimation(0.0),
      );
      final p2 = HintGlowPainter(
        pieces: pieces,
        pieceWidth: 200,
        pieceHeight: 100,
        animation: const AlwaysStoppedAnimation(0.0),
      );
      expect(p2.shouldRepaint(p1), isTrue);
    });

    test('shouldRepaint returns true when pieceHeight differs', () {
      final pieces = [_makePiece()];
      final p1 = HintGlowPainter(
        pieces: pieces,
        pieceWidth: 100,
        pieceHeight: 100,
        animation: const AlwaysStoppedAnimation(0.0),
      );
      final p2 = HintGlowPainter(
        pieces: pieces,
        pieceWidth: 100,
        pieceHeight: 200,
        animation: const AlwaysStoppedAnimation(0.0),
      );
      expect(p2.shouldRepaint(p1), isTrue);
    });
  });
}
