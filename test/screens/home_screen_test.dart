import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aff_flashcards/screens/home_screen.dart';

void main() {
  testWidgets(
    'shows a tile for the visible category, and tapping it opens its topic list',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Category A (Arch)'), findsOneWidget);
      expect(find.text('Category B (Basics)'), findsNothing);

      await tester.tap(find.text('Category A (Arch)'));
      await tester.pumpAndSettle();

      expect(find.textContaining('All Category A'), findsOneWidget);
    },
  );

  testWidgets('the info icon opens the About screen', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();

    expect(find.textContaining('personal study aid'), findsOneWidget);
    expect(find.textContaining('study aid'), findsNWidgets(2));
  });
}
