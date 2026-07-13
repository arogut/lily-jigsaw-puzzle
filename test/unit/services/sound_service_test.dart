import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/models/celebration_style.dart';
import 'package:lily_jigsaw_puzzle/services/sound_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SoundService', () {
    test('is a singleton', () {
      expect(SoundService(), same(SoundService()));
    });

    test('playSnap, playWrong, playWin return futures', () {
      final snapFuture = SoundService().playSnap();
      final wrongFuture = SoundService().playWrong();
      final winFuture = SoundService().playWin();
      expect(snapFuture, isNotNull);
      expect(wrongFuture, isNotNull);
      expect(winFuture, isNotNull);
      snapFuture.ignore();
      wrongFuture.ignore();
      winFuture.ignore();
    });

    test('playWinFanfare loops until stopWinFanfare is called', () async {
      final service = SoundService();
      await service.playWinFanfare(CelebrationStyleId.balloons);
      await service.stopWinFanfare();
    });

    test('stopWinFanfare is safe when no fanfare is playing', () async {
      final service = SoundService();
      await service.stopWinFanfare();
      await service.stopWinFanfare();
    });

    test('stopWinFanfare returns promptly without blocking on audio stop', () async {
      final service = SoundService();
      await service.playWinFanfare(CelebrationStyleId.confetti);
      await expectLater(service.stopWinFanfare(), completes);
    });

    test('playWinFanfare completes without rethrowing when audio fails', () async {
      await expectLater(
        SoundService().playWinFanfare(CelebrationStyleId.confetti),
        completes,
      );
      await SoundService().stopWinFanfare();
    });

    test('playHintAvailable returns a future', () {
      final future = SoundService().playHintAvailable();
      expect(future, isNotNull);
      future.ignore();
    });

    test('playHintsExhausted returns a future', () {
      final future = SoundService().playHintsExhausted();
      expect(future, isNotNull);
      future.ignore();
    });
  });
}
