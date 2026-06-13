import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lily_jigsaw_puzzle/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets(
      'main() loads HintSettings and launches the app', (tester) async {
    SharedPreferences.setMockInitialValues({});

    // SystemChrome.setEnabledSystemUIMode and setPreferredOrientations send
    // method calls on flutter/platform which has no real handler in tests.
    // Register a no-op mock so they succeed instead of throwing
    // MissingPluginException.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);

    await app.main();
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);

    // Drain the SplashScreen navigation timer (5 s) then the PaletteGenerator
    // timers started by ImageSelectionScreen (up to 15 s).
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(seconds: 16));
  });
}
