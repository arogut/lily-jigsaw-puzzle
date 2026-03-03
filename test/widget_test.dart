import 'package:flutter_test/flutter_test.dart';

import 'package:lily_jigsaw_puzzle/main.dart';

void main() {
  testWidgets('App starts and shows puzzle image selection grid', (WidgetTester tester) async {
    await tester.pumpWidget(const JigsawApp());

    // The image selection screen shows puzzle names as labels in the grid.
    // 'Garden' is the first entry in PuzzleImageData.all.
    expect(find.text('Garden'), findsOneWidget);
  });
}
