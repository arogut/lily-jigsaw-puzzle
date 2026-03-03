import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/image_selection_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const JigsawApp());
}

class JigsawApp extends StatelessWidget {
  const JigsawApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jigsaw Puzzle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const ImageSelectionScreen(),
    );
  }
}
