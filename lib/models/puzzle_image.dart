class PuzzleImageData {
  final String assetPath;
  final String name;

  const PuzzleImageData({required this.assetPath, required this.name});

  static const List<PuzzleImageData> all = [
    PuzzleImageData(assetPath: 'assets/images/puzzle-1.jpg', name: 'Cat'),
    PuzzleImageData(assetPath: 'assets/images/puzzle-2.jpg', name: 'Dog'),
    PuzzleImageData(assetPath: 'assets/images/puzzle-3.jpg', name: 'Forrest'),
    PuzzleImageData(assetPath: 'assets/images/puzzle-4.jpg', name: 'City'),
    PuzzleImageData(assetPath: 'assets/images/puzzle-5.jpg', name: 'Lion'),
    PuzzleImageData(assetPath: 'assets/images/puzzle-6.jpg', name: 'Sea'),
    PuzzleImageData(assetPath: 'assets/images/puzzle-7.jpg', name: 'Elephant'),
    PuzzleImageData(assetPath: 'assets/images/puzzle-8.jpg', name: 'Squirrel'),
    PuzzleImageData(assetPath: 'assets/images/puzzle-9.jpg', name: 'Hedgehog'),
  ];
}
