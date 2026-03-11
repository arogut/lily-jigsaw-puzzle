import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/models/puzzle_piece.dart';

void main() {
  group('EdgeType', () {
    test('has flat, tab and blank values', () {
      expect(EdgeType.values, containsAll([EdgeType.flat, EdgeType.tab, EdgeType.blank]));
    });
  });

  group('PieceEdges', () {
    test('constructor stores all four edges', () {
      const edges = PieceEdges(
        top: EdgeType.flat,
        right: EdgeType.tab,
        bottom: EdgeType.blank,
        left: EdgeType.flat,
      );
      expect(edges.top, EdgeType.flat);
      expect(edges.right, EdgeType.tab);
      expect(edges.bottom, EdgeType.blank);
      expect(edges.left, EdgeType.flat);
    });
  });

  group('PuzzlePiece', () {
    late PuzzlePiece piece;

    setUp(() {
      piece = PuzzlePiece(
        row: 1,
        col: 2,
        gridSize: 3,
        edges: const PieceEdges(
          top: EdgeType.flat,
          right: EdgeType.tab,
          bottom: EdgeType.blank,
          left: EdgeType.flat,
        ),
        targetPosition: const Offset(100, 200),
        currentPosition: const Offset(100, 200),
      );
    });

    test('constructor stores position and grid info', () {
      expect(piece.row, 1);
      expect(piece.col, 2);
      expect(piece.gridSize, 3);
      expect(piece.targetPosition, const Offset(100, 200));
      expect(piece.currentPosition, const Offset(100, 200));
    });

    test('default isPlaced is false', () {
      expect(piece.isPlaced, isFalse);
    });

    test('default isDragging is false', () {
      expect(piece.isDragging, isFalse);
    });

    test('isPlaced and isDragging are mutable', () {
      piece
        ..isPlaced = true
        ..isDragging = true;
      expect(piece.isPlaced, isTrue);
      expect(piece.isDragging, isTrue);
    });

    test('currentPosition is mutable', () {
      piece.currentPosition = const Offset(50, 75);
      expect(piece.currentPosition, const Offset(50, 75));
      // targetPosition stays unchanged
      expect(piece.targetPosition, const Offset(100, 200));
    });
  });
}
