import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:lily_jigsaw_puzzle/models/celebration_style.dart';

/// Plays short sound effects for game events.
class SoundService {
  factory SoundService() => _instance;
  SoundService._internal();

  static final SoundService _instance = SoundService._internal();

  final Map<String, AudioPlayer> _players = {};
  String? _activeFanfareAsset;

  AudioPlayer _playerFor(String asset) =>
      _players.putIfAbsent(asset, AudioPlayer.new);

  /// Plays the snap sound effect when a piece locks into its slot.
  Future<void> playSnap() => _play('sounds/snap.wav');

  /// Plays the wrong-placement sound effect when a piece is returned to the tray.
  Future<void> playWrong() => _play('sounds/wrong.wav');

  /// Plays the win fanfare for [style], looping until [stopWinFanfare].
  Future<void> playWinFanfare(CelebrationStyleId style) async {
    await stopWinFanfare();
    final asset = style.audioAsset;
    _activeFanfareAsset = asset;
    try {
      final player = _playerFor(asset);
      await player.setReleaseMode(ReleaseMode.loop);
      await player.stop();
      await player.play(AssetSource(asset));
    } on Object {
      // Audio may be unavailable; visuals continue without sound.
    }
  }

  /// Stops the active win fanfare immediately.
  Future<void> stopWinFanfare() async {
    final asset = _activeFanfareAsset;
    _activeFanfareAsset = null;
    if (asset == null) return;
    await _stopPlayer(asset);
  }

  Future<void> _stopPlayer(String asset) async {
    try {
      await _playerFor(asset).stop();
    } on Object {
      // Ignore stop failures when audio is unavailable.
    }
  }

  /// Plays the legacy win fanfare using the confetti style.
  Future<void> playWin() => playWinFanfare(CelebrationStyleId.confetti);

  /// Plays the click sound effect for UI button interactions.
  Future<void> playClick() => _play('sounds/click.wav');

  /// Plays the sound effect signalling that a hint slot has become available.
  Future<void> playHintAvailable() => _play('sounds/hint_available.wav');

  /// Plays the sound effect signalling that all hint slots have been exhausted.
  Future<void> playHintsExhausted() => _play('sounds/hints_exhausted.wav');

  Future<void> _play(String asset) async {
    try {
      final player = _playerFor(asset);
      await player.setReleaseMode(ReleaseMode.stop);
      await player.stop();
      await player.play(AssetSource(asset));
    } on Object {
      // Audio may be unavailable in tests or when muted.
    }
  }
}
