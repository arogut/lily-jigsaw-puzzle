# Lily Jigsaw Puzzle

> Built with [Claude Code](https://claude.ai/code)

A jigsaw puzzle game for children, built with Flutter for Android. Designed to run on tablets, primarily targeting the Samsung Galaxy Tab S8+.

## Requirements

- Flutter 3.41.3
- Android SDK (API 35+, build-tools 35.0.0)
- Java 17+

## Environment Setup

Flutter is installed at `~/development/flutter`. Add it to your PATH by sourcing your shell config:

```bash
source ~/.bashrc
```

Or use the full path directly: `~/development/flutter/bin/flutter`.

### Android SDK

The Android SDK is located at `~/Android/Sdk`. Set the environment variable when needed:

```bash
export ANDROID_HOME=~/Android/Sdk
```

### Install dependencies

```bash
flutter pub get
```

## Emulated Device Setup

### Prerequisites

The following SDK components are required (install via `sdkmanager` if missing):

```bash
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager \
  "emulator" \
  "platform-tools" \
  "platforms;android-35" \
  "system-images;android-35;google_apis;x86_64"
```

### Create the AVD

```bash
echo "no" | $ANDROID_HOME/cmdline-tools/latest/bin/avdmanager create avd \
  --name "Pixel_Tablet_API_35" \
  --package "system-images;android-35;google_apis;x86_64" \
  --device "pixel_tablet"
```

This creates a Pixel Tablet AVD (10.95", 2560×1600) — the closest available profile to the Galaxy Tab S8+.

### Display (WSL2 only)

If running on WSL2, enable the display via WSLg:

```bash
export DISPLAY=:0
```

Add this to `~/.bashrc` to make it permanent.

### Start the emulator

```bash
~/Android/Sdk/emulator/emulator -avd Pixel_Tablet_API_35 -no-metrics &
```

Wait ~1–2 minutes for the device to fully boot, then verify it's online:

```bash
flutter devices
```

## Running the App

```bash
flutter run -d emulator-5554
```

## Other Useful Commands

```bash
flutter build apk          # Build release APK
flutter build apk --debug  # Build debug APK
flutter test               # Run all tests
flutter analyze            # Run static analysis
```
