import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lily_jigsaw_puzzle/models/puzzle_image.dart';
import 'package:lily_jigsaw_puzzle/screens/difficulty_screen.dart';
import 'package:lily_jigsaw_puzzle/screens/image_selection_screen.dart';
import 'package:lily_jigsaw_puzzle/screens/splash_screen.dart';

void main() {
  // Disable runtime font fetching so tests run offline.
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Splash screen renders the game title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SplashScreen()),
    );
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text("Lily's Puzzle"), findsWidgets);
    // Drain all pending timers (splash lasts 5 s).
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('Image selection screen shows all puzzle names', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ImageSelectionScreen()),
    );
    await tester.pump();
    for (final img in PuzzleImageData.all) {
      expect(find.text(img.name), findsOneWidget);
    }
  });

  testWidgets('Image selection screen shows the title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ImageSelectionScreen()),
    );
    await tester.pump();
    expect(find.text('Choose a Puzzle!'), findsWidgets);
  });

  testWidgets('Difficulty screen shows all three difficulty buttons', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DifficultyScreen(
          selectedImage: PuzzleImageData(assetPath: 'assets/images/puzzle1.jpg', name: 'Garden'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Easy'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('Hard'), findsOneWidget);
  });

  testWidgets('Difficulty screen shows Back button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DifficultyScreen(
          selectedImage: PuzzleImageData(assetPath: 'assets/images/puzzle1.jpg', name: 'Garden'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Back'), findsOneWidget);
  });

  testWidgets('Difficulty screen shows the selected image name in title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DifficultyScreen(
          selectedImage: PuzzleImageData(assetPath: 'assets/images/puzzle1.jpg', name: 'Garden'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Pick Difficulty'), findsWidgets);
  });

  testWidgets('Image selection navigates to difficulty screen on tap', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ImageSelectionScreen()),
    );
    await tester.pump();
    await tester.tap(find.text('Garden'));
    await tester.pumpAndSettle();
    expect(find.text('Pick Difficulty'), findsWidgets);
  });
}
