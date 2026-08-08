import 'dart:math';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/flip_hint_store.dart';
import '../data/starred_cards_store.dart';
import '../models/flashcard.dart';
import '../widgets/flippable_card.dart';

/// The SIM PDF hosted by USPA. Flashcard.simPage stores the printed footer
/// page number, which runs 3 behind the PDF's raw page count since the
/// first 3 pages (cover and front matter) have no footer number.
const _simPdfBaseUrl =
    'https://uspa.org/LinkClick.aspx?fileticket=KMkbZSbEhtQ%3D&portalid=0';

Uri simPdfPageUrl(int simPage) =>
    Uri.parse('$_simPdfBaseUrl#page=${simPage + 3}');

class StudyScreen extends StatefulWidget {
  const StudyScreen({
    super.key,
    required this.title,
    required this.cards,
    StarredCardsStore? starredCardsStore,
    FlipHintStore? flipHintStore,
  }) : starredCardsStore = starredCardsStore ?? const StarredCardsStore(),
       flipHintStore = flipHintStore ?? const FlipHintStore();

  final String title;
  final List<Flashcard> cards;
  final StarredCardsStore starredCardsStore;
  final FlipHintStore flipHintStore;

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  late List<Flashcard> _cards;
  int _index = 0;
  bool _isFlipped = false;
  Set<String> _starredIds = {};
  late final Future<void> _starredIdsReady;
  bool _isTogglingStar = false;
  bool _showHint = false;
  bool _hintCheckResolved = false;
  bool _hintPreemptedByEarlyTap = false;

  @override
  void initState() {
    super.initState();
    _cards = List.of(widget.cards);
    _starredIdsReady = _loadStarredIds();
    _checkFlipHint();
  }

  Future<void> _loadStarredIds() async {
    final ids = await widget.starredCardsStore.loadStarredIds();
    if (mounted) setState(() => _starredIds = ids);
  }

  Future<void> _checkFlipHint() async {
    final seen = await widget.flipHintStore.hasSeenHint();
    if (!mounted) return;
    _hintCheckResolved = true;
    if (seen || _hintPreemptedByEarlyTap) {
      if (!seen) await widget.flipHintStore.markHintSeen();
      return;
    }
    setState(() => _showHint = true);
  }

  void _handleHintResolved() {
    widget.flipHintStore.markHintSeen();
  }

  Future<void> _toggleStar() async {
    // Prevents an overlapping call (e.g. a double-tap) from reading
    // _starredIds before the first call's write lands, which would toggle
    // back to the original state instead of applying once.
    if (_isTogglingStar) return;
    _isTogglingStar = true;
    try {
      await _starredIdsReady;
      final card = _cards[_index];
      final isStarred = _starredIds.contains(card.id);
      await widget.starredCardsStore.setStarred(card.id, !isStarred);
      if (!mounted) return;
      setState(() {
        if (isStarred) {
          _starredIds.remove(card.id);
        } else {
          _starredIds.add(card.id);
        }
      });
    } finally {
      _isTogglingStar = false;
    }
  }

  void _shuffle() {
    setState(() {
      _cards.shuffle(Random());
      _index = 0;
      _isFlipped = false;
    });
  }

  void _flip() {
    if (!_hintCheckResolved) _hintPreemptedByEarlyTap = true;
    setState(() => _isFlipped = !_isFlipped);
  }

  void _next() {
    if (_index >= _cards.length - 1) return;
    setState(() {
      _index++;
      _isFlipped = false;
    });
  }

  void _previous() {
    if (_index <= 0) return;
    setState(() {
      _index--;
      _isFlipped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final card = _cards[_index];
    final isLast = _index == _cards.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle),
            tooltip: 'Shuffle',
            onPressed: _shuffle,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${_index + 1} / ${_cards.length}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Stack(
                  children: [
                    FlippableCard(
                      key: const Key('flip-card'),
                      text: _isFlipped ? card.back : card.front,
                      isFlipped: _isFlipped,
                      onTap: _flip,
                      showHint: _showHint,
                      onHintResolved: _handleHintResolved,
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        key: const Key('star-button'),
                        icon: Icon(
                          _starredIds.contains(card.id)
                              ? Icons.star
                              : Icons.star_border,
                          size: 32,
                          color: _starredIds.contains(card.id)
                              ? Colors.amber
                              : Theme.of(context).colorScheme.outline,
                        ),
                        tooltip: 'Star for review',
                        onPressed: _toggleStar,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  key: const Key('sim-page-link'),
                  onTap: () => launchUrl(
                    simPdfPageUrl(card.simPage),
                    webOnlyWindowName: '_blank',
                  ),
                  child: Text(
                    'SIM p. ${card.simPage}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _index > 0 ? _previous : null,
                  child: const Text('Previous'),
                ),
                ElevatedButton(
                  onPressed: !isLast ? _next : null,
                  child: const Text('Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
