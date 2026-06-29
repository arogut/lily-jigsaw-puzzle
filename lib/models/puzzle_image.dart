class PuzzleImageData {
  const PuzzleImageData({
    required this.assetPath,
    required this.uuid,
  });
  final String assetPath;
  final String uuid;

  /// UUIDs are UUID v5 values computed from each asset path using namespace
  /// `3c3d63d7-0de7-4b57-8e7f-a9a1b9c2d7e5` (via the `uuid` package's
  /// `Uuid().v5(ns, assetPath)`). Add new entries the same way.
  static const List<PuzzleImageData> all = [
    PuzzleImageData(assetPath: 'assets/images/puzzle-1.jpg', uuid: 'c9ca2678-81e7-5268-b01c-551c354b2f70'),
    PuzzleImageData(assetPath: 'assets/images/puzzle-2.jpg', uuid: 'c72cd81d-b06d-5b5f-a68a-392b1757002c'),
    PuzzleImageData(assetPath: 'assets/images/puzzle-3.jpg', uuid: 'f45c886a-9f8b-5c7c-b79d-333930fc17cd'),
    PuzzleImageData(assetPath: 'assets/images/puzzle-4.jpg', uuid: 'd5ba0e08-5414-59b9-9f48-9cff6ac3152d'),
    PuzzleImageData(assetPath: 'assets/images/puzzle-5.jpg', uuid: '8c6d49ba-d76b-5087-9f86-32bbd27a94d1'),
    PuzzleImageData(assetPath: 'assets/images/puzzle-6.jpg', uuid: '0421fcde-de78-5546-9e5d-98baa049268c'),
    PuzzleImageData(assetPath: 'assets/images/puzzle-7.jpg', uuid: '9d8afb59-3130-5fc0-b3bd-1f30e1925a99'),
    PuzzleImageData(assetPath: 'assets/images/puzzle-8.jpg', uuid: '7cadc4ed-659b-5795-8595-1f623552e1c0'),
    PuzzleImageData(assetPath: 'assets/images/puzzle-9.jpg', uuid: '55064576-fba7-5884-92f2-e63a85899524'),
  ];
}
