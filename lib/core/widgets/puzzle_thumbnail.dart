import 'dart:async';

import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

/// A 3-D cartoon-style puzzle thumbnail matching the visual language of
/// GameButton.
///
/// The "raised edge" at the bottom is tinted with the image's dominant colour
/// (darkened ~30 %), giving each card a unique, physical feel. Palette
/// extraction is cached per asset path so each image is sampled only once per
/// app session.
///
/// Supply [edgeColor] in tests (or to hard-code a colour) to bypass the async
/// palette computation.
class PuzzleThumbnail extends StatefulWidget {
  const PuzzleThumbnail({
    required this.assetPath,
    required this.cornerRadius,
    super.key,
    this.overlay,
    this.edgeDepth = 6.0,
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
      final palette = await PaletteGenerator.fromImageProvider(
        AssetImage(path),
        size: const Size(100, 75), // small sample for performance
      );
      final base = palette.dominantColor?.color ?? const Color(0xFF555555);
      final edge = _darken(base);
      PuzzleThumbnail._cache[path] = edge;
      if (mounted) setState(() => _edgeColor = edge);
    } on Exception catch (_) {
      // Image could not be loaded (e.g. asset unavailable in tests).
      // The default fallback colour in build() is used instead.
    }
  }

  static Color _darken(Color c, [double amount = 0.28]) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    // Neutral fallback shown while the palette is being computed.
    final edgeColor = _edgeColor ?? const Color(0xFF555555);
    final br = BorderRadius.circular(widget.cornerRadius);

    return ClipRRect(
      borderRadius: br,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 3-D base layer — the edge colour fills the whole card and peeks
          // out at the bottom beneath the image face.
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
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(widget.cornerRadius),
                topRight: Radius.circular(widget.cornerRadius),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(widget.assetPath, fit: BoxFit.cover),

                  // Top gloss highlight (mimics GameButton's sheen)
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
                ],
              ),
            ),
          ),

          // White border overlay (same style as GameButton's border)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: br,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.55),
                  width: 2.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
