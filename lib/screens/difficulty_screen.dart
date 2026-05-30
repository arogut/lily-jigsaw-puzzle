import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lily_jigsaw_puzzle/core/app_theme.dart';
import 'package:lily_jigsaw_puzzle/core/widgets/puzzle_thumbnail.dart';
import 'package:lily_jigsaw_puzzle/l10n/app_localizations.dart';
import 'package:lily_jigsaw_puzzle/main.dart';
import 'package:lily_jigsaw_puzzle/models/puzzle_image.dart';
import 'package:lily_jigsaw_puzzle/screens/game_screen.dart';
import 'package:lily_jigsaw_puzzle/services/completion_service.dart';
import 'package:lily_jigsaw_puzzle/services/difficulty_settings_service.dart';
import 'package:lily_jigsaw_puzzle/widgets/game_button.dart';
import 'package:lily_jigsaw_puzzle/widgets/gradient_title.dart';

class DifficultyScreen extends StatefulWidget {

  const DifficultyScreen({
    required this.selectedImage,
    required this.localeNotifier,
    required this.difficultySettings,
    super.key,
  });
  final PuzzleImageData selectedImage;
  final LocaleNotifier localeNotifier;
  final DifficultySettings difficultySettings;

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
    final ds = widget.difficultySettings;

    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: AppTheme.backgroundDecoration,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 750;
              return compact
                  ? _buildCompactLayout(context, l10n, constraints, mediumLocked, hardLocked, ds)
                  : _buildNormalLayout(context, l10n, mediumLocked, hardLocked, ds);
            },
          ),
        ),
      ),
    );
  }

  /// Standard vertical layout for tablets and larger screens.
  Widget _buildNormalLayout(
    BuildContext context,
    AppLocalizations l10n,
    bool mediumLocked,
    bool hardLocked,
    DifficultySettings ds,
  ) {
    return SingleChildScrollView(
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
                variant: GameButtonVariant.blue,
                fontSize: 16,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Image preview — constrained width, height locked to border ratio.
          SizedBox(
            width: 280,
            child: AspectRatio(
              aspectRatio: 644 / 608,
              child: PuzzleThumbnail(assetPath: widget.selectedImage.assetPath),
            ),
          ),

          const SizedBox(height: 26),

          GradientTitle(text: l10n.pickDifficulty),

          const SizedBox(height: 26),

          _DifficultyOption(
            description: l10n.difficultyPiecesDesc(ds.easyGridSize * ds.easyGridSize, ds.easyGridSize),
            button: GameButton(
              label: l10n.easy,
              variant: GameButtonVariant.mint,
              fontSize: 22,
              onPressed: () => _go(context, ds.easyGridSize, 1),
            ),
          ),
          const SizedBox(height: 14),

          _DifficultyOption(
            description: l10n.difficultyPiecesDesc(ds.mediumGridSize * ds.mediumGridSize, ds.mediumGridSize),
            locked: mediumLocked,
            button: GameButton(
              label: l10n.medium,
              variant: GameButtonVariant.yellow,
              fontSize: 22,
              onPressed: mediumLocked ? () {} : () => _go(context, ds.mediumGridSize, 2),
            ),
          ),
          const SizedBox(height: 14),

          _DifficultyOption(
            description: l10n.difficultyPiecesDesc(ds.hardGridSize * ds.hardGridSize, ds.hardGridSize),
            locked: hardLocked,
            button: GameButton(
              label: l10n.hard,
              variant: GameButtonVariant.pink,
              fontSize: 22,
              onPressed: hardLocked ? () {} : () => _go(context, ds.hardGridSize, 3),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Compact two-column layout for small landscape screens (phones).
  ///
  /// Shows the puzzle thumbnail on the left and difficulty buttons on the right.
  Widget _buildCompactLayout(
    BuildContext context,
    AppLocalizations l10n,
    BoxConstraints constraints,
    bool mediumLocked,
    bool hardLocked,
    DifficultySettings ds,
  ) {
    // Derive button width from available height so the asset ratio is preserved.
    final desiredBtnH = (constraints.maxHeight * 0.18).clamp(38.0, 52.0);
    final btnFontSize = (desiredBtnH * 0.38).clamp(13.0, 18.0);

    return Column(
      children: [
        // Back button row
        Padding(
          padding: const EdgeInsets.only(left: 14, top: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: GameButton(
              label: l10n.back,
              icon: Icons.arrow_back_rounded,
              variant: GameButtonVariant.blue,
              fontSize: 13,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),

        // Thumbnail (left) + difficulty buttons (right)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Thumbnail fills left half
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 644 / 608,
                      child: PuzzleThumbnail(assetPath: widget.selectedImage.assetPath),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Title + difficulty buttons on right half
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GradientTitle(text: l10n.pickDifficulty, fontSize: 18),
                      const SizedBox(height: 8),
                      _DifficultyOption(
                        description: l10n.difficultyPiecesDesc(ds.easyGridSize * ds.easyGridSize, ds.easyGridSize),
                        button: GameButton(
                          label: l10n.easy,
                          variant: GameButtonVariant.mint,
                          fontSize: btnFontSize,
                          onPressed: () => _go(context, ds.easyGridSize, 1),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _DifficultyOption(
                        description: l10n.difficultyPiecesDesc(ds.mediumGridSize * ds.mediumGridSize, ds.mediumGridSize),
                        locked: mediumLocked,
                        button: GameButton(
                          label: l10n.medium,
                          variant: GameButtonVariant.yellow,
                          fontSize: btnFontSize,
                          onPressed: mediumLocked ? () {} : () => _go(context, ds.mediumGridSize, 2),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _DifficultyOption(
                        description: l10n.difficultyPiecesDesc(ds.hardGridSize * ds.hardGridSize, ds.hardGridSize),
                        locked: hardLocked,
                        button: GameButton(
                          label: l10n.hard,
                          variant: GameButtonVariant.pink,
                          fontSize: btnFontSize,
                          onPressed: hardLocked ? () {} : () => _go(context, ds.hardGridSize, 3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _go(BuildContext context, int gridSize, int difficultyStars) {
    unawaited(Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => GameScreen(
        selectedImage: widget.selectedImage,
        gridSize: gridSize,
        difficultyStars: difficultyStars,
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
        const SizedBox(height: 4),
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
