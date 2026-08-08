import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/flashcard.dart';

class DeckLoader {
  Future<Deck> loadDeck(String assetPath) async {
    final jsonString = await rootBundle.loadString(assetPath, cache: false);
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    return Deck.fromJson(data);
  }

  Future<Deck> loadCategoryA() => loadDeck('assets/decks/category_a.json');

  Future<Deck> loadCategoryB() => loadDeck('assets/decks/category_b.json');
}
