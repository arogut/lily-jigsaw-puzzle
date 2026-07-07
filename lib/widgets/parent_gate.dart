import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lily_jigsaw_puzzle/core/app_theme.dart';
import 'package:lily_jigsaw_puzzle/core/utils/parent_gate_validator.dart';
import 'package:lily_jigsaw_puzzle/l10n/app_localizations.dart';
import 'package:lily_jigsaw_puzzle/widgets/game_button.dart';

/// Parent-gate math challenge shown before settings are accessible.
class ParentGate extends StatefulWidget {
  /// Creates a [ParentGate] that calls [onUnlocked] when answered correctly.
  const ParentGate({
    required this.onUnlocked,
    super.key,
  });

  /// Called once the parent answers the math question correctly.
  final VoidCallback onUnlocked;

  @override
  State<ParentGate> createState() => _ParentGateState();
}

class _ParentGateState extends State<ParentGate> {
  late ParentGateValidator _validator;
  final _answerController = TextEditingController();
  String? _errorMessage;
  Timer? _errorResetTimer;

  @override
  void initState() {
    super.initState();
    _validator = ParentGateValidator();
  }

  @override
  void dispose() {
    _errorResetTimer?.cancel();
    _answerController.dispose();
    super.dispose();
  }

  void _checkAnswer() {
    final l10n = AppLocalizations.of(context)!;
    final input = int.tryParse(_answerController.text.trim());
    if (_validator.isCorrect(input)) {
      widget.onUnlocked();
      return;
    }

    setState(() => _errorMessage = l10n.wrongAnswer);
    _errorResetTimer?.cancel();
    _errorResetTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _errorMessage = null;
        _validator = ParentGateValidator();
        _answerController.clear();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.mathQuestion(_validator.a, _validator.b),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.deepPurple,
              ),
            ),
            const SizedBox(height: 20),
            Semantics(
              label: l10n.mathHint,
              textField: true,
              child: TextField(
                controller: _answerController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.deepPurple,
                ),
                decoration: InputDecoration(
                  hintText: l10n.mathHint,
                  hintStyle: TextStyle(
                    color: AppColors.mediumPurple.withValues(alpha: 0.50),
                    fontSize: 16,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5EEFF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.mediumPurple, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.deepPurple, width: 2.5),
                  ),
                ),
                onSubmitted: (_) => _checkAnswer(),
              ),
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: AppColors.redShadow,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
            ],
            GameButton(
              label: l10n.confirm,
              icon: Icons.check_rounded,
              variant: GameButtonVariant.mint,
              onPressed: _checkAnswer,
            ),
          ],
        ),
      ),
    );
  }
}
