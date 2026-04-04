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
}
