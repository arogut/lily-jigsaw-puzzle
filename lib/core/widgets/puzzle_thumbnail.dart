import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:palette_generator/palette_generator.dart';

/// A 3-D cartoon-style puzzle thumbnail matching the visual language of
/// GameButton.
///
/// The "raised edge" at the bottom is tinted with an ambilight gradient
/// derived by sampling three points along the bottom edge of the image:
/// bottom-left corner, bottom-center, and bottom-right corner. These become
/// the gradient stops (left → center → right), giving each card a unique,
/// physical feel. Palette extraction is cached per asset path so each image
/// is sampled only once per app session.
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

  /// Pre-computes and caches edge colours for [paths] in parallel.
  ///
  /// Call this early (e.g. during the splash screen) so thumbnails render with
  /// their final colour immediately when the image selection screen first appears.
  static Future<void> prewarm(List<String> paths) =>
      Future.wait(paths.map(_computeAndCache));

  // Decodes the image once at thumbnail size, then samples three bottom-edge
  // regions in parallel — avoiding three separate fromImageProvider calls
  // (each of which would decode the image independently).
  static Future<void> _computeAndCache(String path) async {
    if (_cache.containsKey(path)) return;

    try {
      final bytes = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(
        bytes.buffer.asUint8List(),
        targetWidth: 120,
        targetHeight: 90,
      );
      final image = (await codec.getNextFrame()).image;

      // Ambilight effect: sample bottom-left, bottom-center, bottom-right.
      final List<PaletteGenerator> palettes;
      try {
        palettes = await Future.wait([
          PaletteGenerator.fromImage(image, region: const Rect.fromLTWH(0, 63, 40, 27)),
          PaletteGenerator.fromImage(image, region: const Rect.fromLTWH(40, 63, 40, 27)),
          PaletteGenerator.fromImage(image, region: const Rect.fromLTWH(80, 63, 40, 27)),
        ]);
      } finally {
        image.dispose();
      }

      const fallback = Color(0xFF555555);
      _cache[path] = palettes.map((p) {
        final base = p.vibrantColor?.color ?? p.dominantColor?.color;
        return base != null ? _darken(base) : fallback;
      }).toList();
    } on Object catch (_) {
      // Asset unavailable or decode error (e.g. in tests) — fallback colour used in build().
    }
  }

  static Color _darken(Color c, [double amount = 0.20]) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

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
      unawaited(_applyEdgeColor());
    }
  }

  // Reads the cached result (or waits for it to be computed) then rebuilds.
  Future<void> _applyEdgeColor() async {
    await PuzzleThumbnail._computeAndCache(widget.assetPath);
    if (mounted) {
      setState(() => _gradientColors = PuzzleThumbnail._cache[widget.assetPath]);
    }
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
        gradient: LinearGradient(
          colors: stops,
          stops: const [0.0, 0.5, 1.0],
        ),
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
