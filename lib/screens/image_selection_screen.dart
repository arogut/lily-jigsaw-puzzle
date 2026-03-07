import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/puzzle_image.dart';
import '../widgets/game_button.dart';
import 'difficulty_screen.dart';

class ImageSelectionScreen extends StatelessWidget {
  const ImageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    GameButton(
                      label: 'Quit',
                      icon: Icons.exit_to_app_rounded,
                      color: const Color(0xFFFF6B6B),
                      shadowColor: const Color(0xFFCC2222),
                      width: 110,
                      height: 44,
                      fontSize: 15,
                      onPressed: () => SystemNavigator.pop(),
                    ),
                    Expanded(child: Center(child: _buildTitle())),
                    const SizedBox(width: 110),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 4 / 3,
                    ),
                    itemCount: PuzzleImageData.all.length,
                    itemBuilder: (context, index) {
                      return _ImageCard(image: PuzzleImageData.all[index]);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    const text = 'Choose a Puzzle!';
    const sz = 30.0;
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: sz,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5
              ..color = const Color(0xFF6A1B9A),
          ),
        ),
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Color(0xFFFFD93D), Color(0xFFFF6B9D)],
          ).createShader(b),
          child: const Text(
            text,
            style: TextStyle(
              fontSize: sz,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Image card ───────────────────────────────────────────────────────────────

class _ImageCard extends StatefulWidget {
  final PuzzleImageData image;
  const _ImageCard({required this.image});

  @override
  State<_ImageCard> createState() => _ImageCardState();
}

class _ImageCardState extends State<_ImageCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 110));
    _scale = Tween(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTap() {
    _ctrl.reverse();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DifficultyScreen(selectedImage: widget.image),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _onTap(),
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.35),
                blurRadius: 4,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Puzzle image
                Image.asset(widget.image.assetPath, fit: BoxFit.cover),

                // Top gloss highlight
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 28,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x44FFFFFF), Color(0x00FFFFFF)],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                  ),
                ),

                // Bottom gradient + name label
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xCC000000), Color(0x00000000)],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(6, 14, 6, 6),
                    child: Text(
                      widget.image.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        shadows: [
                          Shadow(
                            color: Color(0x88000000),
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // White border overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.55),
                        width: 2.5,
                      ),
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
