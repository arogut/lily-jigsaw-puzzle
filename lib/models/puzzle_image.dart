class PuzzleImageData {
  final String assetPath;
  final String name;

  const PuzzleImageData({required this.assetPath, required this.name});

  static const List<PuzzleImageData> all = [
    PuzzleImageData(assetPath: 'assets/images/puzzle1.jpg', name: 'Garden'),
    PuzzleImageData(assetPath: 'assets/images/puzzle2.jpg', name: 'Animals'),
    PuzzleImageData(assetPath: 'assets/images/puzzle3.jpg', name: 'Ocean'),
    PuzzleImageData(assetPath: 'assets/images/puzzle4.jpg', name: 'Space'),
    PuzzleImageData(assetPath: 'assets/images/puzzle5.jpg', name: 'Castle'),
  ];
}
