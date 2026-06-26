# Lily Jigsaw Puzzle

> Built with [Claude Code](https://claude.ai/code)

A jigsaw puzzle game for children, built with Flutter for Android. Designed to run on tablets, primarily targeting the Samsung Galaxy Tab S8+.

> Images generated with [DeepAI](https://deepai.org/)

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

The emulator runs on the **Windows host** to avoid WSL2 QEMU memory crashes caused by
`lavapipe` software rendering at the Pixel Tablet's 2560×1600 resolution. Flutter in WSL2
connects to it via the Windows ADB server.

### Windows: install SDK command-line tools

Download the command-line tools zip from https://developer.android.com/studio#command-line-tools-only
and extract to `%LOCALAPPDATA%\Android\Sdk\cmdline-tools\latest\`. Then install the required
components from PowerShell:

```powershell
$sdk = "$env:LOCALAPPDATA\Android\Sdk"
$sdkmanager = "$sdk\cmdline-tools\latest\bin\sdkmanager.bat"
& $sdkmanager --sdk_root=$sdk --licenses
& $sdkmanager --sdk_root=$sdk "emulator" "platform-tools" "system-images;android-35;google_apis;x86_64"
```

### Windows: create the Pixel Tablet AVD

```powershell
$avdmanager = "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools\latest\bin\avdmanager.bat"
echo "no" | & $avdmanager --sdk_root="$env:LOCALAPPDATA\Android\Sdk" create avd `
  --name "Pixel_Tablet_API_35" `
  --package "system-images;android-35;google_apis;x86_64" `
  --device "pixel_tablet"
```

### Windows: start the emulator and ADB server

```powershell
$sdk = "$env:LOCALAPPDATA\Android\Sdk"

# Start the emulator
& "$sdk\emulator\emulator.exe" -avd Pixel_Tablet_API_35 -no-metrics

# In a separate PowerShell window, start the ADB server listening on all interfaces
# so WSL2 can reach it (ensure port 5037 is allowed in Windows Firewall)
$adb = "$sdk\platform-tools\adb.exe"
& $adb kill-server
Start-Process -FilePath $adb -ArgumentList "-a -P 5037 nodaemon server" -WindowStyle Hidden
```

> **Note:** Windows Firewall must allow inbound TCP on port 5037. The ADB server and the
> WSL2 ADB client must be the same version — if they differ, update platform-tools via
> `sdkmanager "platform-tools"` on both sides.

### WSL2: connect to the Windows ADB server

`~/.bashrc` is already configured to point ADB at the Windows host:

```bash
export ANDROID_ADB_SERVER_ADDRESS=$(ip route | grep default | awk '{print $3}')
export ANDROID_ADB_SERVER_PORT=5037
```

The Windows host IP is read from the default gateway at shell startup (it changes on WSL restart).
After sourcing, verify the emulator is visible:

```bash
source ~/.bashrc
adb devices   # should list the Windows emulator
flutter devices
```

## Claude Code / Android MCP Setup

The project ships with an Android MCP server (`.mcp.json`) that lets Claude Code take
screenshots, interact with the emulator, and run ADB commands via
[`@mobilenext/mobile-mcp`](https://github.com/mobile-next/mobile-mcp).

### Prerequisites

- **Node.js** with `npx` on your PATH (install via [nvm](https://github.com/nvm-sh/nvm) or your system package manager)
- **ANDROID_HOME** pointing to your Android SDK (e.g. `export ANDROID_HOME=~/Android/Sdk`)
- An Android emulator or device visible to ADB

The script at `.claude/android-mcp.sh` resolves `ANDROID_HOME` from your environment
(defaulting to `~/Android/Sdk` if unset) and loads nvm automatically if `npx` is not on
your PATH. No hardcoded paths — it works on any machine.

> **WSL2 note:** If the emulator runs on the Windows host (the setup described in the
> [Emulated Device Setup](#emulated-device-setup) section above), the script reads the
> Windows host IP from the default gateway at runtime and points ADB at the Windows ADB
> server on port 5037. No extra configuration is needed beyond what that section describes.

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
