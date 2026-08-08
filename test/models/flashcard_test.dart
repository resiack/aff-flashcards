import 'package:flutter_test/flutter_test.dart';
import 'package:aff_flashcards/models/flashcard.dart';

void main() {
  group('Flashcard', () {
    test('fromJson parses id, front, back, and simPage', () {
      final card = Flashcard.fromJson({
        'id': 'card-1',
        'front': 'What is the hard deck?',
        'back': '1,000 feet.',
        'simPage': 22,
      });

      expect(card.id, 'card-1');
      expect(card.front, 'What is the hard deck?');
      expect(card.back, '1,000 feet.');
      expect(card.simPage, 22);
    });
  });

  group('Topic', () {
    test('fromJson parses nested cards', () {
      final topic = Topic.fromJson({
        'id': 'equipment',
        'title': 'Equipment',
        'cards': [
          {'id': 'c1', 'front': 'Q1', 'back': 'A1', 'simPage': 12},
          {'id': 'c2', 'front': 'Q2', 'back': 'A2', 'simPage': 13},
        ],
      });

      expect(topic.id, 'equipment');
      expect(topic.cards, hasLength(2));
      expect(topic.cards[0].id, 'c1');
      expect(topic.cards[1].back, 'A2');
      expect(topic.cards[1].simPage, 13);
    });
  });

  group('Deck', () {
    test(
      'fromJson parses nested topics and allCards flattens them in order',
      () {
        final deck = Deck.fromJson({
          'id': 'category_a',
          'title': 'Category A',
          'simEdition': '2026 USPA SIM',
          'disclaimer': 'Study aid only.',
          'topics': [
            {
              'id': 'topic1',
              'title': 'Topic One',
              'cards': [
                {'id': 'c1', 'front': 'Q1', 'back': 'A1', 'simPage': 12},
              ],
            },
            {
              'id': 'topic2',
              'title': 'Topic Two',
              'cards': [
                {'id': 'c2', 'front': 'Q2', 'back': 'A2', 'simPage': 13},
                {'id': 'c3', 'front': 'Q3', 'back': 'A3', 'simPage': 14},
              ],
            },
          ],
        });

        expect(deck.topics, hasLength(2));
        expect(deck.allCards, hasLength(3));
        expect(deck.allCards.map((c) => c.id), ['c1', 'c2', 'c3']);
      },
    );
  });
}
