import 'dart:async';

import 'package:flutter/material.dart';
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF87CEEB),
              Color(0xFFB39DDB),
              Color(0xFFFFABD0),
            ],
            stops: [0.0, 0.50, 1.0],
          ),
        ),
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
                      color: const Color(0xFF9B59B6),
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
                Column(
                  children: [
                    GameButton(
                      label: l10n.easy,
                      color: const Color(0xFF6BCB77),
                      shadowColor: const Color(0xFF3A9E48),
                      width: 260,
                      height: 64,
                      fontSize: 22,
                      onPressed: () => _go(context, 3),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.easyDesc,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6A1B9A).withValues(alpha: 0.70),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Medium — locked until ≥1 star
                Column(
                  children: [
                    _lockedOrButton(
                      locked: mediumLocked,
                      child: GameButton(
                        label: l10n.medium,
                        color: const Color(0xFFFFAB40),
                        shadowColor: const Color(0xFFCC7722),
                        width: 260,
                        height: 64,
                        fontSize: 22,
                        onPressed: mediumLocked ? () {} : () => _go(context, 5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.mediumDesc,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6A1B9A).withValues(alpha: 0.70),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Hard — locked until ≥2 stars
                Column(
                  children: [
                    _lockedOrButton(
                      locked: hardLocked,
                      child: GameButton(
                        label: l10n.hard,
                        color: const Color(0xFFFF6B6B),
                        shadowColor: const Color(0xFFCC2222),
                        width: 260,
                        height: 64,
                        fontSize: 22,
                        onPressed: hardLocked ? () {} : () => _go(context, 7),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.hardDesc,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6A1B9A).withValues(alpha: 0.70),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Wraps [child] in reduced opacity when [locked] is true.
  Widget _lockedOrButton({required bool locked, required Widget child}) {
    if (!locked) return child;
    return Opacity(opacity: 0.45, child: child);
  }

  Widget _buildPreview() {
    return Container(
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
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.70),
          width: 3,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Stack(
          children: [
            Image.asset(
              widget.selectedImage.assetPath,
              width: 280,
              height: 200,
              fit: BoxFit.cover,
            ),
            // Gloss highlight
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 60,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x50FFFFFF), Color(0x00FFFFFF)],
                  ),
                ),
              ),
            ),
          ],
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
