import 'dart:async';
import 'dart:math' show pi, sin;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter/services.dart';

import 'package:lily_jigsaw_puzzle/controllers/game_controller.dart';
import 'package:lily_jigsaw_puzzle/core/app_theme.dart';
import 'package:lily_jigsaw_puzzle/core/utils/puzzle_geometry.dart';
import 'package:lily_jigsaw_puzzle/models/game_state.dart';
import 'package:lily_jigsaw_puzzle/models/puzzle_image.dart';
import 'package:lily_jigsaw_puzzle/models/puzzle_piece.dart';
import 'package:lily_jigsaw_puzzle/painters/confetti_painter.dart';
import 'package:lily_jigsaw_puzzle/painters/jigsaw_piece_painter.dart';
import 'package:lily_jigsaw_puzzle/screens/game_board_view.dart';
import 'package:lily_jigsaw_puzzle/services/hint_settings_service.dart';
import 'package:lily_jigsaw_puzzle/services/sound_service.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    required this.selectedImage,
    required this.gridSize,
    required this.difficultyStars,
    required this.hintSettings,
    super.key,
  });

  final PuzzleImageData selectedImage;
  final int gridSize;

  /// Stars awarded for completing this difficulty (1 = easy, 2 = medium, 3 = hard).
  final int difficultyStars;

  /// Hint unlock configuration for this session.
  final HintSettings hintSettings;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  GameState? _gameState;
  ui.Image? _uiImage;
  late final GameController _controller;

  late AnimationController _scatterController;
  late AnimationController _returnController;
  List<Offset>? _assembledPositions;
  List<Offset>? _scatterTargets;

  PuzzlePiece? _returningPiece;
  Offset _returnFromPos = Offset.zero;
  Offset _returnToPos = Offset.zero;

  bool _dragCrossedLeft = false;

  final _paintTick = ValueNotifier<int>(0);

  late AnimationController _confettiController;
  List<ConfettiParticle> _confettiParticles = const [];
  bool _showWinOverlay = false;

  late AnimationController _hintController;

  late AnimationController _hintAvailableController;
  late Animation<double> _hintAvailableAnimation;

  late AnimationController _hintsExhaustedController;
  late Animation<double> _hintsExhaustedAnimation;

  late Ticker _physicsTicker;
  Duration? _lastPhysicsTime;

  @override
  void initState() {
    super.initState();
    _controller = GameController(
      hintSettings: widget.hintSettings,
      onHintTimerElapsed: () {
        _gameState?.markNextSlotAvailable();
        _controller.onHintSlotAvailable();
        _hintAvailableController.reset();
        unawaited(_hintAvailableController.forward());
      },
    )..addListener(() {
        if (mounted) setState(() {});
      });

    WidgetsBinding.instance.addObserver(this);
    _scatterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _returnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _returnController.addListener(_onReturnTick);
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    unawaited(_hintController.repeat());

    _hintAvailableController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _hintAvailableAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 1.25), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 0.9), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.05), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1), weight: 20),
    ]).animate(_hintAvailableController);

    _hintsExhaustedController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _hintsExhaustedAnimation = Tween<double>(begin: 1, end: 0)
        .animate(CurvedAnimation(
      parent: _hintsExhaustedController,
      curve: Curves.easeIn,
    ));

    _physicsTicker = createTicker(_onPhysicsTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_uiImage == null) unawaited(_loadImage());
    if (_uiImage != null && _gameState == null) _initGame();
  }

  Future<void> _loadImage() async {
    final size = MediaQuery.of(context).size;
    final targetW =
        ((size.width / 2) - 2 * PuzzleGeometry.edgePad).round().clamp(64, 2048);

    final data = await rootBundle.load(widget.selectedImage.assetPath);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: targetW,
    );
    final frame = await codec.getNextFrame();

    if (!mounted) return;
    setState(() {
      _uiImage = frame.image;
    });
  }

  void _initGame() {
    final size = MediaQuery.of(context).size;
    const boardOffset = Offset(PuzzleGeometry.edgePad, PuzzleGeometry.edgePad);
    final boardSize = Size(
      size.width / 2 - 2 * PuzzleGeometry.edgePad,
      size.height - 2 * PuzzleGeometry.edgePad,
    );

    _gameState = GameState(
      puzzleImage: _uiImage!,
      gridSize: widget.gridSize,
      boardSize: boardSize,
      boardOffset: boardOffset,
      immediateMode: widget.hintSettings.immediateMode,
    );
    _assembledPositions =
        _gameState!.pieces.map((p) => p.targetPosition).toList();

    Future.delayed(const Duration(seconds: 1), _startScatter);
  }

  void _startScatter() {
    if (!mounted || _gameState == null) return;
    final size = MediaQuery.of(context).size;

    _scatterTargets = _gameState!.computeScatterTargets(size);

    _gameState!.beginScattering();
    setState(() {});

    _scatterController
      ..reset()
      ..addListener(_onScatterTick)
      ..addStatusListener(_onScatterStatus);
    unawaited(_scatterController.forward());
  }

  void _onScatterTick() {
    if (_gameState == null ||
        _scatterTargets == null ||
        _assembledPositions == null) {
      return;
    }
    final t = _scatterController.value;
    final n = _gameState!.pieces.length;

    for (var i = 0; i < n; i++) {
      final slotWidth = 1.0 / n;
      final startI = i * slotWidth;
      final endI = (startI + slotWidth * 1.5).clamp(0.0, 1.0);
      final localT =
          endI == startI ? 1.0 : ((t - startI) / (endI - startI)).clamp(0.0, 1.0);
      final curved = Curves.easeInOut.transform(localT);
      _gameState!.setPiecePosition(
        i,
        Offset.lerp(_assembledPositions![i], _scatterTargets![i], curved)!,
      );
    }
    _paintTick.value++;
  }

  void _onScatterStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _lastPhysicsTime = null;
      if (!_physicsTicker.isActive) unawaited(_physicsTicker.start());

      if (mounted && _gameState != null) {
        _gameState!.beginPlaying();
        _controller.onScatterComplete();
        setState(() {});
      }
    }
  }

  void _onPhysicsTick(Duration elapsed) {
    if (_gameState == null) return;

    final previous = _lastPhysicsTime;
    _lastPhysicsTime = elapsed;
    if (previous == null) return;

    final dtMicro = elapsed.inMicroseconds - previous.inMicroseconds;
    final dt = (dtMicro / 1e6).clamp(0.0, 0.05);

    final size = MediaQuery.of(context).size;
    final changed =
        _gameState!.stepPhysics(dt, PuzzleGeometry.trayBounds(size));
    if (changed) _paintTick.value++;
  }

  int? _hitTestPiece(Offset localPos) {
    final gs = _gameState;
    if (gs == null) return null;
    for (var i = gs.pieces.length - 1; i >= 0; i--) {
      final piece = gs.pieces[i];
      if (piece.isPlaced) continue;
      if (piece == _returningPiece) continue;
      final origin = PuzzleGeometry.pieceOrigin(
        piece.currentPosition,
        gs.pieceWidth,
        gs.pieceHeight,
      );
      final path = JigsawPiecePainter.buildPiecePath(
        piece.edges,
        gs.pieceWidth,
        gs.pieceHeight,
      );
      if (path.contains(localPos - origin)) return i;
    }
    return null;
  }

  void _onPanStart(DragStartDetails d) {
    final gs = _gameState!;
    final idx = _hitTestPiece(d.localPosition);
    if (idx == null) return;
    if (gs.hasActiveHint && !gs.pieces[idx].isHinted) return;
    unawaited(HapticFeedback.lightImpact());
    gs.startDrag(idx);
    _dragCrossedLeft = false;
    _paintTick.value++;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final gs = _gameState!;
    if (gs.draggingIndex == null) return;
    gs.updateDrag(d.delta);
    final piece = gs.pieces[gs.draggingIndex!];
    if (piece.currentPosition.dx < MediaQuery.of(context).size.width / 2) {
      _dragCrossedLeft = true;
    }
    _paintTick.value++;
  }

  void _onPanEnd(DragEndDetails d) {
    final gs = _gameState!;
    if (gs.draggingIndex == null) return;
    final piece = gs.pieces[gs.draggingIndex!];
    if ((piece.currentPosition - piece.targetPosition).distance <=
        kSnapThreshold) {
      gs.endDrag();
      unawaited(SoundService().playSnap());
      if (gs.phase == GamePhase.won) {
        _controller.cancelHintTimer();
        unawaited(_recordCompletion());
        unawaited(SoundService().playWin());
        _startConfetti();
      } else {
        _controller.onSuccessfulSnap(gs);
        setState(() {});
      }
    } else if (_dragCrossedLeft) {
      _controller.onWrongBoardDrop(gs);
      unawaited(HapticFeedback.mediumImpact());
      unawaited(SoundService().playWrong());
      gs.endDragNoPlace();
      _startReturnAnimation(piece);
    } else {
      gs.endDragNoPlace();
      if (!_snapToTrayIfOutside(piece, MediaQuery.of(context).size)) {
        _paintTick.value++;
      }
    }
  }

  void _onReturnTick() {
    final piece = _returningPiece;
    if (piece == null) return;
    final t = _returnController.value;

    if (t <= 0.40) {
      final st = t / 0.40;
      final shake = sin(st * pi * 4) * 14.0;
      piece.currentPosition = Offset(_returnFromPos.dx + shake, _returnFromPos.dy);
    } else {
      final rt = Curves.easeOut.transform((t - 0.40) / 0.60);
      piece.currentPosition = Offset.lerp(_returnFromPos, _returnToPos, rt)!;
    }
    _paintTick.value++;
  }

  void _startReturnAnimation(PuzzlePiece piece) {
    final size = MediaQuery.of(context).size;
    final gs = _gameState!;

    _returningPiece = piece;
    _returnFromPos = piece.currentPosition;
    _returnToPos = PuzzleGeometry.randomTrayPosition(
      screenSize: size,
      pieceWidth: gs.pieceWidth,
      pieceHeight: gs.pieceHeight,
    );

    _returnController.reset();
    unawaited(_returnController.forward().then((_) {
      if (mounted) setState(() => _returningPiece = null);
    }));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller
      ..disposeController()
      ..dispose();
    _physicsTicker.dispose();
    _scatterController
      ..removeListener(_onScatterTick)
      ..removeStatusListener(_onScatterStatus)
      ..dispose();
    _returnController
      ..removeListener(_onReturnTick)
      ..dispose();
    _confettiController.dispose();
    _hintController.dispose();
    _hintAvailableController.dispose();
    _hintsExhaustedController.dispose();
    _paintTick.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _controller.onLifecycleChange(state, _gameState);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF9BC8E8),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final img = _uiImage;
    if (img == null) return _buildLoading();

    final gs = _gameState;
    if (gs == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _gameState == null) _initGame();
      });
      return _buildLoading();
    }

    final isPlaying = gs.phase == GamePhase.playing;
    final showHintExitArea =
        isPlaying && gs.currentHintSlot == null && _controller.showingHintArea;

    return GameBoardView(
      gameState: gs,
      uiImage: img,
      paintTick: _paintTick,
      hintController: _hintController,
      confettiParticles: _confettiParticles,
      confettiController: _confettiController,
      showWinOverlay: _showWinOverlay,
      streakRecord: _controller.streakRecord,
      onBack: () => Navigator.of(context).popUntil((r) => r.isFirst),
      onPlayAgain: _restartGame,
      onNewPuzzle: () => Navigator.of(context).popUntil((r) => r.isFirst),
      onPanStart: isPlaying ? _onPanStart : null,
      onPanUpdate: isPlaying ? _onPanUpdate : null,
      onPanEnd: isPlaying ? _onPanEnd : null,
      currentHintSlot: isPlaying ? gs.currentHintSlot : null,
      hintAvailableAnimation: isPlaying ? _hintAvailableAnimation : null,
      hintsExhaustedAnimation:
          showHintExitArea ? _hintsExhaustedAnimation : null,
      showHintArea: showHintExitArea,
      onHint: _onHintTapped,
    );
  }

  Widget _buildLoading() {
    return Container(
      decoration: AppTheme.backgroundDecoration,
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 4),
      ),
    );
  }

  void _restartGame() {
    _controller.resetSession();
    _physicsTicker.stop();
    _lastPhysicsTime = null;
    _scatterController
      ..removeListener(_onScatterTick)
      ..removeStatusListener(_onScatterStatus);
    _confettiController.stop();
    _hintsExhaustedController.reset();
    setState(() {
      _gameState = null;
      _assembledPositions = null;
      _scatterTargets = null;
      _showWinOverlay = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initGame();
    });
  }

  Future<void> _recordCompletion() async {
    await _controller.recordWin(
      widget.selectedImage.uuid,
      widget.difficultyStars,
    );
  }

  bool _snapToTrayIfOutside(PuzzlePiece piece, Size screenSize) {
    final gs = _gameState!;
    final cx = piece.currentPosition.dx + gs.pieceWidth / 2;
    final cy = piece.currentPosition.dy + gs.pieceHeight / 2;
    if (cx <= screenSize.width && cy >= 0 && cy <= screenSize.height) {
      return false;
    }
    _startReturnAnimation(piece);
    return true;
  }

  void _onHintTapped() {
    final gs = _gameState;
    if (gs == null) return;
    final exhausted = _controller.onHintTapped(gs);
    if (exhausted) {
      _hintsExhaustedController.reset();
      unawaited(_hintsExhaustedController.forward().then((_) {
        if (mounted) _controller.markHintAreaHidden();
      }));
    }
    setState(() {});
  }

  void _startConfetti() {
    _physicsTicker.stop();
    _confettiParticles = generateConfettiParticles(250);
    setState(() {});
    _confettiController.reset();
    unawaited(_confettiController.forward().then((_) {
      if (mounted) setState(() => _showWinOverlay = true);
    }));
  }
}
