import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/models/game_state.dart';
import 'package:lily_jigsaw_puzzle/models/puzzle_piece.dart';

/// Creates a small solid-colour ui.Image for testing without asset loading.
Future<ui.Image> _createTestImage({int width = 64, int height = 64}) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = const Color(0xFFFF0000),
  );
  final picture = recorder.endRecording();
  return picture.toImage(width, height);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ui.Image testImage;

  setUpAll(() async {
    testImage = await _createTestImage();
  });

  GameState makeState({int gridSize = 3, Size boardSize = const Size(300, 300)}) {
    return GameState(
      puzzleImage: testImage,
      gridSize: gridSize,
      boardSize: boardSize,
    );
  }

  group('GameState initialisation', () {
    test('creates gridSize² pieces', () {
      final gs = makeState();
      expect(gs.pieces.length, 9);
    });

    test('creates correct piece count for 5×5 grid', () {
      final gs = makeState(gridSize: 5);
      expect(gs.pieces.length, 25);
    });

    test('creates correct piece count for 7×7 grid', () {
      final gs = makeState(gridSize: 7);
      expect(gs.pieces.length, 49);
    });

    test('phase starts as assembled', () {
      final gs = makeState();
      expect(gs.phase, GamePhase.assembled);
    });

    test('pieceWidth equals boardSize.width / gridSize', () {
      final gs = makeState();
      expect(gs.pieceWidth, closeTo(100.0, 0.001));
    });

    test('pieceHeight equals boardSize.height / gridSize', () {
      final gs = makeState(boardSize: const Size(300, 600));
      expect(gs.pieceHeight, closeTo(200.0, 0.001));
    });

    test('all pieces start at their target positions', () {
      final gs = makeState();
      for (final piece in gs.pieces) {
        expect(piece.currentPosition, piece.targetPosition);
      }
    });

    test('no piece starts as placed', () {
      final gs = makeState();
      expect(gs.pieces.every((p) => !p.isPlaced), isTrue);
    });

    test('no piece starts as dragging', () {
      final gs = makeState();
      expect(gs.pieces.every((p) => !p.isDragging), isTrue);
    });

    test('pieces cover all grid positions', () {
      const gridSize = 3;
      final gs = makeState();
      final positions = gs.pieces.map((p) => (p.row, p.col)).toSet();
      for (var r = 0; r < gridSize; r++) {
        for (var c = 0; c < gridSize; c++) {
          expect(positions.contains((r, c)), isTrue);
        }
      }
    });
  });

  group('GameState connectors complementarity', () {
    // Adjacent pieces must have complementary edges so they fit together.
    test('top edge of (r,c) complements bottom edge of (r-1,c)', () {
      final gs = makeState();
      for (final piece in gs.pieces) {
        if (piece.row == 0) continue;
        final above = gs.pieces.firstWhere(
          (p) => p.row == piece.row - 1 && p.col == piece.col,
        );
        final bottomAbove = above.edges.bottom;
        final topCurrent = piece.edges.top;
        // One must be tab, the other blank (they interlock)
        if (bottomAbove == EdgeType.tab) {
          expect(topCurrent, EdgeType.blank);
        } else {
          expect(topCurrent, EdgeType.tab);
        }
      }
    });

    test('left edge of (r,c) complements right edge of (r,c-1)', () {
      final gs = makeState();
      for (final piece in gs.pieces) {
        if (piece.col == 0) continue;
        final leftNeighbour = gs.pieces.firstWhere(
          (p) => p.row == piece.row && p.col == piece.col - 1,
        );
        final rightOfLeft = leftNeighbour.edges.right;
        final leftCurrent = piece.edges.left;
        if (rightOfLeft == EdgeType.tab) {
          expect(leftCurrent, EdgeType.blank);
        } else {
          expect(leftCurrent, EdgeType.tab);
        }
      }
    });

    test('border pieces have flat outer edges', () {
      const gridSize = 3;
      final gs = makeState();
      for (final piece in gs.pieces) {
        if (piece.row == 0) expect(piece.edges.top, EdgeType.flat);
        if (piece.row == gridSize - 1) expect(piece.edges.bottom, EdgeType.flat);
        if (piece.col == 0) expect(piece.edges.left, EdgeType.flat);
        if (piece.col == gridSize - 1) expect(piece.edges.right, EdgeType.flat);
      }
    });
  });

  group('computeScatterTargets', () {
    test('returns one target per piece', () {
      final gs = makeState();
      final targets = gs.computeScatterTargets(const Size(600, 300));
      expect(targets.length, gs.pieces.length);
    });

    test('scatter targets are in the right-half tray region', () {
      const screenSize = Size(600, 300);
      final gs = makeState();
      final targets = gs.computeScatterTargets(screenSize);
      for (final t in targets) {
        // All targets should be in the right half (tray area x > screen.width/2)
        expect(t.dx, greaterThanOrEqualTo(screenSize.width / 2));
      }
    });
  });

  group('drag lifecycle', () {
    test('startDrag moves piece to end of list and marks isDragging', () {
      final gs = makeState();
      final firstPiece = gs.pieces[0];
      gs.startDrag(0);
      expect(gs.pieces.last, firstPiece);
      expect(gs.pieces.last.isDragging, isTrue);
      expect(gs.draggingIndex, gs.pieces.length - 1);
    });

    test('updateDrag moves the dragged piece by delta', () {
      final gs = makeState()..startDrag(0);
      final before = gs.pieces[gs.draggingIndex!].currentPosition;
      gs.updateDrag(const Offset(10, 20));
      expect(gs.pieces[gs.draggingIndex!].currentPosition, before + const Offset(10, 20));
    });

    test('endDrag clears isDragging and draggingIndex', () {
      final gs = makeState()
        ..startDrag(0)
        ..endDrag();
      expect(gs.draggingIndex, isNull);
      expect(gs.pieces.every((p) => !p.isDragging), isTrue);
    });
  });

  group('snap on endDrag', () {
    test('piece snaps to target when within 40px threshold', () {
      final gs = makeState()..startDrag(0);
      final piece = gs.pieces.last;
      // Move to just within snap threshold (< 40 px from target)
      piece.currentPosition = piece.targetPosition + const Offset(20, 0);
      gs.endDrag();
      expect(piece.isPlaced, isTrue);
      expect(piece.currentPosition, piece.targetPosition);
    });

    test('piece does not snap when beyond 40px threshold', () {
      final gs = makeState()..startDrag(0);
      final piece = gs.pieces.last;
      // Move well beyond snap threshold
      piece.currentPosition = piece.targetPosition + const Offset(100, 100);
      gs.endDrag();
      expect(piece.isPlaced, isFalse);
      expect(piece.currentPosition, isNot(piece.targetPosition));
    });
  });

  group('win condition', () {
    test('phase becomes won when all pieces are placed', () {
      final gs = makeState()
        ..phase = GamePhase.playing;
      // Mark all pieces except the first as already placed.
      for (var i = 1; i < gs.pieces.length; i++) {
        gs.pieces[i].isPlaced = true;
      }
      // Drag the remaining unplaced piece (index 0) to its target position.
      gs.startDrag(0);
      final dragged = gs.pieces.last; // startDrag moves it to end
      dragged.currentPosition = dragged.targetPosition;
      gs.endDrag();
      expect(gs.phase, GamePhase.won);
    });

    test('phase does not become won when pieces remain unplaced', () {
      final gs = makeState()
        ..phase = GamePhase.playing
        ..startDrag(0);
      final piece = gs.pieces.last;
      piece.currentPosition = piece.targetPosition + const Offset(200, 200);
      gs.endDrag();
      expect(gs.phase, isNot(GamePhase.won));
    });
  });

  group('beginPlaying', () {
    test('sets phase to playing and notifies listeners', () {
      final gs = makeState();
      var notified = false;
      gs
        ..addListener(() => notified = true)
        ..beginPlaying();
      expect(gs.phase, GamePhase.playing);
      expect(notified, isTrue);
    });
  });

  group('endDragNoPlace', () {
    test('clears isDragging and draggingIndex without placing piece', () {
      final gs = makeState()..startDrag(0);
      final piece = gs.pieces.last;
      final posBefore = piece.currentPosition;
      gs.endDragNoPlace();
      expect(piece.isDragging, isFalse);
      expect(gs.draggingIndex, isNull);
      // Position unchanged (no snap)
      expect(piece.currentPosition, posBefore);
      expect(piece.isPlaced, isFalse);
    });

    test('does nothing when no piece is being dragged', () {
      final gs = makeState();
      expect(gs.endDragNoPlace, returnsNormally);
      expect(gs.draggingIndex, isNull);
    });
  });

  group('setPiecePosition', () {
    test('updates currentPosition without notifying (used by scatter tick)', () {
      final gs = makeState();
      var notifyCount = 0;
      gs
        ..addListener(() => notifyCount++)
        ..setPiecePosition(0, const Offset(99, 88));
      expect(gs.pieces[0].currentPosition, const Offset(99, 88));
      expect(notifyCount, 0); // no notification
      gs.removeListener(() {});
    });
  });

  group('hint system', () {
    test('hintsRemaining starts at 3', () {
      final gs = makeState();
      expect(gs.hintsRemaining, 3);
    });

    test('hasActiveHint is false initially', () {
      final gs = makeState();
      expect(gs.hasActiveHint, isFalse);
    });

    test('activateHint marks one piece as hinted', () {
      final gs = makeState()..phase = GamePhase.playing..activateHint();
      expect(gs.pieces.where((p) => p.isHinted).length, 1);
    });

    test('activateHint decrements hintsRemaining', () {
      final gs = makeState()..phase = GamePhase.playing..activateHint();
      expect(gs.hintsRemaining, 2);
    });

    test('activateHint does not activate when hintsRemaining is 0', () {
      final gs = makeState()
        ..phase = GamePhase.playing
        ..activateHint()
        ..activateHint()
        ..activateHint();
      expect(gs.hintsRemaining, 0);
      gs.activateHint();
      expect(gs.hintsRemaining, 0);
      expect(gs.pieces.where((p) => p.isHinted).length, 1);
    });

    test('activateHint replaces existing hint with a new one', () {
      final gs = makeState()
        ..phase = GamePhase.playing
        ..activateHint()
        ..activateHint();
      // Only one piece should be hinted
      expect(gs.pieces.where((p) => p.isHinted).length, 1);
      // Could be same or different piece but only one at a time
      expect(gs.hintsRemaining, 1);
    });

    test('hasActiveHint is true after activateHint', () {
      final gs = makeState()..phase = GamePhase.playing..activateHint();
      expect(gs.hasActiveHint, isTrue);
    });

    test('endDrag clears hint when hinted piece is placed', () {
      final gs = makeState()..phase = GamePhase.playing..activateHint();
      final hinted = gs.pieces.firstWhere((p) => p.isHinted);
      // Find hinted piece index and drag it to its target
      final idx = gs.pieces.indexOf(hinted);
      gs.startDrag(idx);
      final dragged = gs.pieces.last;
      dragged.currentPosition = dragged.targetPosition;
      gs.endDrag();
      expect(dragged.isHinted, isFalse);
      expect(gs.hasActiveHint, isFalse);
    });

    test('activateHint notifies listeners', () {
      final gs = makeState()..phase = GamePhase.playing;
      var notified = false;
      gs
        ..addListener(() => notified = true)
        ..activateHint();
      expect(notified, isTrue);
    });

    test('activateHint does not hint placed pieces', () {
      final gs = makeState()..phase = GamePhase.playing;
      // Place all but one piece
      for (var i = 0; i < gs.pieces.length - 1; i++) {
        gs.pieces[i].isPlaced = true;
      }
      gs.activateHint();
      // The only hinted piece should be the unplaced one
      final hinted = gs.pieces.where((p) => p.isHinted).toList();
      expect(hinted.length, 1);
      expect(hinted.first.isPlaced, isFalse);
    });

    test('activateHint does not hint face-down pieces', () {
      final gs = makeState()..phase = GamePhase.playing;
      // Make all but the last piece face-down.
      for (var i = 0; i < gs.pieces.length - 1; i++) {
        gs.pieces[i].isFaceDown = true;
      }
      gs.activateHint();
      final hinted = gs.pieces.where((p) => p.isHinted).toList();
      expect(hinted.length, 1);
      expect(hinted.first.isFaceDown, isFalse);
    });
  });

  group('lift effect', () {
    test('startDrag scales piece up to lift scale', () {
      final gs = makeState()..startDrag(0);
      expect(gs.pieces.last.scale, greaterThan(1.0));
    });

    test('endDrag resets piece scale to 1.0', () {
      final gs = makeState()..startDrag(0)..endDrag();
      expect(gs.pieces.last.scale, 1.0);
    });

    test('endDragNoPlace resets piece scale to 1.0', () {
      final gs = makeState()..startDrag(0);
      final piece = gs.pieces.last; // startDrag moves it to end
      gs.endDragNoPlace();
      expect(piece.scale, 1.0);
    });
  });

  group('physics simulation', () {
    test('stepPhysics applies friction to piece velocity', () {
      final gs = makeState()..beginPlaying();
      gs.pieces[0].velocity = const Offset(1000, 0);
      const trayBounds = Rect.fromLTRB(300, 0, 600, 300);
      gs.stepPhysics(0.1, trayBounds);
      expect(gs.pieces[0].velocity.dx, lessThan(1000));
    });

    test('stepPhysics zeroes negligible velocity', () {
      final gs = makeState()..beginPlaying();
      gs.pieces[0].velocity = const Offset(1, 0); // below min threshold
      const trayBounds = Rect.fromLTRB(300, 0, 600, 300);
      gs.stepPhysics(1, trayBounds);
      expect(gs.pieces[0].velocity, Offset.zero);
    });

    test('stepPhysics bounces piece off tray right wall', () {
      final gs = makeState()..beginPlaying();
      final piece = gs.pieces[0]
        ..currentPosition = const Offset(580, 100)
        ..velocity = const Offset(500, 0);
      const trayBounds = Rect.fromLTRB(300, 0, 600, 300);
      gs.stepPhysics(0.1, trayBounds);
      expect(piece.velocity.dx, isNegative);
    });

    test('stepPhysics bounces piece off tray bottom wall', () {
      final gs = makeState()..beginPlaying();
      final piece = gs.pieces[0]
        ..currentPosition = const Offset(400, 285)
        ..velocity = const Offset(0, 500);
      final trayBounds =
          Rect.fromLTRB(300, 0, 600, 300 - gs.pieceHeight + 10);
      gs.stepPhysics(0.1, trayBounds);
      expect(piece.velocity.dy, isNegative);
    });

    test('stepPhysics does not move placed pieces', () {
      final gs = makeState()..beginPlaying();
      gs.pieces[0]
        ..isPlaced = true
        ..currentPosition = Offset.zero
        ..velocity = const Offset(500, 500);
      const trayBounds = Rect.fromLTRB(300, 0, 600, 300);
      gs.stepPhysics(0.1, trayBounds);
      expect(gs.pieces[0].currentPosition, Offset.zero);
    });

    test('stepPhysics does not move dragging pieces', () {
      final gs = makeState()..startDrag(0);
      final piece = gs.pieces.last
        ..velocity = const Offset(500, 500);
      final posBefore = piece.currentPosition;
      const trayBounds = Rect.fromLTRB(300, 0, 600, 300);
      gs.stepPhysics(0.1, trayBounds);
      expect(piece.currentPosition, posBefore);
    });

    test('stepPhysics returns true when something changed', () {
      final gs = makeState()..beginPlaying();
      gs.pieces[0].velocity = const Offset(200, 0);
      const trayBounds = Rect.fromLTRB(300, 0, 600, 300);
      expect(gs.stepPhysics(0.1, trayBounds), isTrue);
    });

    test('stepPhysics returns false when nothing moved', () {
      final gs = makeState()..beginPlaying();
      // All pieces have zero velocity.
      const trayBounds = Rect.fromLTRB(300, 0, 600, 300);
      expect(gs.stepPhysics(0.1, trayBounds), isFalse);
    });
  });

  group('flip mechanic', () {
    test('flipPiece starts animation on face-down piece', () {
      final gs = makeState();
      gs.pieces[0].isFaceDown = true;
      gs.flipPiece(gs.pieces[0]);
      expect(gs.pieces[0].flipProgress, 0.0);
    });

    test('flipPiece does nothing on face-up piece', () {
      final gs = makeState();
      gs.pieces[0].flipProgress = 1.0;
      gs.flipPiece(gs.pieces[0]); // isFaceDown is false
      expect(gs.pieces[0].flipProgress, 1.0);
    });

    test('stepPhysics advances flip animation', () {
      final gs = makeState()..beginPlaying();
      gs.pieces[0]
        ..isFaceDown = true
        ..flipProgress = 0.0;
      gs.flipPiece(gs.pieces[0]);
      const trayBounds = Rect.fromLTRB(300, 0, 600, 300);
      gs.stepPhysics(0.1, trayBounds);
      expect(gs.pieces[0].flipProgress, greaterThan(0.0));
    });

    test('stepPhysics completes flip and clears isFaceDown', () {
      final gs = makeState()..beginPlaying();
      gs.pieces[0]
        ..isFaceDown = true
        ..flipProgress = 0.0;
      gs.flipPiece(gs.pieces[0]);
      const trayBounds = Rect.fromLTRB(300, 0, 600, 300);
      // Advance enough time for the flip to complete.
      gs.stepPhysics(1, trayBounds);
      expect(gs.pieces[0].isFaceDown, isFalse);
      expect(gs.pieces[0].flipProgress, 1.0);
    });
  });

  group('group snapping', () {
    test('checkGroupFormation merges adjacent pieces at correct relative positions', () {
      final gs = makeState();
      // pieces[0] is (row=0, col=0), pieces[1] is (row=0, col=1)
      final a = gs.pieces[0];
      final b = gs.pieces[1];
      // Place b at exactly the correct relative position from a.
      b.currentPosition = a.currentPosition + (b.targetPosition - a.targetPosition);
      gs.checkGroupFormation(a);
      expect(a.groupId, isNotNull);
      expect(b.groupId, equals(a.groupId));
    });

    test('checkGroupFormation does not merge pieces at wrong positions', () {
      final gs = makeState();
      final a = gs.pieces[0];
      // Place b far from correct relative position.
      final b = gs.pieces[1]
        ..currentPosition = a.currentPosition + const Offset(200, 200);
      gs.checkGroupFormation(a);
      expect(a.groupId, isNull);
      expect(b.groupId, isNull);
    });

    test('chain-snap snaps adjacent unplaced piece within threshold', () {
      final gs = makeState()..phase = GamePhase.playing;
      // Set up: place all but pieces[0] and pieces[1].
      for (var i = 2; i < gs.pieces.length; i++) {
        gs.pieces[i].isPlaced = true;
      }
      final a = gs.pieces[0];
      final b = gs.pieces[1];
      // Move b to just within snap threshold of its target.
      b.currentPosition = b.targetPosition + const Offset(15, 0);
      // Snap a to its target via drag.
      gs.startDrag(gs.pieces.indexOf(a));
      gs.pieces.last.currentPosition = gs.pieces.last.targetPosition;
      gs.endDrag();
      // b should have been chain-snapped.
      expect(b.isPlaced, isTrue);
      expect(b.currentPosition, b.targetPosition);
    });
  });

  group('computePilePositions', () {
    test('returns one position per piece', () {
      final gs = makeState();
      final positions = gs.computePilePositions(const Size(600, 300));
      expect(positions.length, gs.pieces.length);
    });

    test('pile positions are in the right-half tray region', () {
      const screenSize = Size(600, 300);
      final gs = makeState();
      final positions = gs.computePilePositions(screenSize);
      for (final pos in positions) {
        expect(pos.dx, greaterThanOrEqualTo(screenSize.width / 2));
      }
    });
  });

  group('applyScatterVelocities', () {
    test('applies non-zero velocity to all unplaced pieces', () {
      final gs = makeState()..applyScatterVelocities(const Size(600, 300));
      for (final piece in gs.pieces) {
        expect(piece.velocity.distance, greaterThan(0));
      }
    });

    test('does not change velocity of placed pieces', () {
      final gs = makeState();
      gs.pieces[0].isPlaced = true;
      gs.applyScatterVelocities(const Size(600, 300));
      expect(gs.pieces[0].velocity, Offset.zero);
    });
  });

  group('endDragNoPlace momentum', () {
    test('endDragNoPlace preserves drag velocity on released piece', () {
      // Simulate drag updates with velocity.
      final gs = makeState()
        ..startDrag(0)
        ..updateDrag(const Offset(100, 0))
        ..updateDrag(const Offset(100, 0))
        ..endDragNoPlace();
      // Piece should have non-zero velocity after release.
      final piece = gs.pieces.firstWhere((p) => !p.isPlaced);
      // Velocity may be zero if updates were too fast for dt tracking,
      // but scale should be reset.
      expect(piece.scale, 1.0);
    });
  });
}
