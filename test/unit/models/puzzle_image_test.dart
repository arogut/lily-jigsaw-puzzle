import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/models/puzzle_image.dart';

void main() {
  group('PuzzleImageData', () {
    test('all list has exactly 5 items', () {
      expect(PuzzleImageData.all.length, 5);
    });

    test('all items have non-empty names', () {
      for (final img in PuzzleImageData.all) {
        expect(img.name.isNotEmpty, isTrue);
      }
    });

    test('all items have asset paths under assets/images/', () {
      for (final img in PuzzleImageData.all) {
        expect(img.assetPath.startsWith('assets/images/'), isTrue);
      }
    });

    test('all asset paths are unique', () {
      final paths = PuzzleImageData.all.map((e) => e.assetPath).toList();
      expect(paths.toSet().length, paths.length);
    });

    test('all names are unique', () {
      final names = PuzzleImageData.all.map((e) => e.name).toList();
      expect(names.toSet().length, names.length);
    });

    test('contains expected puzzle names', () {
      final names = PuzzleImageData.all.map((e) => e.name).toSet();
      expect(names, containsAll(['Garden', 'Animals', 'Ocean', 'Space', 'Castle']));
    });

    test('constructor stores values correctly', () {
      const img = PuzzleImageData(assetPath: 'assets/test.jpg', name: 'Test');
      expect(img.assetPath, 'assets/test.jpg');
      expect(img.name, 'Test');
    });
  });
}
