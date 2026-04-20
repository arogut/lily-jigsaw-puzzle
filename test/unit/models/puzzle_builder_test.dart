import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/models/puzzle_builder.dart';
import 'package:lily_jigsaw_puzzle/models/puzzle_piece.dart';

void main() {
  group('PuzzleBuilder.build', () {
    const gridSize = 3;
    const boardSize = Size(300, 300);
    const boardOffset = Offset(20, 20);

    ({List<PuzzlePiece> pieces, double pieceWidth, double pieceHeight}) build({
      int gs = gridSize,
      Size size = boardSize,
      Offset offset = boardOffset,
    }) =>
        PuzzleBuilder.build(gridSize: gs, boardSize: size, boardOffset: offset);

    test('returns gridSize² pieces', () {
      final result = build();
      expect(result.pieces.length, gridSize * gridSize);
    });

    test('returns correct piece dimensions', () {
      final result = build();
      expect(result.pieceWidth, closeTo(boardSize.width / gridSize, 0.001));
      expect(result.pieceHeight, closeTo(boardSize.height / gridSize, 0.001));
    });

    test('all pieces start at their target positions', () {
      final result = build();
      for (final piece in result.pieces) {
        expect(piece.currentPosition, piece.targetPosition);
      }
    });

    test('covers all grid positions exactly once', () {
      final result = build();
      final positions = result.pieces.map((p) => (p.row, p.col)).toSet();
      for (var r = 0; r < gridSize; r++) {
        for (var c = 0; c < gridSize; c++) {
          expect(positions.contains((r, c)), isTrue);
        }
      }
    });

    test('target positions respect boardOffset', () {
      final result = build();
      final topLeft = result.pieces.firstWhere((p) => p.row == 0 && p.col == 0);
      expect(topLeft.targetPosition, boardOffset);
    });

    test('border pieces have flat outer edges', () {
      final result = build();
      for (final piece in result.pieces) {
        if (piece.row == 0) expect(piece.edges.top, EdgeType.flat);
        if (piece.row == gridSize - 1) expect(piece.edges.bottom, EdgeType.flat);
        if (piece.col == 0) expect(piece.edges.left, EdgeType.flat);
        if (piece.col == gridSize - 1) expect(piece.edges.right, EdgeType.flat);
      }
    });

    test('horizontally adjacent pieces have complementary edges', () {
      final result = build();
      for (final piece in result.pieces) {
        if (piece.row == 0) continue;
        final above = result.pieces.firstWhere(
          (p) => p.row == piece.row - 1 && p.col == piece.col,
        );
        if (above.edges.bottom == EdgeType.tab) {
          expect(piece.edges.top, EdgeType.blank);
        } else {
          expect(piece.edges.top, EdgeType.tab);
        }
      }
    });

    test('vertically adjacent pieces have complementary edges', () {
      final result = build();
      for (final piece in result.pieces) {
        if (piece.col == 0) continue;
        final leftNeighbour = result.pieces.firstWhere(
          (p) => p.row == piece.row && p.col == piece.col - 1,
        );
        if (leftNeighbour.edges.right == EdgeType.tab) {
          expect(piece.edges.left, EdgeType.blank);
        } else {
          expect(piece.edges.left, EdgeType.tab);
        }
      }
    });

    test('inner edges are tab or blank (never flat)', () {
      final result = build();
      for (final piece in result.pieces) {
        if (piece.row > 0) expect(piece.edges.top, isNot(EdgeType.flat));
        if (piece.row < gridSize - 1) expect(piece.edges.bottom, isNot(EdgeType.flat));
        if (piece.col > 0) expect(piece.edges.left, isNot(EdgeType.flat));
        if (piece.col < gridSize - 1) expect(piece.edges.right, isNot(EdgeType.flat));
      }
    });

    test('works for 5×5 grid', () {
      final result = build(gs: 5, size: const Size(500, 500));
      expect(result.pieces.length, 25);
      expect(result.pieceWidth, closeTo(100.0, 0.001));
    });

    test('no piece starts as placed or dragging', () {
      final result = build();
      expect(result.pieces.every((p) => !p.isPlaced), isTrue);
      expect(result.pieces.every((p) => !p.isDragging), isTrue);
    });
  });
}
