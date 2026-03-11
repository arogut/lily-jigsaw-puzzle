import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lily_jigsaw_puzzle/services/sound_service.dart';

/// A glossy, 3-D cartoon-style button inspired by the pzuh.itch.io free-game-GUI pack.
/// Features: raised shadow base, gloss highlight, press-down animation, haptic feedback.
/// The button auto-expands its width when the label text is longer than [width].
class GameButton extends StatefulWidget {

  const GameButton({
    required this.label, required this.onPressed, required this.color, super.key,
    this.shadowColor,
    this.width = 240,
    this.height = 60,
    this.fontSize = 20,
    this.icon,
  });
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final Color? shadowColor;
  final double width;
  final double height;
  final double fontSize;
  final IconData? icon;

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool _pressed = false;

  static Color _darken(Color c, [double amount = 0.20]) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  /// Measures how wide the button content needs to be and returns the
  /// greater of that value and `widget.width`, ensuring text never clips.
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
    const hPad = 28.0; // 14 px on each side
    final iconW = widget.icon != null ? (widget.fontSize + 6 + 8) : 0.0;
    final contentW = tp.width + iconW + hPad;
    return contentW > widget.width ? contentW : widget.width;
  }

  @override
  Widget build(BuildContext context) {
    final shadowColor = widget.shadowColor ?? _darken(widget.color);
    const bottomPad = 6.0;
    final shift = _pressed ? bottomPad : 0.0;
    final actualWidth = _computeWidth();

    return GestureDetector(
      onTapDown: (_) {
        unawaited(HapticFeedback.lightImpact());
        unawaited(SoundService().playClick());
        setState(() => _pressed = true);
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: SizedBox(
        width: actualWidth,
        height: widget.height + bottomPad,
        child: Stack(
          children: [
            // Bottom shadow layer (3-D raised base)
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.only(top: bottomPad),
                decoration: BoxDecoration(
                  color: shadowColor,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),

            // Main button face
            AnimatedPositioned(
              duration: const Duration(milliseconds: 60),
              curve: Curves.easeOut,
              top: shift,
              left: 0,
              right: 0,
              height: widget.height,
              child: Container(
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.40),
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: Stack(
                    children: [
                      // Top gloss highlight
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: widget.height * 0.44,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x55FFFFFF), Color(0x08FFFFFF)],
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(17),
                              topRight: Radius.circular(17),
                            ),
                          ),
                        ),
                      ),

                      // Label + optional icon — centered vertically and horizontally
                      Align(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.icon != null) ...[
                                Icon(
                                  widget.icon,
                                  color: Colors.white,
                                  size: widget.fontSize + 6,
                                  shadows: const [
                                    Shadow(
                                      color: Color(0x55000000),
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
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
                                      blurRadius: 4,
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
          ],
        ),
      ),
    );
  }
}
