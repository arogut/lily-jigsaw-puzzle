import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../models/puzzle_image.dart';
import '../widgets/game_button.dart';
import 'game_screen.dart';

class DifficultyScreen extends StatelessWidget {
  final PuzzleImageData selectedImage;
  final LocaleNotifier localeNotifier;

  const DifficultyScreen({
    super.key,
    required this.selectedImage,
    required this.localeNotifier,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                _buildTitle(l10n.pickDifficulty),

                const SizedBox(height: 26),

                // Easy
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

                // Medium
                Column(
                  children: [
                    GameButton(
                      label: l10n.medium,
                      color: const Color(0xFFFFAB40),
                      shadowColor: const Color(0xFFCC7722),
                      width: 260,
                      height: 64,
                      fontSize: 22,
                      onPressed: () => _go(context, 5),
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

                // Hard
                Column(
                  children: [
                    GameButton(
                      label: l10n.hard,
                      color: const Color(0xFFFF6B6B),
                      shadowColor: const Color(0xFFCC2222),
                      width: 260,
                      height: 64,
                      fontSize: 22,
                      onPressed: () => _go(context, 7),
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
              selectedImage.assetPath,
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

  Widget _buildTitle(String text) {
    const sz = 28.0;
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: sz,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5
              ..color = const Color(0xFF6A1B9A),
          ),
        ),
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Color(0xFFFFD93D), Color(0xFFFF6B9D)],
          ).createShader(b),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: sz,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  void _go(BuildContext context, int gridSize) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GameScreen(
        selectedImage: selectedImage,
        gridSize: gridSize,
        localeNotifier: localeNotifier,
      ),
    ));
  }
}
