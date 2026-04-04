import 'dart:async';

import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

/// A 3-D cartoon-style puzzle thumbnail matching the visual language of
/// GameButton.
///
/// The "raised edge" at the bottom is tinted with an ambilight colour derived
/// by sampling the outer edges of the image (bottom, left, right strips).
/// This mirrors the dominant hue visible near those edges, giving each card a
/// unique, physical feel. Palette extraction is cached per asset path so each
/// image is sampled only once per app session.
///
/// Supply [edgeColor] in tests (or to hard-code a colour) to bypass the async
/// palette computation.
class PuzzleThumbnail extends StatefulWidget {
  const PuzzleThumbnail({
    required this.assetPath,
    required this.cornerRadius,
    super.key,
    this.overlay,
    this.edgeDepth = 10.0,
    this.edgeColor,
  });

  /// Asset path of the puzzle image (e.g. `'assets/images/puzzle-1.jpg'`).
  final String assetPath;

  /// Corner radius applied to both the card and the image clip.
  final double cornerRadius;

  /// Optional widget layered on top of the image (e.g. star indicators).
  final Widget? overlay;

  /// Height of the visible 3-D edge in logical pixels.
  final double edgeDepth;

  /// Override the computed edge colour — useful in widget tests that cannot
  /// load real asset images.
  final Color? edgeColor;

  // Per-asset palette cache: maps asset path to [leftColor, centerColor, rightColor].
  static final Map<String, List<Color>> _cache = {};

  /// Removes all cached palette entries (intended for testing only).
  @visibleForTesting
  static void clearCache() => _cache.clear();

  @override
  State<PuzzleThumbnail> createState() => _PuzzleThumbnailState();
}

class _PuzzleThumbnailState extends State<PuzzleThumbnail> {
  /// Three gradient stops [left, center, right] resolved from the image edges.
  /// Null while loading (or when `edgeColor` override is used).
  List<Color>? _gradientColors;

  @override
  void initState() {
    super.initState();
    if (widget.edgeColor == null) {
      unawaited(_resolveEdgeColor());
    }
  }

  Future<void> _resolveEdgeColor() async {
    final path = widget.assetPath;

    if (PuzzleThumbnail._cache.containsKey(path)) {
      if (mounted) {
        setState(() => _gradientColors = PuzzleThumbnail._cache[path]);
      }
      return;
    }

    try {
      // Ambilight effect: sample three outer edge strips — left 20%, bottom
      // 30%, and right 20% — and darken each independently. The three colours
      // are then used as gradient stops (left → center → right) so the bottom
      // edge visually "bleeds" the hues seen at each side of the image.
      const size = Size(120, 90);
      final palettes = await Future.wait([
        PaletteGenerator.fromImageProvider(
          AssetImage(path),
          size: size,
          region: const Rect.fromLTWH(0, 0, 24, 90), // left 20 %
        ),
        PaletteGenerator.fromImageProvider(
          AssetImage(path),
          size: size,
          region: const Rect.fromLTWH(0, 63, 120, 27), // bottom 30 %
        ),
        PaletteGenerator.fromImageProvider(
          AssetImage(path),
          size: size,
          region: const Rect.fromLTWH(96, 0, 24, 90), // right 20 %
        ),
      ]);

      const fallback = Color(0xFF555555);
      final gradient = palettes.map((p) {
        final base = p.vibrantColor?.color ?? p.dominantColor?.color;
        return base != null ? _darken(base) : fallback;
      }).toList();

      PuzzleThumbnail._cache[path] = gradient;
      if (mounted) setState(() => _gradientColors = gradient);
    } on Exception catch (_) {
      // Image could not be loaded (e.g. asset unavailable in tests).
      // The fallback colour in build() is used instead.
    }
  }

  static Color _darken(Color c, [double amount = 0.20]) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(widget.cornerRadius);

    // Base decoration: solid colour when an override is supplied (e.g. tests),
    // otherwise a left→center→right gradient built from the ambilight palette.
    const fallback = Color(0xFF555555);
    final BoxDecoration baseDecoration;
    if (widget.edgeColor != null) {
      baseDecoration = BoxDecoration(color: widget.edgeColor, borderRadius: br);
    } else {
      final stops = _gradientColors ?? [fallback, fallback, fallback];
      baseDecoration = BoxDecoration(
        gradient: LinearGradient(colors: stops),
        borderRadius: br,
      );
    }

    // The layout mirrors GameButton:
    //   - A 3-D base layer (the ambilight gradient) fills the card from
    //     edgeDepth downward — peeking out at the bottom.
    //   - The image face sits on top, sized to leave edgeDepth exposed at the
    //     bottom, and is clipped to a full rounded rectangle so all four
    //     corners are rounded (not just the top ones).
    return Stack(
      fit: StackFit.expand,
      children: [
        // 3-D base layer — starts edgeDepth from the top so the face above
        // fully covers it except at the bottom edge.
        Positioned(
          top: widget.edgeDepth,
          left: 0,
          right: 0,
          bottom: 0,
          child: DecoratedBox(decoration: baseDecoration),
        ),

        // Image face — a properly rounded rectangle (all four corners).
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: widget.edgeDepth,
          child: ClipRRect(
            borderRadius: br,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(widget.assetPath, fit: BoxFit.cover),

                // Top gloss highlight (mimics GameButton's sheen).
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 32,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x50FFFFFF), Color(0x00FFFFFF)],
                      ),
                    ),
                  ),
                ),

                if (widget.overlay != null) widget.overlay!,

                // White border on the face — same visual language as
                // GameButton's face border.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: br,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.40),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
