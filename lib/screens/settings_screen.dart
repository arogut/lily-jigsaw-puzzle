import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lily_jigsaw_puzzle/core/app_theme.dart';
import 'package:lily_jigsaw_puzzle/l10n/app_localizations.dart';
import 'package:lily_jigsaw_puzzle/main.dart';
import 'package:lily_jigsaw_puzzle/screens/difficulty_sliders_section.dart';
import 'package:lily_jigsaw_puzzle/services/completion_service.dart';
import 'package:lily_jigsaw_puzzle/services/difficulty_settings_service.dart';
import 'package:lily_jigsaw_puzzle/services/hint_settings_service.dart';
import 'package:lily_jigsaw_puzzle/services/streak_service.dart';
import 'package:lily_jigsaw_puzzle/widgets/game_button.dart';
import 'package:lily_jigsaw_puzzle/widgets/gradient_title.dart';

class SettingsScreen extends StatefulWidget {

  const SettingsScreen({
    required this.localeNotifier,
    required this.difficultySettings,
    required this.hintSettings,
    super.key,
  });
  final LocaleNotifier localeNotifier;
  final DifficultySettings difficultySettings;

  /// Hint unlock configuration; passed to the Hints settings section.
  final HintSettings hintSettings;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Math challenge gate
  late int _a;
  late int _b;
  final _answerController = TextEditingController();
  bool _unlocked = false;
  String? _errorMessage;

  // Settings state
  bool _resetDone = false;
  late TextEditingController _delayController;
  String? _delayError;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _a = 1 + rng.nextInt(9);
    _b = 1 + rng.nextInt(9);
    _delayController = TextEditingController(
      text: widget.hintSettings.unlockDelaySeconds.toString(),
    );
  }

  @override
  void dispose() {
    _answerController.dispose();
    _delayController.dispose();
    super.dispose();
  }

  void _checkAnswer(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final input = int.tryParse(_answerController.text.trim());
    if (input == _a + _b) {
      setState(() {
        _unlocked = true;
        _errorMessage = null;
      });
    } else {
      setState(() => _errorMessage = l10n.wrongAnswer);
      Timer(const Duration(milliseconds: 1500), () {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  void _setLocale(Locale locale) {
    widget.localeNotifier.setLocale(locale);
    setState(() {}); // rebuild to show new language
  }

  Future<void> _resetProgress() async {
    await CompletionService().resetAll();
    await StreakService().resetAll();
    if (mounted) setState(() => _resetDone = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundDecoration,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    GameButton(
                      label: l10n.back,
                      icon: Icons.arrow_back_rounded,
                      variant: GameButtonVariant.blue,
                      fontSize: 16,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Center(child: GradientTitle(text: l10n.settingsTitle)),
                    ),
                    const SizedBox(width: 138),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _unlocked
                    ? _buildSettingsPanel(context, l10n)
                    : _buildMathGate(context, l10n),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMathGate(BuildContext context, AppLocalizations l10n) {
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
              l10n.mathQuestion(_a, _b),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.deepPurple,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
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
                  borderSide: const BorderSide(color: AppColors.mediumPurple, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.deepPurple, width: 2.5),
                ),
              ),
              onSubmitted: (_) => _checkAnswer(context),
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
              onPressed: () => _checkAnswer(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsPanel(BuildContext context, AppLocalizations l10n) {
    final currentLocale = widget.localeNotifier.locale;

    final languages = [
      ('pl', l10n.langPolish),
      ('en', l10n.langEnglish),
      ('de', l10n.langGerman),
      ('es', l10n.langSpanish),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Language section
          _buildSectionLabel(l10n.language),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: languages.map((lang) {
              final isSelected = currentLocale.languageCode == lang.$1;
              return GestureDetector(
                onTap: () => _setLocale(Locale(lang.$1)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.mediumPurple
                        : Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.deepPurple
                          : Colors.white.withValues(alpha: 0.50),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    lang.$2,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.deepPurple,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Hints section
          _buildSectionLabel(l10n.hintsSection),
          const SizedBox(height: 12),
          _buildHintsSection(l10n),

          const SizedBox(height: 24),

          // Difficulty section
          _buildSectionLabel(l10n.difficultyTitle),
          const SizedBox(height: 12),
          DifficultySlidersSection(settings: widget.difficultySettings),

          const SizedBox(height: 24),

          // Reset progress section
          _buildSectionLabel(l10n.resetProgress),
          const SizedBox(height: 12),
          GameButton(
            label: l10n.resetProgress,
            icon: Icons.delete_sweep_rounded,
            variant: GameButtonVariant.pink,
            onPressed: () => unawaited(_resetProgress()),
          ),
          if (_resetDone) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l10n.progressReset,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _submitDelay(AppLocalizations l10n) {
    final value = int.tryParse(_delayController.text.trim()) ?? 0;
    if (value < 1) {
      setState(() => _delayError = l10n.hintsDelayError);
      return;
    }
    widget.hintSettings.setUnlockDelay(value: value);
    setState(() => _delayError = null);
  }

  Widget _buildHintsSection(AppLocalizations l10n) {
    final isImmediate = widget.hintSettings.immediateMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: isImmediate,
              onChanged: (v) {
                widget.hintSettings.setImmediateMode(value: v ?? false);
                setState(() => _delayError = null);
              },
              activeColor: AppColors.mediumPurple,
            ),
            Text(
              l10n.hintsImmediate,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.deepPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _delayController,
          enabled: !isImmediate,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: l10n.hintsDelayLabel,
            errorText: _delayError,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            enabledBorder: OutlineInputBorder(
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
          onSubmitted: (_) => _submitDelay(l10n),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.deepPurple,
        letterSpacing: 0.5,
      ),
    );
  }
}
