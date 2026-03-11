import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/models/puzzle_piece.dart';
import 'package:lily_jigsaw_puzzle/painters/jigsaw_piece_painter.dart';

void main() {
  group('JigsawPiecePainter.buildPiecePath', () {
    const pw = 100.0;
    const ph = 100.0;

    test('returns a non-empty path for all-flat edges', () {
      final path = JigsawPiecePainter.buildPiecePath(
        const PieceEdges(
          top: EdgeType.flat,
          right: EdgeType.flat,
          bottom: EdgeType.flat,
          left: EdgeType.flat,
        ),
        pw,
        ph,
      );
      expect(path.getBounds().isEmpty, isFalse);
    });

    test('bounding rect includes tab margins for all-flat piece', () {
      final path = JigsawPiecePainter.buildPiecePath(
        const PieceEdges(
          top: EdgeType.flat,
          right: EdgeType.flat,
          bottom: EdgeType.flat,
          left: EdgeType.flat,
        ),
        pw,
        ph,
      );
      final bounds = path.getBounds();
      // The body sits at (tabW, tabH) and the canvas is (pw+2*tabW, ph+2*tabH)
      const tabW = pw * JigsawPiecePainter.tabFraction;
      const tabH = ph * JigsawPiecePainter.tabFraction;
      expect(bounds.left, closeTo(tabW, 0.1));
      expect(bounds.top, closeTo(tabH, 0.1));
      expect(bounds.right, closeTo(tabW + pw, 0.1));
      expect(bounds.bottom, closeTo(tabH + ph, 0.1));
    });

    test('tab edge extends beyond the flat baseline', () {
      final pathTab = JigsawPiecePainter.buildPiecePath(
        const PieceEdges(
          top: EdgeType.tab,
          right: EdgeType.flat,
          bottom: EdgeType.flat,
          left: EdgeType.flat,
        ),
        pw,
        ph,
      );
      final pathFlat = JigsawPiecePainter.buildPiecePath(
        const PieceEdges(
          top: EdgeType.flat,
          right: EdgeType.flat,
          bottom: EdgeType.flat,
          left: EdgeType.flat,
        ),
        pw,
        ph,
      );
      // Top tab extends ABOVE the flat top edge → smaller top value
      expect(pathTab.getBounds().top, lessThan(pathFlat.getBounds().top));
      // But the path is still within the canvas including the tab area
      expect(pathTab.getBounds().top, greaterThanOrEqualTo(0));
    });

    test('blank edge does not extend the bounding box beyond the flat baseline', () {
      // Blank edges create a concave indent — they go inward, not outward.
      // The bounding box therefore stays the same as a flat edge (the path
      // starts and ends at the baseline corners regardless of concavity).
      final pathBlank = JigsawPiecePainter.buildPiecePath(
        const PieceEdges(
          top: EdgeType.blank,
          right: EdgeType.flat,
          bottom: EdgeType.flat,
          left: EdgeType.flat,
        ),
        pw,
        ph,
      );
      final pathFlat = JigsawPiecePainter.buildPiecePath(
        const PieceEdges(
          top: EdgeType.flat,
          right: EdgeType.flat,
          bottom: EdgeType.flat,
          left: EdgeType.flat,
        ),
        pw,
        ph,
      );
      // Blank top does NOT extend above the flat top boundary.
      expect(pathBlank.getBounds().top, greaterThanOrEqualTo(pathFlat.getBounds().top));
      // The blank path is still non-empty and has the same right/bottom extent.
      expect(pathBlank.getBounds().right, closeTo(pathFlat.getBounds().right, 0.5));
      expect(pathBlank.getBounds().bottom, closeTo(pathFlat.getBounds().bottom, 0.5));
    });

    test('tab and blank edges produce different paths', () {
      final pathTab = JigsawPiecePainter.buildPiecePath(
        const PieceEdges(
          top: EdgeType.tab,
          right: EdgeType.flat,
          bottom: EdgeType.flat,
          left: EdgeType.flat,
        ),
        pw,
        ph,
      );
      final pathBlank = JigsawPiecePainter.buildPiecePath(
        const PieceEdges(
          top: EdgeType.blank,
          right: EdgeType.flat,
          bottom: EdgeType.flat,
          left: EdgeType.flat,
        ),
        pw,
        ph,
      );
      expect(pathTab.getBounds(), isNot(pathBlank.getBounds()));
    });

    test('path is valid for all four tab positions', () {
      for (final edges in [
        const PieceEdges(top: EdgeType.tab, right: EdgeType.flat, bottom: EdgeType.flat, left: EdgeType.flat),
        const PieceEdges(top: EdgeType.flat, right: EdgeType.tab, bottom: EdgeType.flat, left: EdgeType.flat),
        const PieceEdges(top: EdgeType.flat, right: EdgeType.flat, bottom: EdgeType.tab, left: EdgeType.flat),
        const PieceEdges(top: EdgeType.flat, right: EdgeType.flat, bottom: EdgeType.flat, left: EdgeType.tab),
      ]) {
        final path = JigsawPiecePainter.buildPiecePath(edges, pw, ph);
        expect(path.getBounds().isEmpty, isFalse);
      }
    });

    test('path is valid for fully-interlocked interior piece (all tab/blank)', () {
      final path = JigsawPiecePainter.buildPiecePath(
        const PieceEdges(
          top: EdgeType.blank,
          right: EdgeType.tab,
          bottom: EdgeType.tab,
          left: EdgeType.blank,
        ),
        pw,
        ph,
      );
      expect(path.getBounds().isEmpty, isFalse);
    });

    test('tabFraction constant is in a sensible range', () {
      expect(JigsawPiecePainter.tabFraction, greaterThan(0.1));
      expect(JigsawPiecePainter.tabFraction, lessThan(0.5));
    });
  });
}
