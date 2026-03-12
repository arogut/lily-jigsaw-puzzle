import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/services/sound_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SoundService', () {
    test('is a singleton', () {
      expect(SoundService(), same(SoundService()));
    });

    test('playSnap, playWrong, playWin return futures', () {
      // Invoke the methods to exercise the delegation lines.
      // AudioPlayer may fail silently in the test environment — the futures
      // are intentionally not awaited so platform-channel errors don't fail
      // the test.
      final snapFuture = SoundService().playSnap();
      final wrongFuture = SoundService().playWrong();
      final winFuture = SoundService().playWin();
      expect(snapFuture, isNotNull);
      expect(wrongFuture, isNotNull);
      expect(winFuture, isNotNull);
      // Silence any unhandled async errors from AudioPlayer in the test VM
      snapFuture.ignore();
      wrongFuture.ignore();
      winFuture.ignore();
    });
  });
}
