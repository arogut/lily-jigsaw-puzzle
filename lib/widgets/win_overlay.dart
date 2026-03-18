import 'package:flutter/material.dart';
import 'package:lily_jigsaw_puzzle/core/app_theme.dart';
import 'package:lily_jigsaw_puzzle/l10n/app_localizations.dart';
import 'package:lily_jigsaw_puzzle/widgets/game_button.dart';
import 'package:lily_jigsaw_puzzle/widgets/gradient_title.dart';

/// Overlay shown when the player completes the puzzle.
///
/// Displays a celebration message, the win title, and action buttons
/// for replaying or returning home.
class WinOverlay extends StatelessWidget {
  const WinOverlay({
    required this.onPlayAgain,
    required this.onNewPuzzle,
    super.key,
  });

  /// Called when the player taps "Play Again".
  final VoidCallback onPlayAgain;

  /// Called when the player taps "New Puzzle".
  final VoidCallback onNewPuzzle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xBB000040), Color(0xBB000020)],
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF8FF), Color(0xFFFFEEFF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.hotPink.withValues(alpha: 0.50),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: AppColors.hotPink.withValues(alpha: 0.50),
                width: 2.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 72)),
                const SizedBox(height: 10),
                GradientTitle(text: l10n.youDidIt, fontSize: 34),
                const SizedBox(height: 8),
                Text(
                  l10n.puzzleComplete,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepPurple.withValues(alpha: 0.70),
                  ),
                ),
                const SizedBox(height: 28),
                GameButton(
                  label: l10n.playAgain,
                  icon: Icons.replay_rounded,
                  color: AppColors.green,
                  shadowColor: AppColors.greenShadow,
                  width: 220,
                  height: 56,
                  onPressed: onPlayAgain,
                ),
                const SizedBox(height: 12),
                GameButton(
                  label: l10n.newPuzzle,
                  icon: Icons.home_rounded,
                  color: AppColors.blue,
                  shadowColor: AppColors.blueShadow,
                  width: 220,
                  height: 56,
                  onPressed: onNewPuzzle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
