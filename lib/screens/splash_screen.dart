import 'package:flutter/material.dart';

import '../main.dart';
import '../painters/logo_painter.dart';
import 'image_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  final LocaleNotifier localeNotifier;

  const SplashScreen({super.key, required this.localeNotifier});

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
    _scaleIn = Tween(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(parent: _inController, curve: Curves.elasticOut),
    );
    _fadeOut =
        CurvedAnimation(parent: _outController, curve: Curves.easeIn);

    _inController.forward();

    // Start fade-out at 4.4 s, navigate at 5 s
    Future.delayed(const Duration(milliseconds: 4400), () {
      if (mounted) _outController.forward();
    });
    Future.delayed(const Duration(milliseconds: 5000), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              ImageSelectionScreen(localeNotifier: widget.localeNotifier),
          transitionsBuilder: (context, anim, secondaryAnimation, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    });
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

    return Scaffold(
      body: Stack(
        children: [
          // ── Background gradient ──────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF87CEEB), // sky blue
                  Color(0xFFB39DDB), // lavender
                  Color(0xFFFFABD0), // baby pink
                ],
                stops: [0.0, 0.50, 1.0],
              ),
            ),
          ),

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
                          width: 230,
                          height: 230,
                          child: CustomPaint(
                            painter: LogoPainter(size: 200),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Title with gradient + outline
                      const _Title(),

                      const SizedBox(height: 14),

                      // Subtitle
                      Text(
                        'Put the pieces together!',
                        style: TextStyle(
                          fontSize: 18,
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

                      const SizedBox(height: 48),

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
              width: 1,
            ),
          ),
        ),
      );
    }).toList();
  }
}

// ── Title widget ────────────────────────────────────────────────────────────

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    const text = "Lily's Puzzle";
    const size = 48.0;
    const spacing = 2.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Purple stroke outline
        Text(
          text,
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w900,
            letterSpacing: spacing,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 7
              ..color = const Color(0xFF6A1B9A),
          ),
        ),
        // Gradient fill
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFFD93D), Color(0xFFFF6B9D)],
          ).createShader(bounds),
          child: const Text(
            text,
            style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: spacing,
            ),
          ),
        ),
      ],
    );
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
    )..repeat();
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
                        color: const Color(0xFF6A1B9A).withValues(alpha: 0.40),
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
