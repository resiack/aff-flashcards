import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aff_flashcards/data/flip_hint_store.dart';
import 'package:aff_flashcards/data/starred_cards_store.dart';
import 'package:aff_flashcards/models/flashcard.dart';
import 'package:aff_flashcards/screens/study_screen.dart';

/// A store whose initial load blocks until [releaseLoad] is called, for
/// testing a tap that arrives before the load resolves.
class _SlowLoadStarredCardsStore extends StarredCardsStore {
  final _gate = Completer<void>();

  void releaseLoad() => _gate.complete();

  @override
  Future<Set<String>> loadStarredIds() async {
    await _gate.future;
    return super.loadStarredIds();
  }
}

class _SlowLoadFlipHintStore extends FlipHintStore {
  final _gate = Completer<void>();

  void releaseLoad() => _gate.complete();

  @override
  Future<bool> hasSeenHint() async {
    await _gate.future;
    return super.hasSeenHint();
  }
}

void main() {
  final cards = [
    const Flashcard(id: 'c1', front: 'Front 1', back: 'Back 1', simPage: 19),
    const Flashcard(id: 'c2', front: 'Front 2', back: 'Back 2', simPage: 22),
  ];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestable() => MaterialApp(
    home: StudyScreen(title: 'Test Deck', cards: cards),
  );

  testWidgets('shows the front of the first card and progress 1 / 2', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestable());

    expect(find.text('Front 1'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
  });

  testWidgets('tapping the card flips it to show the back', (tester) async {
    await tester.pumpWidget(buildTestable());

    await tester.tap(find.byKey(const Key('flip-card')));
    await tester.pump();

    expect(find.text('Back 1'), findsOneWidget);
    expect(find.text('Front 1'), findsNothing);
  });

  testWidgets('Next advances to the next card and resets the flip', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestable());

    await tester.tap(find.byKey(const Key('flip-card')));
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pump();

    expect(find.text('Front 2'), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);
  });

  testWidgets('Next is disabled on the last card', (tester) async {
    await tester.pumpWidget(buildTestable());

    await tester.tap(find.text('Next'));
    await tester.pump();

    final nextButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Next'),
    );
    expect(nextButton.onPressed, isNull);
  });

  testWidgets('Previous is disabled on the first card', (tester) async {
    await tester.pumpWidget(buildTestable());

    final previousButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Previous'),
    );
    expect(previousButton.onPressed, isNull);
  });

  testWidgets('shows the SIM page reference for the current card', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestable());

    expect(find.text('SIM p. 19'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pump();

    expect(find.text('SIM p. 22'), findsOneWidget);
  });

  testWidgets('the SIM page reference is tappable', (tester) async {
    await tester.pumpWidget(buildTestable());

    expect(find.byKey(const Key('sim-page-link')), findsOneWidget);
    expect(
      tester.widget<InkWell>(find.byKey(const Key('sim-page-link'))).onTap,
      isNotNull,
    );
  });

  testWidgets(
    'the star button toggles the current card starred, and resets per-card',
    (tester) async {
      await tester.pumpWidget(buildTestable());
      await tester.pump();

      expect(
        tester.widget<IconButton>(find.byKey(const Key('star-button'))).icon,
        isA<Icon>().having((i) => i.icon, 'icon', Icons.star_border),
      );

      await tester.tap(find.byKey(const Key('star-button')));
      await tester.pump();

      expect(
        tester.widget<IconButton>(find.byKey(const Key('star-button'))).icon,
        isA<Icon>().having((i) => i.icon, 'icon', Icons.star),
      );

      await tester.tap(find.text('Next'));
      await tester.pump();

      expect(
        tester.widget<IconButton>(find.byKey(const Key('star-button'))).icon,
        isA<Icon>().having((i) => i.icon, 'icon', Icons.star_border),
        reason: 'card 2 was never starred, so its own star state should show',
      );
    },
  );

  testWidgets('a tap that arrives before the initial load resolves is not lost '
      'once that load completes (regression)', (tester) async {
    final slowStore = _SlowLoadStarredCardsStore();
    await tester.pumpWidget(
      MaterialApp(
        home: StudyScreen(
          title: 'Test Deck',
          cards: cards,
          starredCardsStore: slowStore,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('star-button')));
    await tester.pump();

    slowStore.releaseLoad();
    await tester.pumpAndSettle();

    expect(
      tester.widget<IconButton>(find.byKey(const Key('star-button'))).icon,
      isA<Icon>().having((i) => i.icon, 'icon', Icons.star),
      reason: 'the tap should win, not get overwritten by the stale load',
    );
    expect(await slowStore.loadStarredIds(), {'c1'});
  });

  group('simPdfPageUrl', () {
    test('adds 3 to the printed SIM page to get the PDF fragment page', () {
      expect(simPdfPageUrl(19).fragment, 'page=22');
      expect(simPdfPageUrl(14).fragment, 'page=17');
    });

    test('points at the official USPA-hosted SIM PDF', () {
      final uri = simPdfPageUrl(19);
      expect(uri.host, 'uspa.org');
      expect(uri.path, '/LinkClick.aspx');
      expect(uri.queryParameters['portalid'], '0');
    });
  });

  group('flip hint', () {
    testWidgets('plays on a fresh install and marks it seen', (tester) async {
      await tester.pumpWidget(buildTestable());
      // A bare pump lets the async hasSeenHint() read resolve before the
      // timed pumps start. Advancing in smaller steps, rather than one
      // jump, ensures a Timer created partway through still fires.
      await tester.pump();
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      final icon = tester.widget<Opacity>(find.byType(Opacity));
      expect(icon.opacity, greaterThan(0));

      await tester.pumpAndSettle();

      expect(await const FlipHintStore().hasSeenHint(), isTrue);
    });

    testWidgets('does not play once already seen', (tester) async {
      await const FlipHintStore().markHintSeen();

      await tester.pumpWidget(buildTestable());
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 300));

      final icon = tester.widget<Opacity>(find.byType(Opacity));
      expect(icon.opacity, 0);
    });

    testWidgets(
      'a real tap before the seen-check resolves suppresses the hint and '
      'still marks it seen',
      (tester) async {
        final slowHintStore = _SlowLoadFlipHintStore();
        await tester.pumpWidget(
          MaterialApp(
            home: StudyScreen(
              title: 'Test Deck',
              cards: cards,
              flipHintStore: slowHintStore,
            ),
          ),
        );
        await tester.pump();

        await tester.tap(find.byKey(const Key('flip-card')));
        await tester.pump();

        slowHintStore.releaseLoad();
        await tester.pumpAndSettle();

        expect(await slowHintStore.hasSeenHint(), isTrue);
      },
    );
  });

  testWidgets('no longer shows the permanent tap captions', (tester) async {
    await tester.pumpWidget(buildTestable());
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Tap card to reveal answer'), findsNothing);
    expect(find.text('Tap card to see question'), findsNothing);
  });
}
