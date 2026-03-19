import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'package:lily_jigsaw_puzzle/models/puzzle_piece.dart';

// ── Physics constants ──────────────────────────────────────────────────────
const double _kLiftScale = 1.08;
const double _kSnapThreshold = 40;
const double _kGroupFormThreshold = 25;
const double _kMagnetRadius = 80;

// Velocity friction: vel *= (1 - _kFriction * dt). Half-life ≈ 1 second.
const double _kFriction = 0.7;

// Gentle gravity for tray pieces (pixels/s²).
const double _kGravity = 20;

// Bounce damping at tray walls.
const double _kBounceDamp = 0.35;

const double _kMaxVelocity = 1500;
const double _kMinVelocity = 5;

// Flip animation speed: progress advances by this per second.
const double _kFlipSpeed = 3;

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

  // Secondary pieces moved together with the primary dragged piece (group).
  final List<PuzzlePiece> _secondaryDragPieces = [];

  // Velocity tracking during drag.
  Offset _dragVelocity = Offset.zero;
  DateTime? _lastDragTime;

  // Monotonically-increasing group ID counter.
  int _nextGroupId = 0;

  // Pieces currently animating a flip.
  final Set<PuzzlePiece> _flippingPieces = {};

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

  /// Computes positions for the pile effect: a tight cluster near the tray centre.
  List<Offset> computePilePositions(Size screenSize) {
    final rng = Random();
    const spread = 30.0;
    final pileCenter = Offset(
      screenSize.width * 0.75 - pieceWidth / 2,
      screenSize.height * 0.5 - pieceHeight / 2,
    );
    return List.generate(pieces.length, (_) {
      return pileCenter + Offset(
        (rng.nextDouble() - 0.5) * spread,
        (rng.nextDouble() - 0.5) * spread,
      );
    });
  }

  /// Applies explosive outward velocities to all unplaced pieces so they scatter
  /// from their current (pile) positions. Called after the scatter animation
  /// places all pieces in the pile.
  void applyScatterVelocities(Size screenSize) {
    final rng = Random();
    final center = Offset(
      screenSize.width * 0.75,
      screenSize.height * 0.5,
    );
    for (final piece in pieces) {
      if (piece.isPlaced) continue;
      final fromCenter = piece.currentPosition - center;
      final dist = fromCenter.distance;
      final Offset dir;
      if (dist > 1) {
        dir = fromCenter / dist;
      } else {
        final angle = rng.nextDouble() * 2 * pi;
        dir = Offset(cos(angle), sin(angle));
      }
      final speed = 350.0 + rng.nextDouble() * 500.0;
      piece.velocity = dir * speed;
    }
  }

  void beginPlaying() {
    phase = GamePhase.playing;
    notifyListeners();
  }

  // ── Drag lifecycle ────────────────────────────────────────────────────────

  void startDrag(int index) {
    _dragVelocity = Offset.zero;
    _lastDragTime = DateTime.now();
    _secondaryDragPieces.clear();

    final piece = pieces[index];
    final groupId = piece.groupId;

    // Collect all other group members (they follow the primary piece).
    if (groupId != null) {
      for (final p in pieces) {
        if (p != piece && p.groupId == groupId && !p.isPlaced) {
          p
            ..isDragging = true
            ..scale = _kLiftScale
            ..velocity = Offset.zero;
          _secondaryDragPieces.add(p);
        }
      }
    }

    // Move primary piece to end of list so it renders on top.
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
    for (final p in _secondaryDragPieces) {
      p.currentPosition = p.currentPosition + adjustedDelta;
    }
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

    for (final p in _secondaryDragPieces) {
      p
        ..isDragging = false
        ..scale = 1.0
        ..velocity = _clampVelocity(_dragVelocity);
    }
    _secondaryDragPieces.clear();
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
        ..velocity = Offset.zero
        ..groupId = null;

      // Snap secondary group members that are close to their targets.
      for (final p in _secondaryDragPieces) {
        p
          ..isDragging = false
          ..scale = 1.0
          ..velocity = Offset.zero;
        if ((p.currentPosition - p.targetPosition).distance <= snapThreshold * 2) {
          p
            ..currentPosition = p.targetPosition
            ..isPlaced = true
            ..isHinted = false
            ..groupId = null;
        }
      }

      // Chain-snap any adjacent unplaced pieces that happen to be close.
      _chainSnap(piece);
    } else {
      // Not snapped — give the piece momentum.
      piece.velocity = _clampVelocity(_dragVelocity);
      for (final p in _secondaryDragPieces) {
        p
          ..isDragging = false
          ..scale = 1.0
          ..velocity = _clampVelocity(_dragVelocity);
      }
    }

    _secondaryDragPieces.clear();
    draggingIndex = null;
    notifyListeners();

    if (pieces.every((p) => p.isPlaced)) {
      phase = GamePhase.won;
      notifyListeners();
    }
  }

  /// Advances the physics simulation by [dt] seconds within [trayBounds].
  ///
  /// Returns true if any piece changed state (position, velocity, or flip),
  /// so the caller knows whether to schedule a repaint.
  bool stepPhysics(double dt, Rect trayBounds) {
    var changed = false;

    for (final piece in pieces) {
      if (piece.isPlaced || piece.isDragging) continue;

      var vel = piece.velocity;
      var pos = piece.currentPosition;

      // Apply gravity during playing phase only (not during explosive scatter).
      if (phase == GamePhase.playing) {
        vel = Offset(vel.dx, vel.dy + _kGravity * dt);
      }

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
      }
    }

    // Advance flip animations.
    for (final piece in _flippingPieces.toList()) {
      piece.flipProgress = (piece.flipProgress + dt * _kFlipSpeed).clamp(0.0, 1.0);
      if (piece.flipProgress >= 1.0) {
        piece.isFaceDown = false;
        _flippingPieces.remove(piece);
      }
      changed = true;
    }

    if (changed) notifyListeners();
    return changed;
  }

  /// Triggers a flip animation for [piece] if it is currently face-down.
  void flipPiece(PuzzlePiece piece) {
    if (!piece.isFaceDown) return;
    piece.flipProgress = 0.0;
    _flippingPieces.add(piece);
    notifyListeners();
  }

  /// Checks whether any unplaced neighbours of [piece] are in the correct
  /// relative position to form a group. Merges them into the same group if so.
  void checkGroupFormation(PuzzlePiece piece) {
    for (final neighbour in _getNeighbours(piece)) {
      final relTarget = neighbour.targetPosition - piece.targetPosition;
      final relActual = neighbour.currentPosition - piece.currentPosition;
      if ((relActual - relTarget).distance <= _kGroupFormThreshold) {
        _mergeGroups(piece, neighbour);
      }
    }
    notifyListeners();
  }

  /// Returns unplaced, non-dragging direct neighbours (up/down/left/right)
  /// of [piece] within the grid.
  List<PuzzlePiece> _getNeighbours(PuzzlePiece piece) {
    return pieces.where((p) {
      if (p.isPlaced || p.isDragging || p == piece) return false;
      return (p.row == piece.row && (p.col - piece.col).abs() == 1) ||
          (p.col == piece.col && (p.row - piece.row).abs() == 1);
    }).toList();
  }

  /// Merges [a] and [b] into the same group, combining any existing groups.
  void _mergeGroups(PuzzlePiece a, PuzzlePiece b) {
    if (a.groupId != null && a.groupId == b.groupId) return;

    final newId = _nextGroupId++;
    final aId = a.groupId;
    final bId = b.groupId;

    for (final p in pieces) {
      if (p == a || (aId != null && p.groupId == aId)) p.groupId = newId;
      if (p == b || (bId != null && p.groupId == bId)) p.groupId = newId;
    }
  }

  /// BFS chain-snap: after a piece snaps, snap any adjacent unplaced pieces
  /// that are also within the snap threshold of their targets.
  void _chainSnap(PuzzlePiece placed) {
    final queue = [placed];
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      for (final neighbour in _getNeighbours(current)) {
        if ((neighbour.currentPosition - neighbour.targetPosition).distance <=
            _kSnapThreshold) {
          neighbour
            ..currentPosition = neighbour.targetPosition
            ..isPlaced = true
            ..isHinted = false
            ..velocity = Offset.zero
            ..groupId = null;
          queue.add(neighbour);
        }
      }
    }
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
    // Only hint face-up, unplaced, non-dragging pieces.
    final unplaced = pieces
        .where((p) => !p.isPlaced && !p.isDragging && !p.isFaceDown)
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
