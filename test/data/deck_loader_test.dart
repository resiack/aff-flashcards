import 'package:flutter_test/flutter_test.dart';
import 'package:aff_flashcards/data/deck_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loadCategoryA reads and parses the bundled Category A deck', () async {
    final deck = await DeckLoader().loadCategoryA();

    expect(deck.id, 'category_a');
    expect(deck.topics, isNotEmpty);
    expect(deck.allCards, isNotEmpty);
    expect(
      deck.allCards.every((c) => c.front.isNotEmpty && c.back.isNotEmpty),
      isTrue,
    );
  });

  test('loadCategoryB reads and parses the bundled Category B deck', () async {
    final deck = await DeckLoader().loadCategoryB();

    expect(deck.id, 'category_b');
    expect(deck.topics, isNotEmpty);
    expect(deck.allCards, isNotEmpty);
    expect(
      deck.allCards.every((c) => c.front.isNotEmpty && c.back.isNotEmpty),
      isTrue,
    );
  });
}
