import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Displays a puzzle image clipped to the inner hole of the rainbow border
/// frame (thumbnail_border.png), with an optional overlay widget on top.
///
/// The clip mask (thumbnail_clip.png) is derived once via BFS from the
/// border's transparent inner hole and cached statically. Both the mask and
/// the decoded puzzle image are loaded asynchronously; until they are ready
/// the widget falls back to a plain Image.asset.
class PuzzleThumbnail extends StatefulWidget {
  const PuzzleThumbnail({
    required this.assetPath,
    super.key,
    this.overlay,
  });

  /// Asset path of the puzzle image (e.g. `'assets/images/puzzle-1.jpg'`).
  final String assetPath;

  /// Optional widget layered on top of the border frame (e.g. star indicators).
  final Widget? overlay;

  // Display-quality decoded images for the masked painter. Null entry means
  // decode failed (asset missing); absence means not yet attempted.
  static final Map<String, ui.Image?> _displayImageCache = {};

  // Clip mask derived from the transparent inner hole of thumbnail_border.png.
  static ui.Image? _clipMask;

  /// Removes all cached entries (intended for testing only).
  @visibleForTesting
  static void clearCache() {
    _displayImageCache.clear();
    _clipMask = null;
  }

  static Future<void> _loadClipMask() async {
    if (_clipMask != null) return;
    try {
      final data = await rootBundle.load('assets/ui/thumbnail_clip.png');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      _clipMask = (await codec.getNextFrame()).image;
    } on Object catch (_) {
      // Asset unavailable in tests — mask stays null; puzzle renders unclipped.
    }
  }

  static Future<ui.Image?> _fetchDisplayImage(String path) async {
    if (_displayImageCache.containsKey(path)) return _displayImageCache[path];
    try {
      final bytes = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(
        bytes.buffer.asUint8List(),
        targetWidth: 600,
      );
      final image = (await codec.getNextFrame()).image;
      _displayImageCache[path] = image;
      return image;
    } on Object catch (_) {
      _displayImageCache[path] = null;
      return null;
    }
  }

  /// Pre-loads the clip mask and decodes [paths] at display quality so that
  /// thumbnails render masked immediately when the image selection screen appears.
  ///
  /// Call early (e.g. during the splash screen) with all puzzle image paths.
  static Future<void> prewarm(List<String> paths) => Future.wait([
        _loadClipMask(),
        ...paths.map(_fetchDisplayImage),
      ]);

  @override
  State<PuzzleThumbnail> createState() => _PuzzleThumbnailState();
}

class _PuzzleThumbnailState extends State<PuzzleThumbnail> {
  ui.Image? _displayImage;

  @override
  void initState() {
    super.initState();
    if (PuzzleThumbnail._clipMask == null) unawaited(_loadMaskAndRebuild());
    unawaited(_loadDisplayImage());
  }

  Future<void> _loadMaskAndRebuild() async {
    await PuzzleThumbnail._loadClipMask();
    if (mounted) setState(() {});
  }

  Future<void> _loadDisplayImage() async {
    final img = await PuzzleThumbnail._fetchDisplayImage(widget.assetPath);
    if (mounted) setState(() => _displayImage = img);
  }

  @override
  Widget build(BuildContext context) {
    final mask = PuzzleThumbnail._clipMask;
    final puzzleImage = _displayImage;

    final imageLayer = mask != null && puzzleImage != null
        ? CustomPaint(
            painter: _MaskedPuzzlePainter(
              puzzleImage: puzzleImage,
              maskImage: mask,
            ),
          )
        : Image.asset(widget.assetPath, fit: BoxFit.cover);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Puzzle image clipped to the border's inner hole.
        imageLayer,

        // Rainbow border frame — sits above the masked image.
        Image.asset('assets/ui/thumbnail_border.png', fit: BoxFit.fill),

        // Optional overlay (e.g. star indicators) — above the frame.
        if (widget.overlay != null) widget.overlay!,
      ],
    );
  }
}

// Draws the puzzle image clipped to the inner hole defined by maskImage.
// Uses saveLayer + dstIn so coordinates are unambiguously in canvas logical pixels.
class _MaskedPuzzlePainter extends CustomPainter {
  const _MaskedPuzzlePainter({
    required this.puzzleImage,
    required this.maskImage,
  });

  final ui.Image puzzleImage;
  final ui.Image maskImage;

  @override
  void paint(Canvas canvas, Size size) {
    final dst = Offset.zero & size;
    final puzzleSrc = Rect.fromLTWH(
      0,
      0,
      puzzleImage.width.toDouble(),
      puzzleImage.height.toDouble(),
    );
    final maskSrc = Rect.fromLTWH(
      0,
      0,
      maskImage.width.toDouble(),
      maskImage.height.toDouble(),
    );

    canvas
      ..saveLayer(dst, Paint())
      ..drawImageRect(
        puzzleImage,
        puzzleSrc,
        dst,
        Paint()..filterQuality = FilterQuality.medium,
      )
      ..drawImageRect(
        maskImage,
        maskSrc,
        dst,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..filterQuality = FilterQuality.medium,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_MaskedPuzzlePainter old) =>
      old.puzzleImage != puzzleImage || old.maskImage != maskImage;
}
