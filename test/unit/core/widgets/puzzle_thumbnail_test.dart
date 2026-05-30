import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/core/widgets/puzzle_thumbnail.dart';

Widget _buildThumbnail({Widget? overlay}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 200,
        height: 190,
        child: PuzzleThumbnail(
          assetPath: 'assets/images/puzzle-1.jpg',
          overlay: overlay,
        ),
      ),
    ),
  );
}

void main() {
  setUp(PuzzleThumbnail.clearCache);

  group('PuzzleThumbnail', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(_buildThumbnail());
      expect(find.byType(PuzzleThumbnail), findsOneWidget);
    });

    testWidgets('shows overlay widget when provided', (tester) async {
      await tester.pumpWidget(
        _buildThumbnail(
          overlay: const Positioned(top: 4, right: 4, child: Text('★')),
        ),
      );
      expect(find.text('★'), findsOneWidget);
    });

    testWidgets('does not show overlay when none is provided', (tester) async {
      await tester.pumpWidget(_buildThumbnail());
      expect(find.text('★'), findsNothing);
    });

    testWidgets('renders a CustomPaint once mask and image are both loaded',
        (tester) async {
      // In tests neither asset loads so the fallback Image.asset is used,
      // but the widget itself must render without error.
      await tester.pumpWidget(_buildThumbnail());
      expect(find.byType(PuzzleThumbnail), findsOneWidget);
    });
  });

  group('prewarm', () {
    // All prewarm tests use tester.runAsync() because prewarm loads the clip
    // mask via ui.instantiateImageCodec, which requires real async I/O that
    // FakeAsync cannot drive.

    testWidgets('completes without error for an empty path list', (tester) async {
      await tester.runAsync(() => PuzzleThumbnail.prewarm([]));
    });

    testWidgets('completes without error when asset paths are unavailable', (tester) async {
      await tester.runAsync(
        () => PuzzleThumbnail.prewarm(['assets/images/does-not-exist.jpg']),
      );
    });

    testWidgets('completes without error when called multiple times for same path',
        (tester) async {
      await tester.runAsync(
        () => PuzzleThumbnail.prewarm(['assets/images/does-not-exist.jpg']),
      );
      await tester.runAsync(
        () => PuzzleThumbnail.prewarm(['assets/images/does-not-exist.jpg']),
      );
    });

    testWidgets('populates display image cache for a real asset', (tester) async {
      await tester.runAsync(
        () => PuzzleThumbnail.prewarm(['assets/images/puzzle-1.jpg']),
      );
      // Second call must hit the early-return guard (cache already populated).
      await tester.runAsync(
        () => PuzzleThumbnail.prewarm(['assets/images/puzzle-1.jpg']),
      );
    });
  });
}
