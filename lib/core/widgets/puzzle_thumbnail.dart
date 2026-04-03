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

  // Per-asset palette cache, shared across all instances.
  static final Map<String, Color> _cache = {};

  /// Removes all cached palette entries (intended for testing only).
  @visibleForTesting
  static void clearCache() => _cache.clear();

  @override
  State<PuzzleThumbnail> createState() => _PuzzleThumbnailState();
}

class _PuzzleThumbnailState extends State<PuzzleThumbnail> {
  Color? _edgeColor;

  @override
  void initState() {
    super.initState();
    if (widget.edgeColor != null) {
      _edgeColor = widget.edgeColor;
    } else {
      unawaited(_resolveEdgeColor());
    }
  }

  Future<void> _resolveEdgeColor() async {
    final path = widget.assetPath;

    if (PuzzleThumbnail._cache.containsKey(path)) {
      if (mounted) setState(() => _edgeColor = PuzzleThumbnail._cache[path]);
      return;
    }

    try {
      // Ambilight effect: sample outer edge strips of the image — bottom 30%,
      // left 20%, and right 20% — then average the vibrant/dominant colour
      // from each region. This makes the edge glow with the hues actually
      // visible near the borders rather than the most-repeated colour overall.
      const size = Size(120, 90);
      final palettes = await Future.wait([
        PaletteGenerator.fromImageProvider(
          AssetImage(path),
          size: size,
          region: const Rect.fromLTWH(0, 63, 120, 27), // bottom 30 %
        ),
        PaletteGenerator.fromImageProvider(
          AssetImage(path),
          size: size,
          region: const Rect.fromLTWH(0, 0, 24, 90), // left 20 %
        ),
        PaletteGenerator.fromImageProvider(
          AssetImage(path),
          size: size,
          region: const Rect.fromLTWH(96, 0, 24, 90), // right 20 %
        ),
      ]);

      final colors = palettes
          .map((p) => p.vibrantColor?.color ?? p.dominantColor?.color)
          .whereType<Color>()
          .toList();

      final base =
          colors.isEmpty ? const Color(0xFF555555) : _averageColor(colors);
      final edge = _darken(base);
      PuzzleThumbnail._cache[path] = edge;
      if (mounted) setState(() => _edgeColor = edge);
    } on Exception catch (_) {
      // Image could not be loaded (e.g. asset unavailable in tests).
      // The default fallback colour in build() is used instead.
    }
  }

  /// Returns the average of [colors] in linear RGB space.
  static Color _averageColor(List<Color> colors) {
    final r = colors.map((c) => c.r).reduce((a, b) => a + b) / colors.length;
    final g = colors.map((c) => c.g).reduce((a, b) => a + b) / colors.length;
    final b = colors.map((c) => c.b).reduce((a, b) => a + b) / colors.length;
    return Color.from(alpha: 1, red: r, green: g, blue: b);
  }

  static Color _darken(Color c, [double amount = 0.20]) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    // Neutral fallback shown while the palette is being computed.
    final edgeColor = _edgeColor ?? const Color(0xFF555555);
    final br = BorderRadius.circular(widget.cornerRadius);
    final faceRadius = BorderRadius.only(
      topLeft: Radius.circular(widget.cornerRadius),
      topRight: Radius.circular(widget.cornerRadius),
      bottomLeft: const Radius.circular(3),
      bottomRight: const Radius.circular(3),
    );

    return ClipRRect(
      borderRadius: br,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 3-D base layer — the ambilight edge colour fills the whole card
          // and peeks out at the bottom beneath the image face.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(color: edgeColor, borderRadius: br),
            ),
          ),

          // Image face — offset upward so the base colour shows at the bottom.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: widget.edgeDepth,
            child: ClipRRect(
              borderRadius: faceRadius,
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

                  // White border on the face only — same visual language as
                  // GameButton's face border.
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: faceRadius,
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
      ),
    );
  }
}
