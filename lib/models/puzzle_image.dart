import 'package:uuid/uuid.dart';

class PuzzleImageData {
  final String assetPath;
  final String name; // fallback English name
  final String uuid; // deterministic UUID generated from asset path

  const PuzzleImageData({
    required this.assetPath,
    required this.name,
    required this.uuid,
  });

  // Private namespace UUID used for v5 generation (arbitrary, stable).
  static const _ns = '3c3d63d7-0de7-4b57-8e7f-a9a1b9c2d7e5';

  static final List<PuzzleImageData> all = _buildAll();

  static List<PuzzleImageData> _buildAll() {
    const uuidGen = Uuid();
    String id(String path) => uuidGen.v5(_ns, path);

    return [
      PuzzleImageData(assetPath: 'assets/images/puzzle-1.jpg', name: 'Cat',      uuid: id('assets/images/puzzle-1.jpg')),
      PuzzleImageData(assetPath: 'assets/images/puzzle-2.jpg', name: 'Dog',      uuid: id('assets/images/puzzle-2.jpg')),
      PuzzleImageData(assetPath: 'assets/images/puzzle-3.jpg', name: 'Forest',   uuid: id('assets/images/puzzle-3.jpg')),
      PuzzleImageData(assetPath: 'assets/images/puzzle-4.jpg', name: 'City',     uuid: id('assets/images/puzzle-4.jpg')),
      PuzzleImageData(assetPath: 'assets/images/puzzle-5.jpg', name: 'Lion',     uuid: id('assets/images/puzzle-5.jpg')),
      PuzzleImageData(assetPath: 'assets/images/puzzle-6.jpg', name: 'Sea',      uuid: id('assets/images/puzzle-6.jpg')),
      PuzzleImageData(assetPath: 'assets/images/puzzle-7.jpg', name: 'Elephant', uuid: id('assets/images/puzzle-7.jpg')),
      PuzzleImageData(assetPath: 'assets/images/puzzle-8.jpg', name: 'Squirrel', uuid: id('assets/images/puzzle-8.jpg')),
      PuzzleImageData(assetPath: 'assets/images/puzzle-9.jpg', name: 'Hedgehog', uuid: id('assets/images/puzzle-9.jpg')),
    ];
  }
}
