import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'package:lily_jigsaw_puzzle/core/constants/game_physics.dart';
import 'package:lily_jigsaw_puzzle/core/utils/puzzle_geometry.dart';
import 'package:lily_jigsaw_puzzle/models/game_phase.dart';
import 'package:lily_jigsaw_puzzle/models/hint_slot_state.dart';
import 'package:lily_jigsaw_puzzle/models/puzzle_builder.dart';
import 'package:lily_jigsaw_puzzle/models/puzzle_piece.dart';

export 'package:lily_jigsaw_puzzle/models/game_phase.dart';

/// Distance in logical pixels within which a dropped piece snaps to its slot.
const double kSnapThreshold = GamePhysics.snapThreshold;

/// Holds the complete mutable state of an in-progress puzzle game.
///
/// Extends [ChangeNotifier] so listeners can react to phase transitions and
/// drag events without polling.
class GameState extends ChangeNotifier {
  /// Creates a [GameState] and immediately initialises pieces from [puzzleImage].
  ///
  /// When [immediateMode] is true all three hint slots start as
  /// [HintSlotState.available]; otherwise they start as [HintSlotState.waiting].
  GameState({
    required this.puzzleImage,
    required this.gridSize,
    required this.boardSize,
    this.boardOffset = Offset.zero,
    this.immediateMode = false,
  }) {
    _hintSlots = List.generate(
      3,
      (_) => immediateMode ? HintSlotState.available : HintSlotState.waiting,
    );
    _initialize();
  }

  final ui.Image puzzleImage;
  final int gridSize;
  final Size boardSize;
  final Offset boardOffset;

  /// When true, all hint slots start in [HintSlotState.available].
  final bool immediateMode;

  late List<PuzzlePiece> _pieces;

  /// Ordered list of puzzle pieces — rendered and hit-tested back-to-front.
  List<PuzzlePiece> get pieces => _pieces;

  GamePhase _phase = GamePhase.assembled;

  /// Current game phase driving active interactions and visible layers.
  GamePhase get phase => _phase;

  int? _draggingIndex;

  /// Index into [pieces] of the piece currently being dragged, or null.
  int? get draggingIndex => _draggingIndex;

  late List<HintSlotState> _hintSlots;
  PuzzlePiece? _hintedPiece;

  /// The state of the next available (non-used) hint slot, or null if all used.
  HintSlotState? get currentHintSlot {
    for (final s in _hintSlots) {
      if (s != HintSlotState.used) return s;
    }
    return null;
  }

  /// Index of the currently hinted piece, or null when no hint is active.
  ///
  /// Computed from the piece reference — survives list reordering during drag.
  int? get hintedPieceIndex =>
      _hintedPiece == null ? null : _pieces.indexOf(_hintedPiece!);

  /// True when a hint was used and the highlighted piece has been correctly placed.
  bool get isHintedPiecePlaced => _hintedPiece != null && _hintedPiece!.isPlaced;

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
  List<Offset> computeScatterTargets(Size screenSize) =>
      PuzzleGeometry.randomScatterTargets(
        pieceCount: _pieces.length,
        screenSize: screenSize,
        pieceWidth: pieceWidth,
        pieceHeight: pieceHeight,
      );

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
      ..scale = GamePhysics.liftScale
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
  /// piece is within [GamePhysics.magnetRadius] of its target. The offset is zero at the
  /// radius boundary and grows smoothly inward, so there is no discontinuity
  /// when the piece enters or exits the magnet zone.
  Offset _magneticOffset(Offset rawPos, Offset targetPos) {
    final dist = (rawPos - targetPos).distance;
    if (dist <= 0 || dist > GamePhysics.magnetRadius) return Offset.zero;

    // Pull strength ramps from 0 (at magnetRadius) to 8% correction (closer in).
    final t = 1.0 - dist / GamePhysics.magnetRadius;
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
      vel = vel * (1.0 - GamePhysics.friction * dt).clamp(0.0, 1.0);

      // Zero out negligible velocity to avoid perpetual micro-movement.
      if (vel.distance < GamePhysics.minVelocity) {
        vel = Offset.zero;
      }

      if (vel != Offset.zero) {
        pos = pos + vel * dt;

        // Bounce off tray walls.
        if (pos.dx < trayBounds.left) {
          pos = Offset(trayBounds.left, pos.dy);
          vel = Offset(-vel.dx * GamePhysics.bounceDamp, vel.dy);
        }
        if (pos.dx + pieceWidth > trayBounds.right) {
          pos = Offset(trayBounds.right - pieceWidth, pos.dy);
          vel = Offset(-vel.dx * GamePhysics.bounceDamp, vel.dy);
        }
        if (pos.dy < trayBounds.top) {
          pos = Offset(pos.dx, trayBounds.top);
          vel = Offset(vel.dx, -vel.dy * GamePhysics.bounceDamp);
        }
        if (pos.dy + pieceHeight > trayBounds.bottom) {
          pos = Offset(pos.dx, trayBounds.bottom - pieceHeight);
          vel = Offset(vel.dx, -vel.dy * GamePhysics.bounceDamp);
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
    if (d <= GamePhysics.maxVelocity) return vel;
    return vel / d * GamePhysics.maxVelocity;
  }

  /// True when a hint is currently active (one piece is highlighted).
  bool get hasActiveHint => _pieces.any((p) => p.isHinted);

  /// Transitions the first [HintSlotState.waiting] slot to [HintSlotState.available].
  ///
  /// No-op when no waiting slots remain.
  void markNextSlotAvailable() {
    for (var i = 0; i < _hintSlots.length; i++) {
      if (_hintSlots[i] == HintSlotState.waiting) {
        _hintSlots[i] = HintSlotState.available;
        notifyListeners();
        return;
      }
    }
  }

  /// Activates the first [HintSlotState.available] hint slot: marks it used,
  /// highlights a random unplaced piece, and records it as [_hintedPiece].
  ///
  /// No-op when [currentHintSlot] is not [HintSlotState.available].
  void activateHint() {
    if (currentHintSlot != HintSlotState.available) return;
    // Mark first available slot as used.
    for (var i = 0; i < _hintSlots.length; i++) {
      if (_hintSlots[i] == HintSlotState.available) {
        _hintSlots[i] = HintSlotState.used;
        break;
      }
    }
    _clearHint();
    final unplaced = _pieces
        .where((p) => !p.isPlaced && !p.isDragging)
        .toList();
    if (unplaced.isEmpty) return;
    final rng = Random();
    _hintedPiece = unplaced[rng.nextInt(unplaced.length)]..isHinted = true;
    notifyListeners();
  }

  void _clearHint() {
    for (final piece in _pieces) {
      piece.isHinted = false;
    }
  }
}
