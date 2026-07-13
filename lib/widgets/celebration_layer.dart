import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:lily_jigsaw_puzzle/models/celebration_style.dart';
import 'package:lily_jigsaw_puzzle/painters/balloon_painter.dart';
import 'package:lily_jigsaw_puzzle/painters/confetti_painter.dart';
import 'package:lily_jigsaw_puzzle/painters/fireworks_painter.dart';
import 'package:lily_jigsaw_puzzle/painters/milestone_painter.dart';

/// Full-screen particle animation layer for a single celebration play.
///
/// Sound is the caller's responsibility — this widget renders visuals only.
class CelebrationLayer extends StatefulWidget {
  /// Creates a [CelebrationLayer].
  const CelebrationLayer({
    required this.style,
    required this.intensity,
    required this.onSkip,
    required this.onAnimationComplete,
    super.key,
  });

  /// Which particle style to render.
  final CelebrationStyleId style;

  /// Intensity configuration (particle count + animation duration).
  final CelebrationIntensity intensity;

  /// Called when the player taps to skip the animation phase.
  final VoidCallback onSkip;

  /// Called when the animation controller reaches [AnimationStatus.completed].
  final VoidCallback onAnimationComplete;

  @override
  State<CelebrationLayer> createState() => _CelebrationLayerState();
}

class _CelebrationLayerState extends State<CelebrationLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CustomPainter _painter;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.intensity.animationDuration,
    );
    _controller.addStatusListener(_onStatusChanged);
    unawaited(_controller.forward());
    _painter = _buildPainter();
  }

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _finish(onAnimationComplete: widget.onAnimationComplete);
    }
  }

  void _finish({required VoidCallback onAnimationComplete}) {
    if (_finished) return;
    _finished = true;
    onAnimationComplete();
  }

  CustomPainter _buildPainter() {
    final count = widget.intensity.particleCount;
    return switch (widget.style) {
      CelebrationStyleId.confetti => ConfettiPainter(
          particles: generateConfettiParticles(count),
          animation: _controller,
        ),
      CelebrationStyleId.balloons => BalloonPainter(
          particles: generateBalloonParticles(count),
          animation: _controller,
        ),
      CelebrationStyleId.fireworks => FireworksPainter(
          particles: generateFireworksParticles(count),
          animation: _controller,
        ),
      CelebrationStyleId.milestone => MilestonePainter(
          particles: generateMilestoneParticles(count),
          animation: _controller,
        ),
    };
  }

  void _handleSkip() {
    _controller.stop();
    _finish(onAnimationComplete: widget.onSkip);
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_onStatusChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleSkip,
      child: CustomPaint(
        painter: _painter,
        size: Size.infinite,
      ),
    );
  }
}
