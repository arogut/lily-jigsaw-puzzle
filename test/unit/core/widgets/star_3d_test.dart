import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/core/app_theme.dart';
import 'package:lily_jigsaw_puzzle/core/widgets/star_3d.dart';

void main() {
  group('Star3d', () {
    testWidgets('renders two stacked star icons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Star3d())),
      );
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(2));
    });

    testWidgets('face star uses gold colour', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Star3d(size: 24))),
      );
      final icons = tester.widgetList<Icon>(find.byIcon(Icons.star_rounded));
      expect(icons.any((i) => i.color == AppColors.gold), isTrue);
    });

    testWidgets('widget height exceeds size to accommodate shadow offset', (tester) async {
      const testSize = 30.0;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: Star3d(size: testSize))),
        ),
      );
      // The Star3d root SizedBox has height = size + _shadowOffset (3.0).
      final box = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(Star3d),
          matching: find.byType(SizedBox),
        ),
      );
      expect(box.height, greaterThan(testSize));
    });

    testWidgets('respects custom size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Star3d(size: 48))),
      );
      final icons = tester.widgetList<Icon>(find.byIcon(Icons.star_rounded));
      expect(icons.every((i) => i.size == 48), isTrue);
    });
  });
}
