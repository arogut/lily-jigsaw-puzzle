import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/core/widgets/puzzle_thumbnail.dart';

Widget _buildThumbnail({
  Color edgeColor = const Color(0xFF336699),
  Widget? overlay,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 200,
        height: 150,
        child: PuzzleThumbnail(
          assetPath: 'assets/images/puzzle-1.jpg',
          cornerRadius: 12,
          edgeColor: edgeColor,
          overlay: overlay,
        ),
      ),
    ),
  );
}

void main() {
  setUp(PuzzleThumbnail.clearCache);

  group('PuzzleThumbnail', () {
    testWidgets('renders without error when edgeColor is supplied', (tester) async {
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

    testWidgets('applies ClipRRect with correct corner radius', (tester) async {
      await tester.pumpWidget(_buildThumbnail());
      final clips = tester.widgetList<ClipRRect>(find.byType(ClipRRect));
      expect(
        clips.any(
          (c) => c.borderRadius == const BorderRadius.all(Radius.circular(12)),
        ),
        isTrue,
      );
    });

    testWidgets('base layer uses the supplied edge colour', (tester) async {
      const testColor = Color(0xFF112233);
      await tester.pumpWidget(_buildThumbnail(edgeColor: testColor));
      final decorated = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
      expect(
        decorated.any((d) => (d.decoration as BoxDecoration).color == testColor),
        isTrue,
      );
    });
  });

  group('PuzzleThumbnail without edgeColor', () {
    testWidgets('renders with gradient decoration when no edgeColor is supplied',
        (tester) async {
      // Does not supply edgeColor — exercises initState → _applyEdgeColor →
      // _computeAndCache (swallows missing-asset error) → setState path, and
      // the gradient BoxDecoration branch inside build().
      //
      // Image.asset also tries to load the same non-existent path and reports
      // an error to FlutterError.onError. Suppress it so the test framework
      // does not treat it as a failure — this test is verifying the gradient
      // decoration, not image-loading behaviour.
      final prevOnError = FlutterError.onError;
      addTearDown(() => FlutterError.onError = prevOnError);
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exception.toString().contains('Unable to load asset')) return;
        prevOnError?.call(details);
      };

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 150,
              child: PuzzleThumbnail(
                assetPath: 'assets/images/does-not-exist.jpg',
                cornerRadius: 8,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PuzzleThumbnail), findsOneWidget);
      // The base layer must use a gradient (not a solid colour) when no
      // edgeColor override is provided.
      final decorations =
          tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
      expect(
        decorations.any((d) => (d.decoration as BoxDecoration).gradient != null),
        isTrue,
      );
    });
  });

  group('prewarm', () {
    testWidgets('completes without error for an empty path list', (_) async {
      await PuzzleThumbnail.prewarm([]);
    });

    testWidgets('completes without error when asset paths are unavailable', (_) async {
      // _computeAndCache swallows exceptions for missing assets, so prewarm
      // must always complete rather than propagating errors to the caller.
      await PuzzleThumbnail.prewarm(['assets/images/does-not-exist.jpg']);
    });

    testWidgets('completes without error when called multiple times for same path', (_) async {
      // Use a missing path so rootBundle.load fails fast rather than hanging
      // during image decode. Tests that repeated calls with the same path
      // never propagate errors to the caller.
      await PuzzleThumbnail.prewarm(['assets/images/does-not-exist.jpg']);
      await PuzzleThumbnail.prewarm(['assets/images/does-not-exist.jpg']);
    });
  });
}
