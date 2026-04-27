import 'package:flutter/material.dart';

/// Two-panel gradient background used behind the game board and piece tray.
///
/// The left panel uses a blue gradient (board area) and the right panel
/// uses a purple-to-pink gradient (tray area).
class PanelBackgrounds extends StatelessWidget {
  const PanelBackgrounds({super.key});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFB8DEFF), Color(0xFF8EC8F8)],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFD8BAFF), Color(0xFFFFABD0)],
                ),
              ),
            ),
          ),
        ],
      );
}
