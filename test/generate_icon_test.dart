// Run with: flutter test test/generate_icon_test.dart
// Renders the LogoPainter (same as splash screen) to assets/icons/app_icon.png.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lily_jigsaw_puzzle/painters/logo_painter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('render app icon from LogoPainter', () async {
    const iconSize = 1024.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      const Rect.fromLTWH(0, 0, iconSize, iconSize),
    );

    // Draw app gradient background (sky blue → lavender → pink)
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF87CEEB), Color(0xFFB39DDB), Color(0xFFFFABD0)],
        stops: [0.0, 0.50, 1.0],
      ).createShader(const Rect.fromLTWH(0, 0, iconSize, iconSize));
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, iconSize, iconSize),
      bgPaint,
    );

    // Paint the 4-piece jigsaw logo (same as splash screen)
    const LogoPainter(size: 820).paint(canvas, const Size(iconSize, iconSize));

    final picture = recorder.endRecording();
    final image = await picture.toImage(iconSize.toInt(), iconSize.toInt());
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);

    final file = File('assets/icons/app_icon.png');
    file.createSync(recursive: true);
    file.writeAsBytesSync(byteData!.buffer.asUint8List());

    expect(file.existsSync(), isTrue);
    expect(file.lengthSync(), greaterThan(0));
  });
}
