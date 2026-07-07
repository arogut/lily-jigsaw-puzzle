import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lily_jigsaw_puzzle/l10n/app_localizations.dart';
import 'package:lily_jigsaw_puzzle/widgets/parent_gate.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: child),
    );

int? _extractSumFromQuestion(WidgetTester tester) {
  final textWidgets = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .where((s) => s.contains('+'))
      .toList();
  if (textWidgets.isEmpty) return null;
  final match = RegExp(r'(\d+) \+ (\d+)').firstMatch(textWidgets.first);
  if (match == null) return null;
  return int.parse(match.group(1)!) + int.parse(match.group(2)!);
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('ParentGate calls onUnlocked for a correct answer', (tester) async {
    var unlocked = false;

    await tester.pumpWidget(_wrap(ParentGate(onUnlocked: () => unlocked = true)));
    await tester.pump();

    final correctAnswer = _extractSumFromQuestion(tester);
    expect(correctAnswer, isNotNull);

    await tester.enterText(find.byType(TextField), '$correctAnswer');
    await tester.tap(find.text('Confirm'));
    await tester.pump();

    expect(unlocked, isTrue);
  });

  testWidgets('ParentGate shows error for a wrong answer', (tester) async {
    await tester.pumpWidget(_wrap(ParentGate(onUnlocked: () {})));
    await tester.pump();

    await tester.enterText(find.byType(TextField), '999');
    await tester.tap(find.text('Confirm'));
    await tester.pump();

    expect(find.text('Wrong answer!'), findsOneWidget);
  });

  testWidgets('ParentGate regenerates challenge after wrong answer delay', (tester) async {
    await tester.pumpWidget(_wrap(ParentGate(onUnlocked: () {})));
    await tester.pump();

    final firstQuestion = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .firstWhere((s) => s.contains('+'));

    await tester.enterText(find.byType(TextField), '999');
    await tester.tap(find.text('Confirm'));
    await tester.pump();

    expect(find.text('Wrong answer!'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump();

    expect(find.text('Wrong answer!'), findsNothing);
    expect(find.text(firstQuestion), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
  });
}
