import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aff_flashcards/screens/category_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'shows a tile for "All Category A" and each topic, and tapping one opens the study screen',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CategoryScreen(assetPath: 'assets/decks/category_a.json'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('All Category A'), findsOneWidget);
      expect(find.text('Equipment & Altitude Awareness'), findsOneWidget);

      await tester.tap(find.textContaining('All Category A'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('flip-card')), findsOneWidget);
    },
  );

  testWidgets('shows Category B topics when given the Category B asset', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CategoryScreen(assetPath: 'assets/decks/category_b.json'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('All Category B'), findsOneWidget);
    expect(find.text('Freefall Refinement'), findsOneWidget);
  });

  testWidgets(
    'Starred tile is disabled and shows "No starred cards yet" when nothing is starred',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CategoryScreen(assetPath: 'assets/decks/category_b.json'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No starred cards yet'), findsOneWidget);

      final starredTile = tester.widget<ListTile>(
        find.widgetWithText(ListTile, 'Starred'),
      );
      expect(starredTile.onTap, isNull);
    },
  );

  testWidgets(
    'starring a card in a study session updates the Starred count on return',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CategoryScreen(assetPath: 'assets/decks/category_b.json'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Freefall Refinement'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('star-button')));
      await tester.pump();

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('1 card'), findsOneWidget);

      await tester.tap(find.text('Starred'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('flip-card')), findsOneWidget);
      expect(find.text('1 / 1'), findsOneWidget);
    },
  );
}
