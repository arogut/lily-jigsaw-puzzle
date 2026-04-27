import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'package:lily_jigsaw_puzzle/models/game_phase.dart';
import 'package:lily_jigsaw_puzzle/models/puzzle_builder.dart';
import 'package:lily_jigsaw_puzzle/models/puzzle_piece.dart';

export 'package:lily_jigsaw_puzzle/models/game_phase.dart';

// ── Physics constants ──────────────────────────────────────────────────────
const double _kLiftScale = 1.08;

/// Distance in logical pixels within which a dropped piece snaps to its slot.
const double kSnapThreshold = 40;

const double _kMagnetRadius = 80;

// Velocity friction: vel *= (1 - _kFriction * dt). Half-life ≈ 0.1 seconds.
const double _kFriction = 6;

// Bounce damping at tray walls.
const double _kBounceDamp = 0.35;

const double _kMaxVelocity = 1500;
const double _kMinVelocity = 5;

// ──────────────────────────────────────────────────────────────────────────

/// Holds the complete mutable state of an in-progress puzzle game.
///
/// Extends [ChangeNotifier] so listeners can react to phase transitions and
/// drag events without polling.
class GameState extends ChangeNotifier {
  /// Creates a [GameState] and immediately initialises pieces from [puzzleImage].
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

  late List<PuzzlePiece> _pieces;

  /// Ordered list of puzzle pieces — rendered and hit-tested back-to-front.
  List<PuzzlePiece> get pieces => _pieces;

  GamePhase _phase = GamePhase.loading;

  /// Current game phase driving active interactions and visible layers.
  GamePhase get phase => _phase;

  int? _draggingIndex;

  /// Index into [pieces] of the piece currently being dragged, or null.
  int? get draggingIndex => _draggingIndex;

  int _hintsRemaining = 3;

  /// Remaining hint activations available to the player.
  int get hintsRemaining => _hintsRemaining;

  late final double pieceWidth;
  late final double pieceHeight;

  // Velocity tracking during drag.
  Offset _dragVelocity = Offset.zero;
  DateTime? _lastDragTime;

  // Raw finger position during drag, tracked independently of magnetic pull.
  Offset _rawDragPosition = Offset.zero;

  void _initialize() {
    final result = PuzzleBuilder.build(
      gridSize: gridSize,
      boardSize: boardSize,
      boardOffset: boardOffset,
    );
    pieceWidth = result.pieceWidth;
    pieceHeight = result.pieceHeight;
    _pieces = result.pieces;
    _phase = GamePhase.assembled;
  }

  /// Called per-frame during scatter animation — bypasses notifyListeners for performance.
  void setPiecePosition(int index, Offset position) {
    _pieces[index].currentPosition = position;
  }

  /// Returns random scatter target positions spread across the right-half tray.
  List<Offset> computeScatterTargets(Size screenSize) {
    final rng = Random();
    const margin = 20.0;
    final trayLeft = screenSize.width / 2 + margin;
    final trayRight = screenSize.width - margin - pieceWidth;
    const trayTop = margin;
    final trayBottom = screenSize.height - margin - pieceHeight;
    return List.generate(_pieces.length, (i) {
      return Offset(
        trayLeft + rng.nextDouble() * (trayRight - trayLeft).clamp(0, double.infinity),
        trayTop + rng.nextDouble() * (trayBottom - trayTop).clamp(0, double.infinity),
      );
    });
  }

  /// Transitions to [GamePhase.scattering].
  ///
  /// Does not notify listeners — the scatter animation drives repaints
  /// directly via the screen's repaint notifier.
  void beginScattering() {
    _phase = GamePhase.scattering;
  }

  /// Transitions to [GamePhase.playing] and notifies listeners.
  void beginPlaying() {
    _phase = GamePhase.playing;
    notifyListeners();
  }

  // ── Drag lifecycle ────────────────────────────────────────────────────────

