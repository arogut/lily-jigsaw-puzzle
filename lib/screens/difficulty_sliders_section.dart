import 'package:flutter/material.dart';
import 'package:lily_jigsaw_puzzle/core/app_theme.dart';
import 'package:lily_jigsaw_puzzle/l10n/app_localizations.dart';
import 'package:lily_jigsaw_puzzle/services/difficulty_settings_service.dart';

/// Colour-coded sliders for adjusting the grid size of each difficulty level.
///
/// Rebuilds whenever [settings] notifies listeners, so any change to
/// [DifficultySettings] is reflected immediately.
class DifficultySlidersSection extends StatelessWidget {
  /// Creates a [DifficultySlidersSection] backed by the given [settings].
  const DifficultySlidersSection({
    required this.settings,
    super.key,
  });

  /// The difficulty settings to display and mutate.
  final DifficultySettings settings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final easy = settings.easyGridSize;
        final medium = settings.mediumGridSize;
        final hard = settings.hardGridSize;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSliderRow(
                label: l10n.easy,
                color: AppColors.green,
                value: easy,
                min: DifficultySettings.minGridSize,
                max: medium - 1,
                onChanged: settings.setEasy,
              ),
              const SizedBox(height: 8),
              _buildSliderRow(
                label: l10n.medium,
                color: AppColors.orange,
                value: medium,
                min: easy + 1,
                max: hard - 1,
                onChanged: settings.setMedium,
              ),
              const SizedBox(height: 8),
              _buildSliderRow(
                label: l10n.hard,
                color: AppColors.red,
                value: hard,
                min: medium + 1,
                max: DifficultySettings.maxGridSize,
                onChanged: settings.setHard,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliderRow({
    required String label,
    required Color color,
    required int value,
    required int min,
    required int max,
    required void Function(int) onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.deepPurple,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              thumbColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.25),
              overlayColor: color.withValues(alpha: 0.20),
              trackHeight: 4,
            ),
            child: Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: max > min ? max - min : 1,
              onChanged: max > min ? (v) => onChanged(v.round()) : null,
            ),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            '$value×$value',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.deepPurple,
            ),
          ),
        ),
      ],
    );
  }
}
