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

// Natural asset dimensions. The 9-patch slice caps are fixed; only the
// horizontal centre strip stretches to accommodate the label.
const _kBtnH = 61.0;
const _kCapW = 32.0; // left/right end-cap width — not stretched
const _kMinW = 138.0; // natural asset width, enforced as minimum button width
const _kSlice = Rect.fromLTWH(32, 2, 74, 57);

/// Pill-shaped button backed by the design's pastel image assets (138×61 px).
///
/// Height is always [_kBtnH] (the natural asset height). Width auto-sizes to
/// the label and icon using 9-patch centre stretching, so the rounded pill
/// caps and the drop-shadow rows are never distorted. Scales down on press
/// for tactile feedback.
class GameButton extends StatefulWidget {
  const GameButton({
    required this.label,
    required this.onPressed,
    required this.variant,
    super.key,
    this.fontSize = 18,
    this.icon,
    this.enabled = true,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback onPressed;
  final GameButtonVariant variant;
  final double fontSize;
  final IconData? icon;
  final bool enabled;

  /// Accessibility label; defaults to [label] when omitted.
  final String? semanticLabel;

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.semanticLabel ?? widget.label,
      child: ExcludeSemantics(
        child: GestureDetector(
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
          onTapCancel: widget.enabled
              ? () => setState(() => _pressed = false)
              : null,
          child: AnimatedScale(
            scale: _pressed ? 0.96 : 1.0,
            duration: const Duration(milliseconds: 60),
            // IntrinsicWidth lets the button grow to fit its label; the
            // ConstrainedBox enforces the natural asset width as a floor.
            child: IntrinsicWidth(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: _kMinW),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(widget.variant.assetPath),
                      centerSlice: _kSlice,
                      fit: BoxFit.fill,
                    ),
                  ),
                  child: SizedBox(
                    height: _kBtnH,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: _kCapW),
                      child: Center(
                        child: Row(
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
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
