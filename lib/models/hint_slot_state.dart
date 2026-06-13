/// The lifecycle state of a single hint slot within a puzzle session.
enum HintSlotState {
  /// Timer is counting; button is visible but non-interactive.
  waiting,

  /// Timer expired; button is active and ready to tap.
  available,

  /// Hint was consumed; button is hidden.
  used,
}
