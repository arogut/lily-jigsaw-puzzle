import 'dart:math';

import 'package:flutter/painting.dart';

import 'package:lily_jigsaw_puzzle/models/puzzle_piece.dart';

/// Constructs the initial set of puzzle pieces for a game session.
///
/// Randomly assigns tab/blank connector shapes to all shared edges so adjacent
/// pieces interlock correctly.
class PuzzleBuilder {
  PuzzleBuilder._();

  /// Builds [gridSize]² pieces positioned within [boardSize] at [boardOffset].
  ///
  /// Returns the piece list along with the computed piece dimensions.
  static ({
    List<PuzzlePiece> pieces,
    double pieceWidth,
    double pieceHeight,
  }) build({
    required int gridSize,
    required Size boardSize,
    required Offset boardOffset,
  }) {
    final pieceWidth = boardSize.width / gridSize;
    final pieceHeight = boardSize.height / gridSize;

    final rng = Random();
    // hConnectors[r][c]: edge between row r and row r+1, col c
    final hConnectors = List.generate(
      gridSize - 1,
      (_) => List.generate(
        gridSize,
        (_) => rng.nextBool() ? EdgeType.tab : EdgeType.blank,
      ),
    );
    // vConnectors[r][c]: edge between col c and col c+1, row r
    final vConnectors = List.generate(
      gridSize,
      (_) => List.generate(
        gridSize - 1,
        (_) => rng.nextBool() ? EdgeType.tab : EdgeType.blank,
      ),
    );

    final pieces = <PuzzlePiece>[];
    for (var r = 0; r < gridSize; r++) {
      for (var c = 0; c < gridSize; c++) {
        final target = boardOffset + Offset(c * pieceWidth, r * pieceHeight);
        pieces.add(PuzzlePiece(
          row: r,
          col: c,
          gridSize: gridSize,
          edges: _edgesFor(r, c, gridSize, hConnectors, vConnectors),
          targetPosition: target,
          currentPosition: target,
        ));
      }
    }
    return (pieces: pieces, pieceWidth: pieceWidth, pieceHeight: pieceHeight);
  }

  static PieceEdges _edgesFor(
    int r,
    int c,
    int gridSize,
    List<List<EdgeType>> hConnectors,
    List<List<EdgeType>> vConnectors,
  ) {
    final top = r == 0
        ? EdgeType.flat
        : (hConnectors[r - 1][c] == EdgeType.tab
            ? EdgeType.blank
            : EdgeType.tab);
    final bottom = r == gridSize - 1 ? EdgeType.flat : hConnectors[r][c];
    final left = c == 0
        ? EdgeType.flat
        : (vConnectors[r][c - 1] == EdgeType.tab
            ? EdgeType.blank
            : EdgeType.tab);
    final right = c == gridSize - 1 ? EdgeType.flat : vConnectors[r][c];
    return PieceEdges(top: top, right: right, bottom: bottom, left: left);
  }
}
