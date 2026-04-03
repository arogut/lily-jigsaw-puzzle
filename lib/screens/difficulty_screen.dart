import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lily_jigsaw_puzzle/core/app_theme.dart';
import 'package:lily_jigsaw_puzzle/core/widgets/puzzle_thumbnail.dart';
import 'package:lily_jigsaw_puzzle/l10n/app_localizations.dart';
import 'package:lily_jigsaw_puzzle/main.dart';
import 'package:lily_jigsaw_puzzle/models/puzzle_image.dart';
import 'package:lily_jigsaw_puzzle/screens/game_screen.dart';
import 'package:lily_jigsaw_puzzle/services/completion_service.dart';
import 'package:lily_jigsaw_puzzle/widgets/game_button.dart';
import 'package:lily_jigsaw_puzzle/widgets/gradient_title.dart';

class DifficultyScreen extends StatefulWidget {

  const DifficultyScreen({
    required this.selectedImage, required this.localeNotifier, super.key,
  });
  final PuzzleImageData selectedImage;
  final LocaleNotifier localeNotifier;

  @override
  State<DifficultyScreen> createState() => _DifficultyScreenState();
}

class _DifficultyScreenState extends State<DifficultyScreen> {
  int _stars = 0;

  @override
  void initState() {
    super.initState();
    unawaited(
      CompletionService().getStars(widget.selectedImage.uuid).then((s) {
        if (mounted) setState(() => _stars = s);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final mediumLocked = _stars < 1;
    final hardLocked = _stars < 2;

    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: AppTheme.backgroundDecoration,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 14),

                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: GameButton(
                      label: l10n.back,
                      icon: Icons.arrow_back_rounded,
                      color: AppColors.mediumPurple,
                      width: 120,
                      height: 46,
                      fontSize: 16,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Image preview with decorative frame
                _buildPreview(),

                const SizedBox(height: 26),

                // Section title
                GradientTitle(text: l10n.pickDifficulty),

                const SizedBox(height: 26),

                // Easy — always unlocked
                _DifficultyOption(
                  description: l10n.easyDesc,
                  button: GameButton(
                    label: l10n.easy,
                    color: AppColors.green,
                    shadowColor: AppColors.greenShadow,
                    width: 260,
                    height: 64,
                    fontSize: 22,
                    onPressed: () => _go(context, 3),
                  ),
                ),
                const SizedBox(height: 14),

                // Medium — locked until ≥1 star
                _DifficultyOption(
                  description: l10n.mediumDesc,
                  locked: mediumLocked,
                  button: GameButton(
                    label: l10n.medium,
                    color: AppColors.orange,
                    shadowColor: const Color(0xFFCC7722),
                    width: 260,
                    height: 64,
                    fontSize: 22,
                    onPressed: mediumLocked ? () {} : () => _go(context, 5),
                  ),
                ),
                const SizedBox(height: 14),

                // Hard — locked until ≥2 stars
                _DifficultyOption(
                  description: l10n.hardDesc,
                  locked: hardLocked,
                  button: GameButton(
                    label: l10n.hard,
                    color: AppColors.red,
                    shadowColor: AppColors.redShadow,
                    width: 260,
                    height: 64,
                    fontSize: 22,
                    onPressed: hardLocked ? () {} : () => _go(context, 7),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.40),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: 280,
        height: 200,
        child: PuzzleThumbnail(
          assetPath: widget.selectedImage.assetPath,
          cornerRadius: 24,
        ),
      ),
    );
  }

  void _go(BuildContext context, int gridSize) {
    unawaited(Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => GameScreen(
        selectedImage: widget.selectedImage,
        gridSize: gridSize,
        localeNotifier: widget.localeNotifier,
      ),
    )));
  }
}

/// A difficulty option row containing a [button] and a description text.
///
/// When [locked] is true, the button is shown at reduced opacity.
class _DifficultyOption extends StatelessWidget {
  const _DifficultyOption({
    required this.button,
    required this.description,
    this.locked = false,
  });

  final Widget button;
  final String description;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (locked) Opacity(opacity: 0.45, child: button) else button,
        const SizedBox(height: 6),
        Text(
          description,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.deepPurple.withValues(alpha: 0.70),
          ),
        ),
      ],
    );
  }
}
