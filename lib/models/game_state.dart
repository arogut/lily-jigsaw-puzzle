import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'package:lily_jigsaw_puzzle/models/puzzle_piece.dart';

// ── Physics constants ──────────────────────────────────────────────────────
const double _kLiftScale = 1.08;
const double _kSnapThreshold = 40;
const double _kMagnetRadius = 80;

// Velocity friction: vel *= (1 - _kFriction * dt). Half-life ≈ 0.1 seconds.
const double _kFriction = 6;

// Bounce damping at tray walls.
const double _kBounceDamp = 0.35;

const double _kMaxVelocity = 1500;
const double _kMinVelocity = 5;

// ──────────────────────────────────────────────────────────────────────────

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
  int hintsRemaining = 3;

  late double pieceWidth;
  late double pieceHeight;

  // hConnectors[r][c]: edge between row r and row r+1, col c
  late List<List<EdgeType>> _hConnectors;
  // vConnectors[r][c]: edge between col c and col c+1, row r
  late List<List<EdgeType>> _vConnectors;

  // Velocity tracking during drag.
  Offset _dragVelocity = Offset.zero;
  DateTime? _lastDragTime;

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

  /// Sets scatter random target positions spread across the right-half tray area.
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

  // ── Drag lifecycle ────────────────────────────────────────────────────────

  void startDrag(int index) {
    _dragVelocity = Offset.zero;
    _lastDragTime = DateTime.now();

    // Move primary piece to end of list so it renders on top.
    final piece = pieces[index];
    pieces.remove(piece);
    piece
      ..isDragging = true
      ..scale = _kLiftScale
      ..velocity = Offset.zero;
    pieces.add(piece);
    draggingIndex = pieces.length - 1;
    notifyListeners();
  }

  void updateDrag(Offset delta) {
    if (draggingIndex == null) return;

    // Track velocity using an exponential moving average.
    final now = DateTime.now();
    if (_lastDragTime != null) {
      final dt = now.difference(_lastDragTime!).inMicroseconds / 1e6;
      if (dt > 0 && dt < 0.1) {
        final rawVel = delta / dt;
        _dragVelocity = _dragVelocity * 0.6 + rawVel * 0.4;
      }
    }
    _lastDragTime = now;

    final piece = pieces[draggingIndex!];
    final adjustedDelta = _applyMagneticPull(piece, delta);

    piece.currentPosition = piece.currentPosition + adjustedDelta;
    notifyListeners();
  }

  /// Applies a subtle magnetic pull toward the snap target when the piece is
  /// within [_kMagnetRadius]. Returns the adjusted delta.
  Offset _applyMagneticPull(PuzzlePiece piece, Offset delta) {
    final dist = (piece.currentPosition - piece.targetPosition).distance;
    if (dist <= 0 || dist > _kMagnetRadius) return delta;

    // Pull strength ramps from 0 (at magnetRadius) to 8% correction (at snap threshold).
    final t = 1.0 - dist / _kMagnetRadius;
    final pullDir = (piece.targetPosition - piece.currentPosition) / dist;
    return delta + pullDir * (dist * t * 0.08);
  }

  /// Ends the drag without snapping/placing. Used when the piece was dropped
  /// in the wrong position and the view will animate it back, or when it stays
  /// in the tray with momentum.
  void endDragNoPlace() {
    if (draggingIndex == null) return;
    pieces[draggingIndex!]
      ..isDragging = false
      ..scale = 1.0
      ..velocity = _clampVelocity(_dragVelocity);
    draggingIndex = null;
  }

  void endDrag() {
    if (draggingIndex == null) return;
    final piece = pieces[draggingIndex!]
      ..isDragging = false
      ..scale = 1.0;

    const snapThreshold = _kSnapThreshold;
    if ((piece.currentPosition - piece.targetPosition).distance <= snapThreshold) {
      piece
        ..currentPosition = piece.targetPosition
        ..isPlaced = true
        ..isHinted = false
        ..velocity = Offset.zero;
    } else {
      // Not snapped — give the piece momentum.
      piece.velocity = _clampVelocity(_dragVelocity);
    }

    draggingIndex = null;
    notifyListeners();

    if (pieces.every((p) => p.isPlaced)) {
      phase = GamePhase.won;
      notifyListeners();
    }
  }

  /// Advances the physics simulation by [dt] seconds within [trayBounds].
  ///
  /// Returns true if any piece changed state (position or velocity),
  /// so the caller knows whether to schedule a repaint.
  bool stepPhysics(double dt, Rect trayBounds) {
    var changed = false;

    for (final piece in pieces) {
      if (piece.isPlaced || piece.isDragging) continue;

      var vel = piece.velocity;
      var pos = piece.currentPosition;

      // Apply friction (exponential decay).
      vel = vel * (1.0 - _kFriction * dt).clamp(0.0, 1.0);

      // Zero out negligible velocity to avoid perpetual micro-movement.
      if (vel.distance < _kMinVelocity) {
        vel = Offset.zero;
      }

      if (vel != Offset.zero) {
        pos = pos + vel * dt;

        // Bounce off tray walls.
        if (pos.dx < trayBounds.left) {
          pos = Offset(trayBounds.left, pos.dy);
          vel = Offset(-vel.dx * _kBounceDamp, vel.dy);
        }
        if (pos.dx + pieceWidth > trayBounds.right) {
          pos = Offset(trayBounds.right - pieceWidth, pos.dy);
          vel = Offset(-vel.dx * _kBounceDamp, vel.dy);
        }
        if (pos.dy < trayBounds.top) {
          pos = Offset(pos.dx, trayBounds.top);
          vel = Offset(vel.dx, -vel.dy * _kBounceDamp);
        }
        if (pos.dy + pieceHeight > trayBounds.bottom) {
          pos = Offset(pos.dx, trayBounds.bottom - pieceHeight);
          vel = Offset(vel.dx, -vel.dy * _kBounceDamp);
        }

        piece
          ..currentPosition = pos
          ..velocity = vel;
        changed = true;
      } else if (piece.velocity != Offset.zero) {
        // Velocity was reduced to zero — write the zeroed value back.
        piece.velocity = Offset.zero;
        changed = true;
      }
    }

    if (changed) notifyListeners();
    return changed;
  }

  Offset _clampVelocity(Offset vel) {
    final d = vel.distance;
    if (d <= _kMaxVelocity) return vel;
    return vel / d * _kMaxVelocity;
  }

  bool get hasActiveHint => pieces.any((p) => p.isHinted);

  void activateHint() {
    if (hintsRemaining <= 0) return;
    _clearHint();
    // Only hint unplaced, non-dragging pieces.
    final unplaced = pieces
        .where((p) => !p.isPlaced && !p.isDragging)
        .toList();
    if (unplaced.isEmpty) return;
    final rng = Random();
    unplaced[rng.nextInt(unplaced.length)].isHinted = true;
    hintsRemaining--;
    notifyListeners();
  }

  void _clearHint() {
    for (final piece in pieces) {
      piece.isHinted = false;
    }
  }
}
