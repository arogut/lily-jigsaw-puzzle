import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lily_jigsaw_puzzle/services/sound_service.dart';

/// The four pastel button variants matching the design palette.
enum GameButtonVariant { pink, blue, mint, yellow }

extension _VariantAssets on GameButtonVariant {
  String get assetPath => switch (this) {
        GameButtonVariant.pink => 'assets/ui/btn_pink.png',
        GameButtonVariant.blue => 'assets/ui/btn_blue.png',
        GameButtonVariant.mint => 'assets/ui/btn_mint.png',
        GameButtonVariant.yellow => 'assets/ui/btn_yellow.png',
      };

  Color get shadowColor => switch (this) {
        GameButtonVariant.pink => const Color(0xFFD96895),
        GameButtonVariant.blue => const Color(0xFF4AAAD4),
        GameButtonVariant.mint => const Color(0xFF55C990),
        GameButtonVariant.yellow => const Color(0xFFD4B830),
      };
}

/// A glossy, 3-D cartoon-style button using the design's pastel pill images.
///
/// Features: raised shadow base, image background, press-down animation,
/// haptic feedback. The button auto-expands horizontally when the label
/// text is longer than [width].
class GameButton extends StatefulWidget {
  const GameButton({
    required this.label,
    required this.onPressed,
    required this.variant,
    super.key,
    this.width = 240,
    this.height = 60,
    this.fontSize = 20,
    this.icon,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onPressed;
  final GameButtonVariant variant;
  final double width;
  final double height;
  final double fontSize;
  final IconData? icon;
  final bool enabled;

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool _pressed = false;

  double _computeWidth() {
    final tp = TextPainter(
      text: TextSpan(
        text: widget.label,
        style: TextStyle(
          fontSize: widget.fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    const hPad = 32.0;
    final iconW = widget.icon != null ? (widget.fontSize + 6 + 8) : 0.0;
    final contentW = tp.width + iconW + hPad;
    return contentW > widget.width ? contentW : widget.width;
  }

  @override
  Widget build(BuildContext context) {
    const bottomPad = 6.0;
    final shift = _pressed ? bottomPad : 0.0;
    final actualWidth = _computeWidth();
    final shadowColor = widget.variant.shadowColor;
    final assetPath = widget.variant.assetPath;

    // The button image's natural size (≈139×61). The pill ends take ~32 px
    // each, leaving a 75-px stretchable centre strip.
    const sliceL = 32.0;
    const sliceT = 2.0;
    const sliceW = 75.0;
    const sliceH = 57.0;

    return GestureDetector(
      onTapDown: widget.enabled
          ? (_) {
              unawaited(HapticFeedback.lightImpact());
              unawaited(SoundService().playClick());
              setState(() => _pressed = true);
            }
          : null,
      onTapUp: widget.enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onPressed();
            }
          : null,
      onTapCancel: widget.enabled ? () => setState(() => _pressed = false) : null,
      child: SizedBox(
        width: actualWidth,
        height: widget.height + bottomPad,
        child: Stack(
          children: [
            // 3-D shadow base — stays put while face lifts above it.
            Positioned(
              top: bottomPad,
              left: 0,
              right: 0,
              height: widget.height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: shadowColor,
                  borderRadius: BorderRadius.circular(widget.height / 2),
                ),
              ),
            ),

            // Button face — image + label, animated down on press.
            AnimatedPositioned(
              duration: const Duration(milliseconds: 60),
              curve: Curves.easeOut,
              top: shift,
              left: 0,
              right: 0,
              height: widget.height,
              child: Image.asset(
                assetPath,
                fit: BoxFit.fill,
                centerSlice: const Rect.fromLTWH(sliceL, sliceT, sliceW, sliceH),
                frameBuilder: (context, child, frame, _) => Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    child,
                    // Label + optional icon centred over the image.
                    Align(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(
                                widget.icon,
                                color: Colors.white,
                                size: widget.fontSize + 4,
                                shadows: const [
                                  Shadow(
                                    color: Color(0x55000000),
                                    offset: Offset(0, 2),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              widget.label,
                              style: TextStyle(
                                fontSize: widget.fontSize,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                                shadows: const [
                                  Shadow(
                                    color: Color(0x55000000),
                                    offset: Offset(0, 2),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
