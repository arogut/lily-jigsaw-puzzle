import 'package:flutter_test/flutter_test.dart';

import 'package:lily_jigsaw_puzzle/main.dart';

void main() {
  testWidgets('App starts and shows Choose a Puzzle', (WidgetTester tester) async {
    await tester.pumpWidget(const JigsawApp());

    expect(find.text('Choose a Puzzle'), findsOneWidget);
  });
}
