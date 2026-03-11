import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

class SoundService {
  factory SoundService() => _instance;
  SoundService._internal();

  static final SoundService _instance = SoundService._internal();

  Future<void> playSnap() => _play('sounds/snap.wav');
  Future<void> playWrong() => _play('sounds/wrong.wav');
  Future<void> playWin() => _play('sounds/win.wav');
  Future<void> playClick() => _play('sounds/click.wav');

  Future<void> _play(String asset) async {
    final player = AudioPlayer();
    await player.setReleaseMode(ReleaseMode.release);
    await player.play(AssetSource(asset));
  }
}
