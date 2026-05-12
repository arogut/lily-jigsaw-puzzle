import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lily_jigsaw_puzzle/services/sound_service.dart';

/// The four pastel button variants matching the design palette.
enum GameButtonVariant { pink, blue, mint, yellow }

extension _VariantAsset on GameButtonVariant {
  String get assetPath => switch (this) {
        GameButtonVariant.pink => 'assets/ui/btn_pink.png',
        GameButtonVariant.blue => 'assets/ui/btn_blue.png',
        GameButtonVariant.mint => 'assets/ui/btn_mint.png',
        GameButtonVariant.yellow => 'assets/ui/btn_yellow.png',
      };
}

/// Pill-shaped button using the design's pastel image assets.
///
/// Stretches horizontally via 9-patch centerSlice so rounded corners stay
/// sharp at any width. Scales down 4% on press for tactile feedback.
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
    final actualWidth = _computeWidth();

    // The pill images are ≈139×61 px. Left/right caps are ~32 px each;
    // the 75 px centre strip stretches horizontally. The 2 px top/bottom
    // margins stay fixed so the pill silhouette never distorts vertically.
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
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 60),
        child: SizedBox(
          width: actualWidth,
          height: widget.height,
          child: Image.asset(
            widget.variant.assetPath,
            fit: BoxFit.fill,
            centerSlice: const Rect.fromLTWH(sliceL, sliceT, sliceW, sliceH),
            frameBuilder: (context, child, frame, _) => Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                child,
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
      ),
    );
  }
}
