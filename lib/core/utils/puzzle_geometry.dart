import 'dart:math';

import 'package:flutter/painting.dart';

/// Shared puzzle layout geometry used by painters, hit-testing, and scatter logic.
abstract final class PuzzleGeometry {
  /// Padding between the board/tray and the screen edge, in logical pixels.
  static const edgePad = 20.0;

  /// Tab margin as a fraction of piece dimension.
  static const tabFraction = 0.35;

  /// Horizontal tab extension for a piece of [pieceWidth].
  static double tabWidth(double pieceWidth) => pieceWidth * tabFraction;

  /// Vertical tab extension for a piece of [pieceHeight].
  static double tabHeight(double pieceHeight) => pieceHeight * tabFraction;

  /// Canvas origin for a piece at [currentPosition] (includes tab margin).
  static Offset pieceOrigin(Offset currentPosition, double pieceWidth, double pieceHeight) =>
      Offset(
        currentPosition.dx - tabWidth(pieceWidth),
        currentPosition.dy - tabHeight(pieceHeight),
      );

  /// Canvas size needed to render a piece including tab extensions.
  static Size pieceCanvasSize(double pieceWidth, double pieceHeight) {
    final tabW = tabWidth(pieceWidth);
    final tabH = tabHeight(pieceHeight);
    return Size(pieceWidth + 2 * tabW, pieceHeight + 2 * tabH);
  }

  /// Bounds of the right-side piece tray for physics simulation.
  static Rect trayBounds(Size screenSize) => Rect.fromLTRB(
        screenSize.width / 2 + edgePad,
        0,
        screenSize.width - edgePad,
        screenSize.height,
      );

  /// Returns random scatter target positions spread across the right-half tray.
  static List<Offset> randomScatterTargets({
    required int pieceCount,
    required Size screenSize,
    required double pieceWidth,
    required double pieceHeight,
    Random? random,
  }) {
    final rng = random ?? Random();
    const margin = edgePad;
    final trayLeft = screenSize.width / 2 + margin;
    final trayRight = screenSize.width - margin - pieceWidth;
    const trayTop = margin;
    final trayBottom = screenSize.height - margin - pieceHeight;
    return List.generate(pieceCount, (_) {
      return Offset(
        trayLeft +
            rng.nextDouble() * (trayRight - trayLeft).clamp(0, double.infinity),
        trayTop +
            rng.nextDouble() * (trayBottom - trayTop).clamp(0, double.infinity),
      );
    });
  }

  /// Returns a random position in the tray for a piece return animation.
  static Offset randomTrayPosition({
    required Size screenSize,
    required double pieceWidth,
    required double pieceHeight,
    Random? random,
  }) {
    final rng = random ?? Random();
    const margin = edgePad;
    final trayX = (screenSize.width / 2 + margin) +
        rng.nextDouble() *
            (screenSize.width / 2 - margin * 2 - pieceWidth)
                .clamp(0, double.infinity);
    final trayY = margin +
        rng.nextDouble() *
            (screenSize.height - margin * 2 - pieceHeight)
                .clamp(0, double.infinity);
    return Offset(trayX, trayY);
  }
}
