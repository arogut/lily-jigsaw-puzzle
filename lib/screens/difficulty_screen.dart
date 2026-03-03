import 'package:flutter/material.dart';

import '../models/puzzle_image.dart';
import 'game_screen.dart';

class DifficultyScreen extends StatelessWidget {
  final PuzzleImageData selectedImage;

  const DifficultyScreen({super.key, required this.selectedImage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                selectedImage.assetPath,
                width: 280,
                height: 210,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Choose Difficulty',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _DifficultyButton(
              label: 'Easy',
              subtitle: '3 × 3',
              gridSize: 3,
              color: Colors.green,
              image: selectedImage,
            ),
            const SizedBox(height: 12),
            _DifficultyButton(
              label: 'Medium',
              subtitle: '5 × 5',
              gridSize: 5,
              color: Colors.orange,
              image: selectedImage,
            ),
            const SizedBox(height: 12),
            _DifficultyButton(
              label: 'Hard',
              subtitle: '7 × 7',
              gridSize: 7,
              color: Colors.red,
              image: selectedImage,
            ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final int gridSize;
  final Color color;
  final PuzzleImageData image;

  const _DifficultyButton({
    required this.label,
    required this.subtitle,
    required this.gridSize,
    required this.color,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GameScreen(
                selectedImage: image,
                gridSize: gridSize,
              ),
            ),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
