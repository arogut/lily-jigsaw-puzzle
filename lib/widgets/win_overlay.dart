import 'package:flutter/material.dart';
import 'package:lily_jigsaw_puzzle/core/app_theme.dart';
import 'package:lily_jigsaw_puzzle/l10n/app_localizations.dart';
import 'package:lily_jigsaw_puzzle/models/streak_record.dart';
import 'package:lily_jigsaw_puzzle/widgets/game_button.dart';
import 'package:lily_jigsaw_puzzle/widgets/gradient_title.dart';

/// Overlay shown when the player completes the puzzle.
///
/// Displays a fixed 🎉 celebration message, the win title, and action buttons
/// for replaying or returning home.
class WinOverlay extends StatelessWidget {
  const WinOverlay({
    required this.onPlayAgain,
    required this.onNewPuzzle,
    required this.onDismiss,
    this.streakRecord,
    super.key,
  });

  /// Called when the player taps "Play Again".
  final VoidCallback onPlayAgain;

  /// Called when the player taps "New Puzzle".
  final VoidCallback onNewPuzzle;

  /// Called when the player taps the overlay backdrop to dismiss.
  final VoidCallback onDismiss;

  /// Streak data to display after a puzzle is won.
  /// When `null` or [StreakRecord.currentStreak] is zero, no streak section is shown.
  final StreakRecord? streakRecord;

  static const Color _accentColor = AppColors.pastelPink;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenH = MediaQuery.of(context).size.height;
    final compact = screenH < 500;

    final hPad = compact ? 24.0 : 40.0;
    final vPad = compact ? 18.0 : 36.0;
    final emojiFontSize = compact ? 40.0 : 72.0;
    final titleFontSize = compact ? 24.0 : 34.0;
    final subtitleFontSize = compact ? 13.0 : 16.0;
    final gap = compact ? 6.0 : 10.0;
    final subtitleGap = compact ? 4.0 : 8.0;
    final btnGap = compact ? 16.0 : 28.0;
    const accent = _accentColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onDismiss,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xBB000040), Color(0xBB000020)],
          ),
        ),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.alphaBlend(accent.withValues(alpha: 0.08), Colors.white),
                    Color.alphaBlend(accent.withValues(alpha: 0.15), const Color(0xFFFFEEFF)),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.50),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: accent.withValues(alpha: 0.50),
                  width: 2.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🎉', style: TextStyle(fontSize: emojiFontSize)),
                  SizedBox(height: gap),
                  GradientTitle(text: l10n.youDidIt, fontSize: titleFontSize),
                  SizedBox(height: subtitleGap),
                  Text(
                    l10n.puzzleComplete,
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      fontWeight: FontWeight.w600,
                      color: AppColors.deepPurple.withValues(alpha: 0.70),
                    ),
                  ),
                  if (streakRecord != null && streakRecord!.currentStreak > 0) ...[
                    SizedBox(height: subtitleGap),
                    Text(
                      l10n.streakDays(streakRecord!.currentStreak),
                      style: TextStyle(
                        fontSize: compact ? 16.0 : 20.0,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                    Text(
                      l10n.streakBest(streakRecord!.longestStreak),
                      style: TextStyle(
                        fontSize: compact ? 12.0 : 14.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.deepPurple.withValues(alpha: 0.60),
                      ),
                    ),
                  ],
                  SizedBox(height: btnGap),
                  GameButton(
                    label: l10n.playAgain,
                    icon: Icons.replay_rounded,
                    variant: GameButtonVariant.mint,
                    onPressed: onPlayAgain,
                  ),
                  SizedBox(height: gap),
                  GameButton(
                    label: l10n.newPuzzle,
                    icon: Icons.home_rounded,
                    variant: GameButtonVariant.blue,
                    onPressed: onNewPuzzle,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
