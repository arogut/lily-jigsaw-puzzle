import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/services/completion_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CompletionService', () {
    test('returns 0 stars for unknown image', () async {
      final svc = CompletionService();
      final stars = await svc.getStars('unknown-uuid');
      expect(stars, 0);
    });

    test('records 1 star for easy completion', () async {
      final svc = CompletionService();
      await svc.recordCompletion('uuid-1', 1);
      expect(await svc.getStars('uuid-1'), 1);
    });

    test('records 2 stars for medium completion', () async {
      final svc = CompletionService();
      await svc.recordCompletion('uuid-2', 2);
      expect(await svc.getStars('uuid-2'), 2);
    });

    test('records 3 stars for hard completion', () async {
      final svc = CompletionService();
      await svc.recordCompletion('uuid-3', 3);
      expect(await svc.getStars('uuid-3'), 3);
    });

    test('upgrades stars when a harder difficulty is completed', () async {
      final svc = CompletionService();
      await svc.recordCompletion('uuid-4', 1); // easy → 1 star
      await svc.recordCompletion('uuid-4', 3); // hard → 3 stars
      expect(await svc.getStars('uuid-4'), 3);
    });

    test('does not downgrade stars when an easier difficulty is re-completed', () async {
      final svc = CompletionService();
      await svc.recordCompletion('uuid-5', 3); // hard → 3 stars
      await svc.recordCompletion('uuid-5', 1); // easy — should remain 3
      expect(await svc.getStars('uuid-5'), 3);
    });

    test('keeps per-image star counts independent', () async {
      final svc = CompletionService();
      await svc.recordCompletion('uuid-a', 3); // 3 stars
      await svc.recordCompletion('uuid-b', 1); // 1 star
      expect(await svc.getStars('uuid-a'), 3);
      expect(await svc.getStars('uuid-b'), 1);
    });

    test('resetAll clears all stored stars', () async {
      final svc = CompletionService();
      await svc.recordCompletion('uuid-x', 3);
      await svc.recordCompletion('uuid-y', 2);
      await svc.resetAll();
      expect(await svc.getStars('uuid-x'), 0);
      expect(await svc.getStars('uuid-y'), 0);
    });

    test('uses the same key format across separate instances', () async {
      await CompletionService().recordCompletion('shared-uuid', 2);
      final stars = await CompletionService().getStars('shared-uuid');
      expect(stars, 2);
    });
  });
}
