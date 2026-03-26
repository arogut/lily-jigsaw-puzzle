import 'dart:ui';

enum EdgeType { flat, tab, blank }

class PieceEdges {

  const PieceEdges({
    required this.top,
    required this.right,
    required this.bottom,
    required this.left,
  });
  final EdgeType top;
  final EdgeType right;
  final EdgeType bottom;
  final EdgeType left;
}

class PuzzlePiece {

  PuzzlePiece({
    required this.row,
    required this.col,
    required this.gridSize,
    required this.edges,
    required this.targetPosition,
    required this.currentPosition,
    this.isPlaced = false,
    this.isDragging = false,
    this.isHinted = false,
  });
  final int row;
  final int col;
  final int gridSize;
  final PieceEdges edges;
  final Offset targetPosition;

  Offset currentPosition;
  bool isPlaced;
  bool isDragging;
  bool isHinted;

  /// Current velocity in pixels per second, used by the physics simulation
  /// for momentum, throw-and-bounce.
  Offset velocity = Offset.zero;

  /// Scale factor for the lift effect: 1.0 = normal size, > 1.0 = lifted
  /// during drag to give a "picked up" feel.
  double scale = 1;
}
