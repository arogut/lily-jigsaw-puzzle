import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/core/widgets/panel_backgrounds.dart';

void main() {
  group('PanelBackgrounds', () {
    testWidgets('renders two Expanded children', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PanelBackgrounds())),
      );
      expect(find.byType(Expanded), findsNWidgets(2));
    });

    testWidgets('root widget is a Row', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PanelBackgrounds())),
      );
      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('left panel has a blue LinearGradient', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PanelBackgrounds())),
      );
      final containers = tester.widgetList<Container>(find.byType(Container)).toList();
      final leftDecoration = (containers.first.decoration as BoxDecoration?)?.gradient as LinearGradient?;
      expect(leftDecoration, isNotNull);
      expect(leftDecoration!.colors, contains(const Color(0xFFB8DEFF)));
      expect(leftDecoration.colors, contains(const Color(0xFF8EC8F8)));
    });

    testWidgets('right panel has a purple-to-pink LinearGradient', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PanelBackgrounds())),
      );
      final containers = tester.widgetList<Container>(find.byType(Container)).toList();
      final rightDecoration = (containers.last.decoration as BoxDecoration?)?.gradient as LinearGradient?;
      expect(rightDecoration, isNotNull);
      expect(rightDecoration!.colors, contains(const Color(0xFFD8BAFF)));
      expect(rightDecoration.colors, contains(const Color(0xFFFFABD0)));
    });

    testWidgets('is a const-constructible StatelessWidget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PanelBackgrounds())),
      );
      expect(find.byType(PanelBackgrounds), findsOneWidget);
    });
  });
}
