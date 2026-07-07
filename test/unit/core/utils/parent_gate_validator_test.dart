import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lily_jigsaw_puzzle/core/utils/parent_gate_validator.dart';

void main() {
  group('ParentGateValidator', () {
    test('accepts the correct sum', () {
      final validator = ParentGateValidator(random: Random(0));
      expect(validator.isCorrect(validator.a + validator.b), isTrue);
    });

    test('rejects incorrect answers', () {
      final validator = ParentGateValidator(random: Random(0));
      expect(validator.isCorrect(null), isFalse);
      expect(validator.isCorrect(0), isFalse);
    });
  });
}
