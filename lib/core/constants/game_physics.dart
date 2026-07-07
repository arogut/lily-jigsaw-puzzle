/// Physics and interaction constants for puzzle gameplay.
abstract final class GamePhysics {
  /// Scale applied to a piece while it is being dragged.
  static const liftScale = 1.08;

  /// Distance in logical pixels within which a dropped piece snaps to its slot.
  static const snapThreshold = 40.0;

  /// Radius within which magnetic pull toward the target slot is applied.
  static const magnetRadius = 80.0;

  /// Velocity friction coefficient (vel *= (1 - friction * dt)).
  static const friction = 6.0;

  /// Bounce damping at tray walls.
  static const bounceDamp = 0.35;

  /// Maximum piece velocity after drag release.
  static const maxVelocity = 1500.0;

  /// Velocities below this threshold are zeroed out.
  static const minVelocity = 5.0;
}
