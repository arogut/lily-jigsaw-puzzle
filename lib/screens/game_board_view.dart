import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:lily_jigsaw_puzzle/core/app_theme.dart';
import 'package:lily_jigsaw_puzzle/core/widgets/panel_backgrounds.dart';
import 'package:lily_jigsaw_puzzle/l10n/app_localizations.dart';
import 'package:lily_jigsaw_puzzle/models/game_state.dart';
import 'package:lily_jigsaw_puzzle/painters/all_pieces_painter.dart';
import 'package:lily_jigsaw_puzzle/painters/board_grid_painter.dart';
import 'package:lily_jigsaw_puzzle/painters/board_shadow_painter.dart';
import 'package:lily_jigsaw_puzzle/painters/confetti_painter.dart';
import 'package:lily_jigsaw_puzzle/painters/hint_glow_painter.dart';
import 'package:lily_jigsaw_puzzle/widgets/game_button.dart';
import 'package:lily_jigsaw_puzzle/widgets/tray_label.dart';
import 'package:lily_jigsaw_puzzle/widgets/win_overlay.dart';

/// Padding between the board/tray and the screen edge, in logical pixels.
const double kEdgePad = 20;

/// Renders the full game UI for an active puzzle session.
///
/// Stateless — all mutable state lives in [GameState] and the animation
/// controllers owned by the parent GameScreen.
class GameBoardView extends StatelessWidget {
  const GameBoardView({
    required this.gameState,
    required this.uiImage,
    required this.paintTick,
    required this.hintController,
    required this.confettiParticles,
    required this.confettiController,
    required this.showWinOverlay,
    required this.onBack,
    required this.onPlayAgain,
    required this.onNewPuzzle,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onHint,
    super.key,
  });

  /// Active puzzle state; drives all phase checks, board geometry, and piece rendering.
  final GameState gameState;

  /// Decoded puzzle image rendered across all piece faces.
  final ui.Image uiImage;

  /// Repaint notifier incremented by the parent whenever pieces move.
  final ValueNotifier<int> paintTick;

  /// Animation driving the hint-glow pulse effect.
  final Animation<double> hintController;

  /// Particle list fed to [ConfettiPainter] when the puzzle is won.
  final List<ConfettiParticle> confettiParticles;

  /// Animation driving the confetti particle simulation.
  final Animation<double> confettiController;

  /// When `true`, shows [WinOverlay]; when `false`, shows the confetti layer.
  final bool showWinOverlay;

  /// Called when the user taps the back button.
  final VoidCallback onBack;

  /// Called when the user taps "Play Again" from the win overlay.
  final VoidCallback onPlayAgain;

  /// Called when the user taps "New Puzzle" from the win overlay.
  final VoidCallback onNewPuzzle;

  /// Called at the start of a drag gesture over the piece layer.
  final GestureDragStartCallback? onPanStart;

  /// Called as a drag gesture moves over the piece layer.
  final GestureDragUpdateCallback? onPanUpdate;

  /// Called when a drag gesture ends over the piece layer.
  final GestureDragEndCallback? onPanEnd;

  /// Null when hints are unavailable — drives both the enabled state and
  /// opacity of the hint button.
  final VoidCallback? onHint;

  @override
  Widget build(BuildContext context) {
    final gs = gameState;
    final l10n = AppLocalizations.of(context)!;
    final boardOffX = gs.boardOffset.dx;
    final boardOffY = gs.boardOffset.dy;
    final boardW = gs.boardSize.width;
    final boardH = gs.boardSize.height;
    final dividerX = boardOffX + boardW + kEdgePad;

    return Stack(
      children: [
        const Positioned.fill(child: PanelBackgrounds()),
        Positioned(
          left: boardOffX, top: boardOffY, width: boardW, height: boardH,
          child: CustomPaint(painter: BoardGridPainter(gs.gridSize)),
        ),
        if (gs.phase == GamePhase.scattering || gs.phase == GamePhase.playing)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: BoardShadowPainter(
                  pieces: gs.pieces,
                  pieceWidth: gs.pieceWidth,
                  pieceHeight: gs.pieceHeight,
                ),
              ),
            ),
          ),
        _buildDivider(dividerX),
        _buildPieceLayer(gs),
        if (gs.phase == GamePhase.playing && gs.hasActiveHint)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: HintGlowPainter(
                  pieces: gs.pieces,
                  pieceWidth: gs.pieceWidth,
                  pieceHeight: gs.pieceHeight,
                  animation: hintController,
                ),
              ),
            ),
          ),
        Positioned(
          left: 8, top: 8,
          child: GameButton(
            label: l10n.back,
            icon: Icons.arrow_back_rounded,
            color: AppColors.mediumPurple,
            width: 120,
            height: 44,
            fontSize: 15,
            onPressed: onBack,
          ),
        ),
        _buildRightControls(gs, l10n),
        if (gs.phase == GamePhase.won && !showWinOverlay)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: ConfettiPainter(
                  particles: confettiParticles,
                  animation: confettiController,
                ),
              ),
            ),
          ),
        if (gs.phase == GamePhase.won && showWinOverlay)
          WinOverlay(
            onPlayAgain: onPlayAgain,
            onNewPuzzle: onNewPuzzle,
          ),
      ],
    );
  }

  Widget _buildDivider(double x) => Positioned(
        left: x - 4,
        top: 0,
        bottom: 0,
        width: 8,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.hotPink,
                Color(0xFFFFD93D),
                AppColors.green,
                AppColors.blue,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      );

  Widget _buildPieceLayer(GameState gs) => Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: onPanStart,
          onPanUpdate: onPanUpdate,
          onPanEnd: onPanEnd,
          child: CustomPaint(
            painter: AllPiecesPainter(
              pieces: gs.pieces,
              image: uiImage,
              pieceWidth: gs.pieceWidth,
              pieceHeight: gs.pieceHeight,
              repaintNotifier: paintTick,
              hasActiveHint: gs.hasActiveHint,
            ),
          ),
        ),
      );

  Widget _buildRightControls(GameState gs, AppLocalizations l10n) => Positioned(
        right: kEdgePad,
        top: 8,
        child: ListenableBuilder(
          listenable: gs,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Opacity(
                  opacity: onHint != null ? 1.0 : 0.5,
                  child: GameButton(
                    label: '${l10n.hint} (${gs.hintsRemaining})',
                    icon: Icons.lightbulb_outline,
                    color: AppColors.amber,
                    width: 120,
                    height: 44,
                    fontSize: 15,
                    enabled: onHint != null,
                    onPressed: onHint ?? () {},
                  ),
                ),
              ),
              TrayLabel(
                placed: gs.pieces.where((p) => p.isPlaced).length,
                total: gs.pieces.length,
              ),
            ],
          ),
        ),
      );
}
