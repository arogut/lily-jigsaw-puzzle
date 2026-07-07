import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

class SoundService {
  factory SoundService() => _instance;
  SoundService._internal();

  static final SoundService _instance = SoundService._internal();

  final Map<String, AudioPlayer> _players = {};

  AudioPlayer _playerFor(String asset) =>
      _players.putIfAbsent(asset, AudioPlayer.new);

  /// Plays the snap sound effect when a piece locks into its slot.
  Future<void> playSnap() => _play('sounds/snap.wav');

  /// Plays the wrong-placement sound effect when a piece is returned to the tray.
  Future<void> playWrong() => _play('sounds/wrong.wav');

  /// Plays the win fanfare when the puzzle is completed.
  Future<void> playWin() => _play('sounds/win.wav');

  /// Plays the click sound effect for UI button interactions.
  Future<void> playClick() => _play('sounds/click.wav');

  /// Plays the sound effect signalling that a hint slot has become available.
  Future<void> playHintAvailable() => _play('sounds/hint_available.wav');

  /// Plays the sound effect signalling that all hint slots have been exhausted.
  Future<void> playHintsExhausted() => _play('sounds/hints_exhausted.wav');

  Future<void> _play(String asset) async {
    final player = _playerFor(asset);
    await player.setReleaseMode(ReleaseMode.release);
    await player.setReleaseMode(ReleaseMode.stop);
    await player.stop();
    await player.play(AssetSource(asset));
  }
}
