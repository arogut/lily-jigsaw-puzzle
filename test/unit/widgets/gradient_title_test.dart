import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/widgets/gradient_title.dart';

void main() {
  testWidgets('GradientTitle renders the provided text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GradientTitle(text: 'Hello Puzzle'),
        ),
      ),
    );

    expect(find.text('Hello Puzzle'), findsNWidgets(2));
  });
}
