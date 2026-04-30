import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lily_jigsaw_puzzle/core/app_theme.dart';
import 'package:lily_jigsaw_puzzle/core/widgets/puzzle_thumbnail.dart';
import 'package:lily_jigsaw_puzzle/core/widgets/star_3d.dart';
import 'package:lily_jigsaw_puzzle/l10n/app_localizations.dart';
import 'package:lily_jigsaw_puzzle/main.dart';
import 'package:lily_jigsaw_puzzle/models/puzzle_image.dart';
import 'package:lily_jigsaw_puzzle/screens/difficulty_screen.dart';
import 'package:lily_jigsaw_puzzle/screens/settings_screen.dart';
import 'package:lily_jigsaw_puzzle/services/completion_service.dart';
import 'package:lily_jigsaw_puzzle/services/difficulty_settings_service.dart';
import 'package:lily_jigsaw_puzzle/services/sound_service.dart';
import 'package:lily_jigsaw_puzzle/widgets/game_button.dart';
import 'package:lily_jigsaw_puzzle/widgets/gradient_title.dart';

class ImageSelectionScreen extends StatefulWidget {

  const ImageSelectionScreen({
    required this.localeNotifier,
    required this.difficultySettings,
    super.key,
  });
  final LocaleNotifier localeNotifier;
  final DifficultySettings difficultySettings;

  @override
  State<ImageSelectionScreen> createState() => _ImageSelectionScreenState();
}

// StatefulWidget is required so that returning from Settings triggers a
// setState() call, which forces each _ImageCard's FutureBuilder to re-fetch
// updated star counts (e.g. after progress reset).
class _ImageSelectionScreenState extends State<ImageSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundDecoration,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 14),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: AppTheme.glassCard(radius: 24),
                child: Row(
                  children: [
                    GameButton(
                      label: l10n.quit,
                      icon: Icons.exit_to_app_rounded,
                      color: AppColors.red,
                      shadowColor: AppColors.redShadow,
                      width: 110,
                      height: 44,
                      fontSize: 15,
                      onPressed: SystemNavigator.pop,
                    ),
                    Expanded(child: Center(child: GradientTitle(text: l10n.choosePuzzle, fontSize: 30))),
                    GameButton(
                      label: l10n.settings,
                      icon: Icons.settings_rounded,
                      color: AppColors.mediumPurple,
                      shadowColor: AppColors.deepPurple,
                      width: 110,
                      height: 44,
                      fontSize: 15,
                      onPressed: () {
                        unawaited(
                          Navigator.of(context).push(MaterialPageRoute<void>(
                            builder: (_) => SettingsScreen(
                              localeNotifier: widget.localeNotifier,
                              difficultySettings: widget.difficultySettings,
                            ),
                          )).then((_) {
                            if (mounted) setState(() {});
                          }),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 4 / 3,
                    ),
                    itemCount: PuzzleImageData.all.length,
                    itemBuilder: (context, index) {
                      return _ImageCard(
                        image: PuzzleImageData.all[index],
                        localeNotifier: widget.localeNotifier,
                        difficultySettings: widget.difficultySettings,
                      );
                    },
                  ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

}


// ── Image card ───────────────────────────────────────────────────────────────

class _ImageCard extends StatefulWidget {
  const _ImageCard({
    required this.image,
    required this.localeNotifier,
    required this.difficultySettings,
  });
  final PuzzleImageData image;
  final LocaleNotifier localeNotifier;
  final DifficultySettings difficultySettings;

  @override
  State<_ImageCard> createState() => _ImageCardState();
}

class _ImageCardState extends State<_ImageCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  int _stars = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 110));
    _scale = Tween<double>(begin: 1, end: 0.93)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    unawaited(_loadStars());
  }

  @override
  void didUpdateWidget(_ImageCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    unawaited(_loadStars());
  }

  Future<void> _loadStars() async {
    final s = await CompletionService().getStars(widget.image.uuid);
    if (mounted) setState(() => _stars = s);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTap() {
    unawaited(_ctrl.reverse());
    unawaited(SoundService().playClick());
    unawaited(Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => DifficultyScreen(
        selectedImage: widget.image,
        localeNotifier: widget.localeNotifier,
        difficultySettings: widget.difficultySettings,
      ),
    )).then((_) {
      // Refresh star display when returning from the game.
      if (mounted) setState(() {});
    }));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _onTap(),
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: _stars == 3
                ? Border.all(color: AppColors.gold, width: 2.5)
                : null,
            boxShadow: [
              BoxShadow(
                color: _stars == 3
                    ? AppColors.gold.withValues(alpha: 0.45)
                    : Colors.black.withValues(alpha: 0.28),
                blurRadius: _stars == 3 ? 20 : 12,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.35),
                blurRadius: 4,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: PuzzleThumbnail(
            assetPath: widget.image.assetPath,
            cornerRadius: 20,
            overlay: Stack(
              children: [
                // Image name label — dark gradient scrim at the bottom
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 28, 10, 7),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xBB000000), Color(0x00000000)],
                      ),
                    ),
                    child: Text(
                      widget.image.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Color(0x88000000),
                            offset: Offset(0, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Star badges at top-right
                if (_stars > 0)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(_stars, (_) => const Star3d(size: 26)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
