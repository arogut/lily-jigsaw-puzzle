import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/l10n/app_localizations.dart';
import 'package:lily_jigsaw_puzzle/models/streak_record.dart';
import 'package:lily_jigsaw_puzzle/widgets/win_overlay.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: child),
  );
}

Widget _overlay({
  VoidCallback? onPlayAgain,
  VoidCallback? onNewPuzzle,
  VoidCallback? onDismiss,
  StreakRecord? streakRecord,
}) {
  return WinOverlay(
    onPlayAgain: onPlayAgain ?? () {},
    onNewPuzzle: onNewPuzzle ?? () {},
    onDismiss: onDismiss ?? () {},
    streakRecord: streakRecord,
  );
}

void main() {
  group('WinOverlay', () {
    testWidgets('renders play again and new puzzle buttons', (tester) async {
      await tester.pumpWidget(
        _wrap(_overlay()),
      );
      await tester.pump();

      expect(find.byType(WinOverlay), findsOneWidget);
    });

    testWidgets('calls onPlayAgain when play again button tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(_overlay(
          onPlayAgain: () => tapped = true,
        )),
      );
      await tester.pump();

      final replayButton = find.byIcon(Icons.replay_rounded);
      expect(replayButton, findsOneWidget);
      await tester.tap(replayButton);
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('calls onNewPuzzle when new puzzle button tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(_overlay(
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

    testWidgets('shows fixed celebration emoji', (tester) async {
      await tester.pumpWidget(
        _wrap(_overlay()),
      );
      await tester.pump();

      expect(find.text('🎉'), findsOneWidget);
      expect(find.text('🎈'), findsNothing);
      expect(find.text('🎆'), findsNothing);
      expect(find.text('🏆'), findsNothing);
    });

    testWidgets('given_null_streakRecord_when_rendered_then_no_streak_section', (tester) async {
      await tester.pumpWidget(
        _wrap(_overlay()),
      );
      await tester.pump();

      expect(find.textContaining('Day Streak'), findsNothing,
          reason: 'streak section must not appear when streakRecord is null');
    });

    testWidgets('given_streakRecord_with_zero_streak_when_rendered_then_no_streak_section',
        (tester) async {
      await tester.pumpWidget(
        _wrap(_overlay(streakRecord: StreakRecord.initial())),
      );
      await tester.pump();

      expect(find.textContaining('Day Streak'), findsNothing,
          reason: 'streak section must not appear when currentStreak == 0');
    });

    testWidgets('given_streak_of_5_when_rendered_then_shows_current_streak', (tester) async {
      await tester.pumpWidget(
        _wrap(_overlay(
          streakRecord: const StreakRecord(
            currentStreak: 5,
            longestStreak: 12,
            lastCompletionDate: '2026-06-27',
          ),
        )),
      );
      await tester.pump();

      expect(find.textContaining('5'), findsWidgets,
          reason: 'current streak count must be visible');
      expect(find.textContaining('Day Streak'), findsOneWidget,
          reason: 'streak label must appear when currentStreak > 0');
    });

    testWidgets('given_streak_record_when_rendered_then_shows_longest_streak', (tester) async {
      await tester.pumpWidget(
        _wrap(_overlay(
          streakRecord: const StreakRecord(
            currentStreak: 3,
            longestStreak: 10,
            lastCompletionDate: '2026-06-27',
          ),
        )),
      );
      await tester.pump();

      expect(find.textContaining('10'), findsWidgets,
          reason: 'longest streak must be shown alongside current streak');
    });

    testWidgets('given_streak_of_1_when_rendered_then_streak_section_is_visible',
        (tester) async {
      await tester.pumpWidget(
        _wrap(_overlay(
          streakRecord: const StreakRecord(
            currentStreak: 1,
            longestStreak: 1,
            lastCompletionDate: '2026-06-27',
          ),
        )),
      );
      await tester.pump();

      expect(find.textContaining('Day Streak'), findsOneWidget);
    });

    testWidgets('calls onDismiss when backdrop tapped', (tester) async {
      var dismissed = false;
      await tester.pumpWidget(
        _wrap(_overlay(onDismiss: () => dismissed = true)),
      );
      await tester.pump();

      await tester.tapAt(const Offset(10, 10));
      await tester.pump();

      expect(dismissed, isTrue);
    });
  });
}
