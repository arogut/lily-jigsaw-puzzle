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
    this.isFaceDown = false,
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

  /// Whether this piece is face-down (back facing up). Face-down pieces cannot
  /// be dragged — the player must tap to flip them first.
  bool isFaceDown;

  /// Flip animation progress: 0.0 = fully face-down, 1.0 = fully face-up.
  /// Values in (0, 1) represent a mid-flip state used for the squeeze animation.
  double flipProgress = 1.0;

  /// Current velocity in pixels per second, used by the physics simulation
  /// for momentum, throw-and-bounce, and gravity.
  Offset velocity = Offset.zero;

  /// Scale factor for the lift effect: 1.0 = normal size, > 1.0 = lifted
  /// during drag to give a "picked up" feel.
  double scale = 1.0;

  /// Group ID for group snapping. Pieces with the same non-null [groupId]
  /// move together when dragged and snap together when one of them snaps.
  int? groupId;
}