  /// Lifts [pieces[index]] to the top of the render stack and begins tracking drag.
  void startDrag(int index) {
    _dragVelocity = Offset.zero;
    _lastDragTime = DateTime.now();

    // Move primary piece to end of list so it renders on top.
    final piece = _pieces[index];
    _pieces.remove(piece);
    piece
      ..isDragging = true
      ..scale = _kLiftScale
      ..velocity = Offset.zero;
    _pieces.add(piece);
    _draggingIndex = _pieces.length - 1;
    _rawDragPosition = piece.currentPosition;
    notifyListeners();
  }

  /// Moves the dragged piece by [delta] and applies magnetic pull near its target.
  void updateDrag(Offset delta) {
    if (_draggingIndex == null) return;

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

    _rawDragPosition += delta;
    final piece = _pieces[_draggingIndex!];
    piece.currentPosition =
        _rawDragPosition + _magneticOffset(_rawDragPosition, piece.targetPosition);
    notifyListeners();
  }

  /// Returns the magnetic offset to add to the raw finger position when the
  /// piece is within [_kMagnetRadius] of its target. The offset is zero at the
  /// radius boundary and grows smoothly inward, so there is no discontinuity
  /// when the piece enters or exits the magnet zone.
  Offset _magneticOffset(Offset rawPos, Offset targetPos) {
    final dist = (rawPos - targetPos).distance;
    if (dist <= 0 || dist > _kMagnetRadius) return Offset.zero;

    // Pull strength ramps from 0 (at magnetRadius) to 8% correction (closer in).
    final t = 1.0 - dist / _kMagnetRadius;
    final pullDir = (targetPos - rawPos) / dist;
    return pullDir * (dist * t * 0.08);
  }

  /// Ends the drag without snapping/placing. Used when the piece was dropped
  /// in the wrong position and the view will animate it back, or when it stays
  /// in the tray with momentum.
  void endDragNoPlace() {
    if (_draggingIndex == null) return;
    _pieces[_draggingIndex!]
      ..isDragging = false
      ..scale = 1.0
      ..velocity = _clampVelocity(_dragVelocity);
    _draggingIndex = null;
  }

  /// Ends the drag, snapping the piece into place if within [kSnapThreshold].
  void endDrag() {
    if (_draggingIndex == null) return;
    final piece = _pieces[_draggingIndex!]
      ..isDragging = false
      ..scale = 1.0;

    if ((piece.currentPosition - piece.targetPosition).distance <= kSnapThreshold) {
      piece
        ..currentPosition = piece.targetPosition
        ..isPlaced = true
        ..isHinted = false
        ..velocity = Offset.zero;
    } else {
      // Not snapped — give the piece momentum.
      piece.velocity = _clampVelocity(_dragVelocity);
    }

    _draggingIndex = null;
    notifyListeners();

    if (_pieces.every((p) => p.isPlaced)) {
      _phase = GamePhase.won;
      notifyListeners();
    }
  }

  /// Advances the physics simulation by [dt] seconds within [trayBounds].
  ///
  /// Returns true if any piece changed state (position or velocity),
  /// so the caller knows whether to schedule a repaint.
  bool stepPhysics(double dt, Rect trayBounds) {
    var changed = false;

    for (final piece in _pieces) {
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

  /// True when a hint is currently active (one piece is highlighted).
  bool get hasActiveHint => _pieces.any((p) => p.isHinted);

  /// Highlights a random unplaced piece and decrements [hintsRemaining].
  void activateHint() {
    if (_hintsRemaining <= 0) return;
    _clearHint();
    // Only hint unplaced, non-dragging pieces.
    final unplaced = _pieces
        .where((p) => !p.isPlaced && !p.isDragging)
        .toList();
    if (unplaced.isEmpty) return;
    final rng = Random();
    unplaced[rng.nextInt(unplaced.length)].isHinted = true;
    _hintsRemaining--;
    notifyListeners();
  }

  void _clearHint() {
    for (final piece in _pieces) {
      piece.isHinted = false;
    }
  }
}
