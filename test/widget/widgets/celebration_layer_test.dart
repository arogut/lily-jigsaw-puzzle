import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/models/celebration_style.dart';
import 'package:lily_jigsaw_puzzle/widgets/celebration_layer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  CelebrationIntensity testIntensity() =>
      CelebrationIntensity.fromStreakWeeks(0);

  Widget wrapLayer(Widget child) => MaterialApp(home: Scaffold(body: child));

  CelebrationLayer buildLayer({
    CelebrationStyleId style = CelebrationStyleId.confetti,
    VoidCallback? onSkip,
    VoidCallback? onAnimationComplete,
  }) {
    return CelebrationLayer(
      style: style,
      intensity: testIntensity(),
      onSkip: onSkip ?? () {},
      onAnimationComplete: onAnimationComplete ?? () {},
    );
  }

  group('CelebrationLayer', () {
    for (final style in CelebrationStyleId.values) {
      testWidgets('renders without throwing for $style', (tester) async {
        await tester.pumpWidget(
          wrapLayer(buildLayer(style: style)),
        );
        await tester.pump();
        expect(find.byType(CelebrationLayer), findsOneWidget);
      });
    }

    testWidgets('disposes animation controller when removed', (tester) async {
      await tester.pumpWidget(
        wrapLayer(buildLayer()),
      );
      await tester.pump();

      await tester.pumpWidget(wrapLayer(const SizedBox()));
      await tester.pump();

      expect(find.byType(CelebrationLayer), findsNothing);
    });

    testWidgets('onSkip fires when layer is tapped', (tester) async {
      var skipped = false;
      await tester.pumpWidget(
        wrapLayer(buildLayer(onSkip: () => skipped = true)),
      );
      await tester.pump();

      await tester.tap(find.byType(CelebrationLayer));
      await tester.pump();

      expect(skipped, isTrue);
    });

    testWidgets('onAnimationComplete fires when animation finishes', (tester) async {
      var completed = false;
      await tester.pumpWidget(
        wrapLayer(buildLayer(onAnimationComplete: () => completed = true)),
      );
      await tester.pump();

      await tester.pump(testIntensity().animationDuration);
      await tester.pump(const Duration(milliseconds: 1));

      expect(completed, isTrue);
    });

    testWidgets('renders without SoundService dependency', (tester) async {
      await tester.pumpWidget(
        wrapLayer(buildLayer()),
      );
      await tester.pump();
      expect(find.byType(CelebrationLayer), findsOneWidget);
    });
  });
}
