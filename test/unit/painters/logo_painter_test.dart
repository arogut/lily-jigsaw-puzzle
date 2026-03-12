import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/painters/logo_painter.dart';

void main() {
  group('LogoPainter', () {
    test('shouldRepaint returns false when size is unchanged', () {
      const painter = LogoPainter(size: 100);
      expect(painter.shouldRepaint(const LogoPainter(size: 100)), isFalse);
    });

    test('shouldRepaint returns true when size changes', () {
      const painter = LogoPainter(size: 100);
      expect(painter.shouldRepaint(const LogoPainter(size: 200)), isTrue);
    });
  });
}
