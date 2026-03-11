import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'package:lily_jigsaw_puzzle/models/puzzle_piece.dart';

enum GamePhase { loading, assembled, scattering, playing, won }

class GameState extends ChangeNotifier {

  GameState({
    required this.puzzleImage,
    required this.gridSize,
    required this.boardSize,
    this.boardOffset = Offset.zero,
  }) {
    _initialize();
  }
  final ui.Image puzzleImage;
  final int gridSize;
  final Size boardSize;
  final Offset boardOffset;

  late List<PuzzlePiece> pieces;
  GamePhase phase = GamePhase.loading;
  int? draggingIndex;

  late double pieceWidth;
  late double pieceHeight;

  // hConnectors[r][c]: edge between row r and row r+1, col c
  late List<List<EdgeType>> _hConnectors;
  // vConnectors[r][c]: edge between col c and col c+1, row r
  late List<List<EdgeType>> _vConnectors;

  void _initialize() {
    pieceWidth = boardSize.width / gridSize;
    pieceHeight = boardSize.height / gridSize;

    _buildConnectors();
    _buildPieces();
    phase = GamePhase.assembled;
    notifyListeners();
  }

  void _buildConnectors() {
    final rng = Random();
    // Horizontal connectors: (gridSize-1) rows of gridSize columns
    _hConnectors = List.generate(
      gridSize - 1,
      (_) => List.generate(gridSize, (_) => rng.nextBool() ? EdgeType.tab : EdgeType.blank),
    );
    // Vertical connectors: gridSize rows of (gridSize-1) columns
    _vConnectors = List.generate(
      gridSize,
      (_) => List.generate(gridSize - 1, (_) => rng.nextBool() ? EdgeType.tab : EdgeType.blank),
    );
  }

  void _buildPieces() {
    pieces = [];
    for (var r = 0; r < gridSize; r++) {
      for (var c = 0; c < gridSize; c++) {
        final target = boardOffset + Offset(c * pieceWidth, r * pieceHeight);
        pieces.add(
          PuzzlePiece(
            row: r,
            col: c,
            gridSize: gridSize,
            edges: _edgesFor(r, c),
            targetPosition: target,
            currentPosition: target,
          ),
        );
      }
    }
  }

  PieceEdges _edgesFor(int r, int c) {
    // Top edge
    EdgeType top;
    if (r == 0) {
      top = EdgeType.flat;
    } else {
      // complement of the bottom edge of (r-1, c)
      top = _hConnectors[r - 1][c] == EdgeType.tab ? EdgeType.blank : EdgeType.tab;
    }

    // Bottom edge
    EdgeType bottom;
    if (r == gridSize - 1) {
      bottom = EdgeType.flat;
    } else {
      bottom = _hConnectors[r][c];
    }

    // Left edge
    EdgeType left;
    if (c == 0) {
      left = EdgeType.flat;
    } else {
      // complement of the right edge of (r, c-1)
      left = _vConnectors[r][c - 1] == EdgeType.tab ? EdgeType.blank : EdgeType.tab;
    }

    // Right edge
    EdgeType right;
    if (c == gridSize - 1) {
      right = EdgeType.flat;
    } else {
      right = _vConnectors[r][c];
    }

    return PieceEdges(top: top, right: right, bottom: bottom, left: left);
  }

  /// Called per-frame during scatter animation — bypasses notifyListeners for performance.
  void setPiecePosition(int index, Offset position) {
    pieces[index].currentPosition = position;
  }

  /// Sets scatter random target positions in the right-half tray area.
  List<Offset> computeScatterTargets(Size screenSize) {
    final rng = Random();
    const margin = 20.0;
    final trayLeft = screenSize.width / 2 + margin;
    final trayRight = screenSize.width - margin - pieceWidth;
    const trayTop = margin;
    final trayBottom = screenSize.height - margin - pieceHeight;
    return List.generate(pieces.length, (i) {
      return Offset(
        trayLeft + rng.nextDouble() * (trayRight - trayLeft).clamp(0, double.infinity),
        trayTop + rng.nextDouble() * (trayBottom - trayTop).clamp(0, double.infinity),
      );
    });
  }

  void beginPlaying() {
    phase = GamePhase.playing;
    notifyListeners();
  }

  void startDrag(int index) {
    // Move piece to end of list so it renders on top
    final piece = pieces.removeAt(index)
      ..isDragging = true;
    pieces.add(piece);
    draggingIndex = pieces.length - 1;
    notifyListeners();
  }

  void updateDrag(Offset delta) {
    if (draggingIndex == null) return;
    final piece = pieces[draggingIndex!];
    piece.currentPosition = piece.currentPosition + delta;
    notifyListeners();
  }

  /// Ends the drag without snapping/placing — used when the piece was dropped
  /// in the wrong position and the view will animate it back to the tray.
  void endDragNoPlace() {
    if (draggingIndex == null) return;
    pieces[draggingIndex!].isDragging = false;
    draggingIndex = null;
  }

  void endDrag() {
    if (draggingIndex == null) return;
    final piece = pieces[draggingIndex!]
      ..isDragging = false;

    const snapThreshold = 40.0;
    if ((piece.currentPosition - piece.targetPosition).distance <= snapThreshold) {
      piece
        ..currentPosition = piece.targetPosition
        ..isPlaced = true;
    }

    draggingIndex = null;
    notifyListeners();

    if (pieces.every((p) => p.isPlaced)) {
      phase = GamePhase.won;
      notifyListeners();
    }
  }
}
