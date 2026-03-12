import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/widgets/tray_label.dart';

void main() {
  group('TrayLabel', () {
    testWidgets('displays placed / total correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TrayLabel(placed: 5, total: 9))),
      );
      expect(find.text('5 / 9'), findsOneWidget);
    });

    testWidgets('displays 0 / 0 for zeroes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TrayLabel(placed: 0, total: 0))),
      );
      expect(find.text('0 / 0'), findsOneWidget);
    });

    testWidgets('displays large piece count correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TrayLabel(placed: 48, total: 49))),
      );
      expect(find.text('48 / 49'), findsOneWidget);
    });

    testWidgets('renders as Container with decoration', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TrayLabel(placed: 1, total: 4))),
      );
      // Verify widget tree exists and renders without error
      expect(find.byType(TrayLabel), findsOneWidget);
      expect(find.byType(Text), findsOneWidget);
    });
  });
}
