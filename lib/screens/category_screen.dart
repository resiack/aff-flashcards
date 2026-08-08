import 'package:flutter/material.dart';

import '../data/deck_loader.dart';
import '../data/starred_cards_store.dart';
import '../models/flashcard.dart';
import 'study_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key, required this.assetPath});

  final String assetPath;

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late final Future<Deck> _deckFuture;
  final _starredCardsStore = const StarredCardsStore();
  Set<String> _starredIds = {};

  @override
  void initState() {
    super.initState();
    _deckFuture = DeckLoader().loadDeck(widget.assetPath);
    _loadStarredIds();
  }

  Future<void> _loadStarredIds() async {
    final ids = await _starredCardsStore.loadStarredIds();
    if (mounted) setState(() => _starredIds = ids);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AFF Flashcards')),
      body: FutureBuilder<Deck>(
        future: _deckFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Failed to load flashcards.'));
          }

          final deck = snapshot.data!;
          final starredCards = deck.allCards
              .where((card) => _starredIds.contains(card.id))
              .toList();

          return ListView(
            children: [
              ListTile(
                title: Text('All ${deck.title}'),
                subtitle: Text(
                  '${deck.allCards.length} card${deck.allCards.length == 1 ? '' : 's'}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openStudyScreen(
                  context,
                  title: 'All ${deck.title}',
                  cards: deck.allCards,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.star),
                title: const Text('Starred'),
                subtitle: Text(
                  starredCards.isEmpty
                      ? 'No starred cards yet'
                      : '${starredCards.length} card${starredCards.length == 1 ? '' : 's'}',
                ),
                trailing: starredCards.isEmpty
                    ? null
                    : const Icon(Icons.chevron_right),
                onTap: starredCards.isEmpty
                    ? null
                    : () => _openStudyScreen(
                        context,
                        title: 'Starred: ${deck.title}',
                        cards: starredCards,
                      ),
              ),
              const Divider(),
              for (final topic in deck.topics)
                ListTile(
                  title: Text(topic.title),
                  subtitle: Text(
                    '${topic.cards.length} card${topic.cards.length == 1 ? '' : 's'}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openStudyScreen(
                    context,
                    title: topic.title,
                    cards: topic.cards,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _openStudyScreen(
    BuildContext context, {
    required String title,
    required List<Flashcard> cards,
  }) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => StudyScreen(title: title, cards: cards),
          ),
        )
        .then((_) => _loadStarredIds());
  }
}
