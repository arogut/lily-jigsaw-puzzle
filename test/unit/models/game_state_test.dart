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
}
