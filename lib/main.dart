import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const AffFlashcardsApp());
}

class AffFlashcardsApp extends StatelessWidget {
  const AffFlashcardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AFF Flashcards',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}
