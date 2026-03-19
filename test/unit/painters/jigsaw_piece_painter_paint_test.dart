import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/models/puzzle_piece.dart';
import 'package:lily_jigsaw_puzzle/painters/jigsaw_piece_painter.dart';

PuzzlePiece _makePiece(PieceEdges edges, {int row = 0, int col = 0, int gridSize = 3}) =>
    PuzzlePiece(
      row: row,
      col: col,
      gridSize: gridSize,
      edges: edges,
      targetPosition: Offset.zero,
      currentPosition: Offset.zero,
    );

void _paintPiece(PuzzlePiece piece, ui.Image image, {double pw = 100, double ph = 100}) {
  final painter = JigsawPiecePainter(
    piece: piece,
    image: image,
    pieceWidth: pw,
    pieceHeight: ph,
  );
  const tabFrac = JigsawPiecePainter.tabFraction;
  final size = Size(pw * (1 + 2 * tabFrac), ph * (1 + 2 * tabFrac));
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  painter.paint(canvas, size);
  recorder.endRecording().dispose();
}

void main() {
  group('JigsawPiecePainter.paint', () {
    late ui.Image testImage;

    setUpAll(() async {
      testImage = await createTestImage(width: 300, height: 300);
    });

    tearDownAll(() {
      testImage.dispose();
    });

    test('paints all-flat piece without error', () {
      _paintPiece(
        _makePiece(const PieceEdges(
          top: EdgeType.flat,
          right: EdgeType.flat,
          bottom: EdgeType.flat,
          left: EdgeType.flat,
        )),
        testImage,
      );
    });

    test('paints piece with all tab edges without error', () {
      _paintPiece(
        _makePiece(const PieceEdges(
          top: EdgeType.tab,
          right: EdgeType.tab,
          bottom: EdgeType.tab,
          left: EdgeType.tab,
        )),
        testImage,
      );
    });

    test('paints piece with all blank edges without error', () {
      _paintPiece(
        _makePiece(const PieceEdges(
          top: EdgeType.blank,
          right: EdgeType.blank,
          bottom: EdgeType.blank,
          left: EdgeType.blank,
        )),
        testImage,
      );
    });

    test('paints interior piece (tab right/bottom, blank top/left) without error', () {
      _paintPiece(
        _makePiece(
          const PieceEdges(
            top: EdgeType.blank,
            right: EdgeType.tab,
            bottom: EdgeType.tab,
            left: EdgeType.blank,
          ),
          row: 1,
          col: 1,
        ),
        testImage,
      );
    });

    test('paints corner piece (flat top/left, tab right/bottom) without error', () {
      _paintPiece(
        _makePiece(const PieceEdges(
          top: EdgeType.flat,
          right: EdgeType.tab,
          bottom: EdgeType.tab,
          left: EdgeType.flat,
        )),
        testImage,
      );
    });

    test('paints non-square piece without error', () {
      _paintPiece(
        _makePiece(const PieceEdges(
          top: EdgeType.flat,
          right: EdgeType.tab,
          bottom: EdgeType.flat,
          left: EdgeType.blank,
        )),
        testImage,
        pw: 120,
        ph: 80,
      );
    });

    test('paints piece at non-zero grid position without error', () {
      _paintPiece(
        _makePiece(
          const PieceEdges(
            top: EdgeType.blank,
            right: EdgeType.flat,
            bottom: EdgeType.tab,
            left: EdgeType.blank,
          ),
          row: 2,
          col: 1,
          gridSize: 5,
        ),
        testImage,
        pw: 60,
        ph: 60,
      );
    });

    test('shouldRepaint returns false for same piece reference', () {
      final piece = _makePiece(const PieceEdges(
        top: EdgeType.flat,
        right: EdgeType.flat,
        bottom: EdgeType.flat,
        left: EdgeType.flat,
      ));
      final p1 = JigsawPiecePainter(
        piece: piece,
        image: testImage,
        pieceWidth: 100,
        pieceHeight: 100,
      );
      final p2 = JigsawPiecePainter(
        piece: piece,
        image: testImage,
        pieceWidth: 100,
        pieceHeight: 100,
      );
      expect(p2.shouldRepaint(p1), isFalse);
    });

    test('shouldRepaint returns true for different piece instance', () {
      final piece1 = _makePiece(const PieceEdges(
        top: EdgeType.flat,
        right: EdgeType.flat,
        bottom: EdgeType.flat,
        left: EdgeType.flat,
      ));
      final piece2 = _makePiece(const PieceEdges(
        top: EdgeType.tab,
        right: EdgeType.flat,
        bottom: EdgeType.flat,
        left: EdgeType.flat,
      ));
      final p1 = JigsawPiecePainter(
        piece: piece1,
        image: testImage,
        pieceWidth: 100,
        pieceHeight: 100,
      );
      final p2 = JigsawPiecePainter(
        piece: piece2,
        image: testImage,
        pieceWidth: 100,
        pieceHeight: 100,
      );
      expect(p2.shouldRepaint(p1), isTrue);
    });

    test('shouldRepaint returns true for different pieceWidth', () {
      final piece = _makePiece(const PieceEdges(
        top: EdgeType.flat,
        right: EdgeType.flat,
        bottom: EdgeType.flat,
        left: EdgeType.flat,
      ));
      final p1 = JigsawPiecePainter(
        piece: piece,
        image: testImage,
        pieceWidth: 100,
        pieceHeight: 100,
      );
      final p2 = JigsawPiecePainter(
        piece: piece,
        image: testImage,
        pieceWidth: 150,
        pieceHeight: 100,
      );
      expect(p2.shouldRepaint(p1), isTrue);
    });

    test('paints face-down piece without error', () {
      final piece = _makePiece(const PieceEdges(
        top: EdgeType.flat,
        right: EdgeType.flat,
        bottom: EdgeType.flat,
        left: EdgeType.flat,
      ))..isFaceDown = true;
      _paintPiece(piece, testImage);
    });

    test('paints face-down piece with logo image without error', () async {
      final logoImg = await createTestImage(width: 48, height: 48);
      final piece = _makePiece(const PieceEdges(
        top: EdgeType.flat,
        right: EdgeType.flat,
        bottom: EdgeType.flat,
        left: EdgeType.flat,
      ))..isFaceDown = true;
      final painter = JigsawPiecePainter(
        piece: piece,
        image: testImage,
        pieceWidth: 100,
        pieceHeight: 100,
        logoImage: logoImg,
      );
      const tabFrac = JigsawPiecePainter.tabFraction;
      const pw = 100.0;
      const ph = 100.0;
      final size = Size(pw * (1 + 2 * tabFrac), ph * (1 + 2 * tabFrac));
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, size);
      recorder.endRecording().dispose();
      logoImg.dispose();
    });

    test('shouldRepaint returns true for different pieceHeight', () {
      final piece = _makePiece(const PieceEdges(
        top: EdgeType.flat,
        right: EdgeType.flat,
        bottom: EdgeType.flat,
        left: EdgeType.flat,
      ));
      final p1 = JigsawPiecePainter(
        piece: piece,
        image: testImage,
        pieceWidth: 100,
        pieceHeight: 100,
      );
      final p2 = JigsawPiecePainter(
        piece: piece,
        image: testImage,
        pieceWidth: 100,
        pieceHeight: 150,
      );
      expect(p2.shouldRepaint(p1), isTrue);
    });
  });
}
