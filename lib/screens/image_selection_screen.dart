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
import 'package:lily_jigsaw_puzzle/services/sound_service.dart';
import 'package:lily_jigsaw_puzzle/widgets/game_button.dart';
import 'package:lily_jigsaw_puzzle/widgets/gradient_title.dart';

class ImageSelectionScreen extends StatefulWidget {

  const ImageSelectionScreen({required this.localeNotifier, super.key});
  final LocaleNotifier localeNotifier;

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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
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

/// Returns the localized image name for a given asset path.
String localizedImageName(AppLocalizations l10n, String assetPath) {
  switch (assetPath) {
    case 'assets/images/puzzle-1.jpg': return l10n.imageCat;
    case 'assets/images/puzzle-2.jpg': return l10n.imageDog;
    case 'assets/images/puzzle-3.jpg': return l10n.imageForest;
    case 'assets/images/puzzle-4.jpg': return l10n.imageCity;
    case 'assets/images/puzzle-5.jpg': return l10n.imageLion;
    case 'assets/images/puzzle-6.jpg': return l10n.imageSea;
    case 'assets/images/puzzle-7.jpg': return l10n.imageElephant;
    case 'assets/images/puzzle-8.jpg': return l10n.imageSquirrel;
    case 'assets/images/puzzle-9.jpg': return l10n.imageHedgehog;
    default: return '';
  }
}

// ── Image card ───────────────────────────────────────────────────────────────

class _ImageCard extends StatefulWidget {
  const _ImageCard({required this.image, required this.localeNotifier});
  final PuzzleImageData image;
  final LocaleNotifier localeNotifier;

  @override
  State<_ImageCard> createState() => _ImageCardState();
}

class _ImageCardState extends State<_ImageCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 110));
    _scale = Tween<double>(begin: 1, end: 0.93)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 12,
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
            overlay: Align(
              child: FutureBuilder<int>(
                future: CompletionService().getStars(widget.image.uuid),
                builder: (context, snap) {
                  final stars = snap.data ?? 0;
                  if (stars == 0) return const SizedBox.shrink();
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        stars,
                        (_) => const Star3d(size: 56),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
