import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/models/hint_slot_state.dart';

void main() {
  group('HintSlotState', () {
    test('has exactly three values: waiting, available, used', () {
      expect(HintSlotState.values.length, 3);
      expect(HintSlotState.values, contains(HintSlotState.waiting));
      expect(HintSlotState.values, contains(HintSlotState.available));
      expect(HintSlotState.values, contains(HintSlotState.used));
    });

    test('waiting is not available', () {
      expect(HintSlotState.waiting == HintSlotState.available, isFalse);
    });

    test('available is not used', () {
      expect(HintSlotState.available == HintSlotState.used, isFalse);
    });

    test('waiting is not used', () {
      expect(HintSlotState.waiting == HintSlotState.used, isFalse);
    });
  });
}
