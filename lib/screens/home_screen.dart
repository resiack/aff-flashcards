import 'package:flutter/material.dart';

import 'about_screen.dart';
import 'category_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AFF Flashcards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AboutScreen())),
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Category A (Arch)'),
            subtitle: const Text('Ground school & first-jump course'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openCategory(
              context,
              assetPath: 'assets/decks/category_a.json',
            ),
          ),
        ],
      ),
    );
  }

  void _openCategory(BuildContext context, {required String assetPath}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CategoryScreen(assetPath: assetPath)),
    );
  }
}
