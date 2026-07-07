import 'dart:math';

/// Generates and validates the parent-gate math challenge.
class ParentGateValidator {
  /// Creates a validator with random operands in the range 1–9.
  ParentGateValidator({Random? random}) : _random = random ?? Random() {
    _a = 1 + _random.nextInt(9);
    _b = 1 + _random.nextInt(9);
  }

  final Random _random;
  late final int _a;
  late final int _b;

  /// First operand shown in the math question.
  int get a => _a;

  /// Second operand shown in the math question.
  int get b => _b;

  /// Returns true when [answer] equals the correct sum.
  bool isCorrect(int? answer) => answer == _a + _b;
}
