import 'dart:ui';

enum EdgeType { flat, tab, blank }

class PieceEdges {
  final EdgeType top;
  final EdgeType right;
  final EdgeType bottom;
  final EdgeType left;

  const PieceEdges({
    required this.top,
    required this.right,
    required this.bottom,
    required this.left,
  });
}

class PuzzlePiece {
  final int row;
  final int col;
  final int gridSize;
  final PieceEdges edges;
  final Offset targetPosition;

  Offset currentPosition;
  bool isPlaced;
  bool isDragging;

  PuzzlePiece({
    required this.row,
    required this.col,
    required this.gridSize,
    required this.edges,
    required this.targetPosition,
    required this.currentPosition,
    this.isPlaced = false,
    this.isDragging = false,
  });
}
