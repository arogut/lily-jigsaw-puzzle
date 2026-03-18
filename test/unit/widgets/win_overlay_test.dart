import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/l10n/app_localizations.dart';
import 'package:lily_jigsaw_puzzle/widgets/win_overlay.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: child),
  );
}

void main() {
  group('WinOverlay', () {
    testWidgets('renders play again and new puzzle buttons', (tester) async {
      await tester.pumpWidget(
        _wrap(WinOverlay(onPlayAgain: () {}, onNewPuzzle: () {})),
      );
      await tester.pump();

      expect(find.byType(WinOverlay), findsOneWidget);
    });

    testWidgets('calls onPlayAgain when play again button tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(WinOverlay(
          onPlayAgain: () => tapped = true,
          onNewPuzzle: () {},
        )),
      );
      await tester.pump();

      // Find and tap the play again button by its icon
      final replayButton = find.byIcon(Icons.replay_rounded);
      expect(replayButton, findsOneWidget);
      await tester.tap(replayButton);
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('calls onNewPuzzle when new puzzle button tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(WinOverlay(
          onPlayAgain: () {},
          onNewPuzzle: () => tapped = true,
        )),
      );
      await tester.pump();

      final homeButton = find.byIcon(Icons.home_rounded);
      expect(homeButton, findsOneWidget);
      await tester.tap(homeButton);
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('shows celebration emoji', (tester) async {
      await tester.pumpWidget(
        _wrap(WinOverlay(onPlayAgain: () {}, onNewPuzzle: () {})),
      );
      await tester.pump();

      expect(find.text('🎉'), findsOneWidget);
    });
  });
}
