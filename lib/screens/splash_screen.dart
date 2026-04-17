import 'dart:async';

import 'package:flutter/material.dart';

import 'package:lily_jigsaw_puzzle/core/app_theme.dart';
import 'package:lily_jigsaw_puzzle/core/widgets/puzzle_thumbnail.dart';
import 'package:lily_jigsaw_puzzle/main.dart';
import 'package:lily_jigsaw_puzzle/models/puzzle_image.dart';
import 'package:lily_jigsaw_puzzle/painters/logo_painter.dart';
import 'package:lily_jigsaw_puzzle/screens/image_selection_screen.dart';
import 'package:lily_jigsaw_puzzle/services/difficulty_settings_service.dart';
import 'package:lily_jigsaw_puzzle/widgets/gradient_title.dart';

class SplashScreen extends StatefulWidget {

  const SplashScreen({
    required this.localeNotifier,
    required this.difficultySettings,
    super.key,
  });
  final LocaleNotifier localeNotifier;
  final DifficultySettings difficultySettings;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _inController;
  late final AnimationController _outController;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scaleIn;
  late final Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();

    _inController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _outController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeIn =
        CurvedAnimation(parent: _inController, curve: Curves.easeOut);
    _scaleIn = Tween<double>(begin: 0.65, end: 1).animate(
      CurvedAnimation(parent: _inController, curve: Curves.elasticOut),
    );
    _fadeOut =
        CurvedAnimation(parent: _outController, curve: Curves.easeIn);

    unawaited(_inController.forward());

    // Pre-warm thumbnail edge colours so they are ready when the selection
    // screen appears. Runs in parallel with the splash animation.
    unawaited(PuzzleThumbnail.prewarm(
      PuzzleImageData.all.map((e) => e.assetPath).toList(),
    ));

    // Start fade-out at 4.4 s, navigate at 5 s
    unawaited(Future.delayed(const Duration(milliseconds: 4400), () {
      if (mounted) unawaited(_outController.forward());
    }));
    unawaited(Future.delayed(const Duration(milliseconds: 5000), () {
      if (!mounted) return;
      unawaited(Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          pageBuilder: (context, animation, secondaryAnimation) =>
              ImageSelectionScreen(
            localeNotifier: widget.localeNotifier,
            difficultySettings: widget.difficultySettings,
          ),
          transitionsBuilder: (context, anim, secondaryAnimation, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      ));
    }));
  }

  @override
  void dispose() {
    _inController.dispose();
    _outController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Scale content proportionally so it fits on small landscape screens.
    // 440 is the natural content height at 1× (logo + gaps + title + dots).
    final scale = (size.height / 440).clamp(0.0, 1.0);
    final logoBox = 230.0 * scale;
    final titleFontSize = 48.0 * scale;
    final subtitleFontSize = 18.0 * scale;
    final gapAfterLogo = 32.0 * scale;
    final gapAfterTitle = 14.0 * scale;
    final gapBeforeDots = 48.0 * scale;

    return Scaffold(
      body: Stack(
        children: [
          // ── Background gradient ──────────────────────────────────────────
          Container(decoration: AppTheme.backgroundDecoration),

          // ── Decorative bubbles ──────────────────────────────────────────
          ..._bubbles(size),

          // ── Main content (fades in then out) ───────────────────────────
          AnimatedBuilder(
            animation: Listenable.merge([_inController, _outController]),
            builder: (context, _) {
              final vis =
                  (_fadeIn.value * (1.0 - _fadeOut.value)).clamp(0.0, 1.0);
              return Opacity(
                opacity: vis,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Transform.scale(
                        scale: _scaleIn.value,
                        child: SizedBox(
                          width: logoBox,
                          height: logoBox,
                          child: CustomPaint(
                            painter: LogoPainter(size: logoBox * 0.87),
                          ),
                        ),
                      ),

                      SizedBox(height: gapAfterLogo),

                      // Title with gradient + outline
                      GradientTitle(
                        text: "Lily's Puzzle",
                        fontSize: titleFontSize,
                        strokeWidth: 7,
                      ),

                      SizedBox(height: gapAfterTitle),

                      // Subtitle
                      Text(
                        'Put the pieces together!',
                        style: TextStyle(
                          fontSize: subtitleFontSize,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.92),
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

                      SizedBox(height: gapBeforeDots),

                      // Loading dots
                      const _LoadingDots(),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _bubbles(Size size) {
    const specs = [
      (0.08, 0.10, 64.0, Color(0x30FFFFFF)),
      (0.88, 0.08, 80.0, Color(0x25FFD93D)),
      (0.12, 0.78, 52.0, Color(0x22FF6B9D)),
      (0.82, 0.74, 72.0, Color(0x28FFFFFF)),
      (0.04, 0.48, 42.0, Color(0x20FFD93D)),
      (0.94, 0.42, 56.0, Color(0x30FF6B9D)),
      (0.48, 0.04, 46.0, Color(0x25FFFFFF)),
      (0.52, 0.90, 66.0, Color(0x20FFD93D)),
    ];

    return specs.map((s) {
      final (fx, fy, r, color) = s;
      return Positioned(
        left: size.width * fx - r / 2,
        top: size.height * fy - r / 2,
        child: Container(
          width: r,
          height: r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.20),
            ),
          ),
        ),
      );
    }).toList();
  }
}

// ── Animated loading dots ───────────────────────────────────────────────────

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    unawaited(_ctrl.repeat());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = ((_ctrl.value * 3) - i).clamp(0.0, 1.0);
            final scale = 0.6 + 0.4 * (1 - (phase - 0.5).abs() * 2).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.85),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.deepPurple.withValues(alpha: 0.40),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
