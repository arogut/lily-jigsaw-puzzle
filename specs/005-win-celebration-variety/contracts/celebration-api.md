# Contracts: Celebration API

**Phase**: 1 | **Date**: 2026-07-13 (updated for two-phase flow)

Public Dart API surface for `GameScreen`, streak feature (004), and tests.

---

## CelebrationStyleId

```dart
enum CelebrationStyleId {
  confetti,
  balloons,
  fireworks,
  milestone;

  static const List<CelebrationStyleId> standardStyles = [
    confetti, balloons, fireworks,
  ];

  String get audioAsset; // sounds/win_<style>.wav
}
```

---

## CelebrationPhase

```dart
/// Active stage of a win celebration.
enum CelebrationPhase {
  /// Full-screen particles; tap to skip.
  animating,

  /// Fixed win card visible; fanfare still playing.
  overlay,
}
```

---

## CelebrationIntensity

```dart
@immutable
final class CelebrationIntensity {
  factory CelebrationIntensity.fromStreakWeeks(int completedStreakWeeks);

  final int level;
  final int particleCount;
  final Duration animationDuration; // scales with intensity — NOT fanfare
}
```

---

## DailyCompletionTracker

```dart
final class DailyCompletionTracker {
  DailyCompletionTracker({PreferencesStore? store});

  Future<int> consumeNext(DateTime date);
  Future<int> peek(DateTime date);
  Future<void> reset();
}
```

---

## CelebrationSelector

```dart
abstract final class CelebrationSelector {
  static CelebrationStyleId styleFor(DateTime date, int dailyCount);
  static int dayOffset(DateTime date);
}
```

---

## SoundService (additions)

```dart
/// Starts looping fanfare for [style]. Runs until [stopWinFanfare].
Future<void> playWinFanfare(CelebrationStyleId style);

/// Stops fanfare immediately. Idempotent.
Future<void> stopWinFanfare();
```

---

## WinOverlay

```dart
class WinOverlay extends StatelessWidget {
  const WinOverlay({
    required this.onPlayAgain,
    required this.onNewPuzzle,
    required this.onDismiss,
    this.streakRecord,
    super.key,
  });

  final VoidCallback onDismiss;
  // Fixed 🎉 design — NO celebrationStyle theming parameter
}
```

---

## CelebrationLayer

```dart
/// Animation phase only. Sound is caller's responsibility.
class CelebrationLayer extends StatefulWidget {
  const CelebrationLayer({
    required this.style,
    required this.intensity,
    required this.onSkip,
    required this.onAnimationComplete,
    super.key,
  });

  final CelebrationStyleId style;
  final CelebrationIntensity intensity;
  final VoidCallback onSkip;
  final VoidCallback onAnimationComplete;
}
```

`AnimationController.duration = intensity.animationDuration`. On `completed` status →
`onAnimationComplete`. Full-screen `GestureDetector` → `onSkip`.

---

## GameScreen Integration

```dart
Future<void> _onWin() async {
  // ... streak, dailyCount, style, intensity ...
  unawaited(SoundService().playWinFanfare(style));
  setState(() {
    _celebrationPhase = CelebrationPhase.animating;
    _celebrationStyle = style;
    _celebrationIntensity = intensity;
  });
}

void _onAnimationFinished() {
  setState(() => _celebrationPhase = CelebrationPhase.overlay);
}

void _onSkipAnimation() {
  _onAnimationFinished(); // same transition
}

void _onEndCelebration({required bool viaBackdrop}) {
  unawaited(SoundService().stopWinFanfare());
  setState(() {
    _celebrationPhase = null;
    _showWinOverlay = false;
  });
  // viaBackdrop: puzzle board visible; Back only — no Play Again on board
}
```

Show `CelebrationLayer` when `phase == animating`. Show `WinOverlay` when
`phase == overlay`. Never both.
