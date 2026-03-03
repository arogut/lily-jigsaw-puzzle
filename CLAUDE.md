# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

A Flutter jigsaw puzzle game targeting Android.

## Environment

Flutter 3.41.3 is installed at `~/development/flutter`. PATH and ANDROID_HOME are configured in `~/.bashrc` and `~/.zshrc`. Open a new terminal (or `source ~/.bashrc`) to have `flutter` available directly.

- Flutter SDK: `~/development/flutter`
- Android SDK: `~/Android/Sdk` (API 36, build-tools 35.0.0)

## Common Commands

```bash
flutter run                        # Run on connected device
flutter build apk                  # Build release APK
flutter build apk --debug          # Build debug APK
flutter test                       # Run all tests
flutter test test/widget_test.dart # Run a single test file
flutter pub get                    # Install dependencies
flutter pub add <package>          # Add a dependency
flutter analyze                    # Run static analysis
```

## Architecture

- `lib/main.dart` — entry point
- `android/` — Android-specific configuration (Kotlin, Gradle)
- `test/` — widget and unit tests
- `pubspec.yaml` — dependencies and project metadata

## Notes

- `flutter doctor` shows warnings for Chrome and Linux toolchain — these are not needed for Android development.
- The PATH warning in `flutter doctor` resolves after sourcing `~/.bashrc` in a new terminal.
- To deploy to a physical Android device over USB on WSL2, USB passthrough via `usbipd-win` is required on the Windows host.
