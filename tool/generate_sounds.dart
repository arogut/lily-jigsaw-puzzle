// ignore_for_file: avoid_print // standalone build tool; print output is intentional

// Generates synthetic WAV sound effects for the jigsaw puzzle game.
// WAV format: 16-bit signed PCM, mono, 22050 Hz sample rate.
// Run with: dart run tool/generate_sounds.dart

import 'dart:io';
import 'dart:math' show pi, sin;
import 'dart:typed_data';

const int _sampleRate = 22050;

// Writes a standard RIFF/WAVE header followed by the given PCM samples.
List<int> _buildWav(List<int> samples) {
  final dataBytes = samples.length * 2; // 16-bit = 2 bytes/sample
  final fileSize = 44 + dataBytes;
  final buf = ByteData(fileSize)
    // RIFF chunk
    ..setUint8(0, 0x52) // 'R'
    ..setUint8(1, 0x49) // 'I'
    ..setUint8(2, 0x46) // 'F'
    ..setUint8(3, 0x46) // 'F'
    ..setUint32(4, fileSize - 8, Endian.little) // chunk size
    ..setUint8(8, 0x57) // 'W'
    ..setUint8(9, 0x41) // 'A'
    ..setUint8(10, 0x56) // 'V'
    ..setUint8(11, 0x45) // 'E'
    // fmt sub-chunk
    ..setUint8(12, 0x66) // 'f'
    ..setUint8(13, 0x6D) // 'm'
    ..setUint8(14, 0x74) // 't'
    ..setUint8(15, 0x20) // ' '
    ..setUint32(16, 16, Endian.little) // sub-chunk size (PCM)
    ..setUint16(20, 1, Endian.little) // audio format = PCM
    ..setUint16(22, 1, Endian.little) // num channels = mono
    ..setUint32(24, _sampleRate, Endian.little)
    ..setUint32(28, _sampleRate * 2, Endian.little) // byte rate
    ..setUint16(32, 2, Endian.little) // block align
    ..setUint16(34, 16, Endian.little) // bits per sample
    // data sub-chunk
    ..setUint8(36, 0x64) // 'd'
    ..setUint8(37, 0x61) // 'a'
    ..setUint8(38, 0x74) // 't'
    ..setUint8(39, 0x61) // 'a'
    ..setUint32(40, dataBytes, Endian.little);

  for (var i = 0; i < samples.length; i++) {
    buf.setInt16(44 + i * 2, samples[i].clamp(-32768, 32767), Endian.little);
  }

  return buf.buffer.asUint8List();
}

// Clamps a double sample [-1,1] to int16 range.
int _toInt16(double v) => (v * 32767).clamp(-32768, 32767).toInt();

// ── snap.wav ─────────────────────────────────────────────────────────────────
// Pleasant ascending ping: 880Hz → 1047Hz over 0.3s with quick attack and
// exponential decay.
List<int> _generateSnap() {
  const duration = 0.30;
  final n = (duration * _sampleRate).round();
  final samples = <int>[];
  for (var i = 0; i < n; i++) {
    final t = i / _sampleRate;
    final progress = t / duration;
    // Frequency sweep
    final freq = 880.0 + (1047.0 - 880.0) * progress;
    // Envelope: sharp linear attack for first 5%, then exponential decay
    final envelope = progress < 0.05
        ? progress / 0.05
        : (1.0 - (progress - 0.05) / 0.95) * (1.0 - progress);
    final sample = sin(2 * pi * freq * t) * envelope;
    samples.add(_toInt16(sample));
  }
  return samples;
}

// ── wrong.wav ─────────────────────────────────────────────────────────────────
// Descending buzz: 300Hz → 180Hz over 0.25s.
List<int> _generateWrong() {
  const duration = 0.25;
  final n = (duration * _sampleRate).round();
  final samples = <int>[];
  for (var i = 0; i < n; i++) {
    final t = i / _sampleRate;
    final progress = t / duration;
    final freq = 300.0 - (300.0 - 180.0) * progress;
    final envelope = 1.0 - progress;
    final sample = sin(2 * pi * freq * t) * envelope * 0.7;
    samples.add(_toInt16(sample));
  }
  return samples;
}

// ── win.wav ───────────────────────────────────────────────────────────────────
// Happy ascending arpeggio: C5(523Hz), E5(659Hz), G5(784Hz), C6(1047Hz),
// each 0.18s.
List<int> _generateWin() {
  const toneDuration = 0.18;
  const tones = [523.0, 659.0, 784.0, 1047.0];
  final samples = <int>[];
  for (var ti = 0; ti < tones.length; ti++) {
    final freq = tones[ti];
    final n = (toneDuration * _sampleRate).round();
    for (var i = 0; i < n; i++) {
      final t = i / _sampleRate;
      final progress = t / toneDuration;
      // Short attack, then decay
      final envelope = progress < 0.10
          ? progress / 0.10
          : 1.0 - (progress - 0.10) / 0.90 * 0.5;
      final sample = sin(2 * pi * freq * t) * envelope * 0.8;
      samples.add(_toInt16(sample));
    }
  }
  return samples;
}

// ── click.wav ─────────────────────────────────────────────────────────────────
// Short tick: 800Hz, 0.08s, sharp decay.
List<int> _generateClick() {
  const duration = 0.08;
  final n = (duration * _sampleRate).round();
  const freq = 800.0;
  final samples = <int>[];
  for (var i = 0; i < n; i++) {
    final t = i / _sampleRate;
    final progress = t / duration;
    final envelope = 1.0 - progress;
    final sample = sin(2 * pi * freq * t) * envelope * 0.6;
    samples.add(_toInt16(sample));
  }
  return samples;
}

void main() {
  const outDir = 'assets/sounds';

  final files = <String, List<int>>{
    '$outDir/snap.wav': _generateSnap(),
    '$outDir/wrong.wav': _generateWrong(),
    '$outDir/win.wav': _generateWin(),
    '$outDir/click.wav': _generateClick(),
  };

  for (final entry in files.entries) {
    final wavBytes = _buildWav(entry.value);
    File(entry.key).writeAsBytesSync(wavBytes);
    print('Written ${entry.key} (${wavBytes.length} bytes)');
  }

  print('Done.');
}
