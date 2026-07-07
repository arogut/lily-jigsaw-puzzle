/// Application-wide constants not tied to a specific feature module.
abstract final class AppConstants {
  /// Default locale language code when no preference is saved.
  static const defaultLocaleCode = 'pl';

  /// Milliseconds after splash start when the fade-out animation begins.
  static const splashFadeOutDelayMs = 4400;

  /// Milliseconds after splash start when navigation to the image picker occurs.
  static const splashNavigateDelayMs = 5000;
}
