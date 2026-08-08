import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aff_flashcards/widgets/flippable_card.dart';

void main() {
  Widget buildTestable({
    String text = 'Front text',
    bool isFlipped = false,
    required VoidCallback onTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: FlippableCard(text: text, isFlipped: isFlipped, onTap: onTap),
      ),
    );
  }

  testWidgets('renders the given text', (tester) async {
    await tester.pumpWidget(buildTestable(text: 'Hello', onTap: () {}));

    expect(find.text('Hello'), findsOneWidget);
  });

  testWidgets('tapping the card calls onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(buildTestable(onTap: () => tapped = true));

    await tester.tap(find.byType(FlippableCard));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('exposes a click cursor for mouse input', (tester) async {
    await tester.pumpWidget(buildTestable(onTap: () {}));

    expect(
      tester
          .widget<FocusableActionDetector>(find.byType(FocusableActionDetector))
          .mouseCursor,
      SystemMouseCursors.click,
    );
  });

  testWidgets('scales down while pressed and back up when released', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestable(onTap: () {}));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(FlippableCard)),
    );
    await tester.pump();
    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
      0.98,
    );

    await gesture.up();
    await tester.pump();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1.0);
  });

  testWidgets(
    'exposes a single semantics node with the card content as its label '
    'and the action as its hint, with no duplicate contribution from the '
    'visible text',
    (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        buildTestable(text: 'What handles?', isFlipped: false, onTap: () {}),
      );

      final semantics = tester.getSemantics(find.byType(FlippableCard));
      expect(semantics.label, 'What handles?');
      expect(semantics.hint, 'Reveal answer');
      expect(semantics.getSemanticsData().flagsCollection.isButton, isTrue);
      expect(
        semantics.childrenCount,
        0,
        reason:
            'the visible text must not contribute a separate semantics '
            'node once excluded',
      );

      handle.dispose();
    },
  );

  testWidgets('uses "Show question" as the hint when flipped', (tester) async {
    await tester.pumpWidget(buildTestable(isFlipped: true, onTap: () {}));

    final semantics = tester.getSemantics(find.byType(FlippableCard));
    expect(semantics.hint, 'Show question');
  });

  testWidgets('Enter and Space each activate the card exactly once', (
    tester,
  ) async {
    var tapCount = 0;
    await tester.pumpWidget(buildTestable(onTap: () => tapCount++));

    final focusNode = tester
        .widget<FocusableActionDetector>(find.byType(FocusableActionDetector))
        .focusNode!;
    focusNode.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(tapCount, 1, reason: 'Enter should activate exactly once');

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(tapCount, 2, reason: 'Space should activate exactly once more');
  });

  testWidgets('keyboard focus shows a visible outline that clears on blur', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestable(onTap: () {}));

    Border? currentBorder() {
      final container = tester.widget<Container>(
        find.byKey(const Key('focus-ring')),
      );
      final decoration = container.foregroundDecoration as BoxDecoration?;
      return decoration?.border as Border?;
    }

    expect(currentBorder(), isNull);

    // Tab moves focus to the card and, as a real keyboard event, switches
    // FocusManager's highlight mode to "traditional". It defaults to
    // "touch" in tests, under which onShowFocusHighlight never fires.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(currentBorder(), isNotNull);

    final focusNode = tester
        .widget<FocusableActionDetector>(find.byType(FocusableActionDetector))
        .focusNode!;
    focusNode.unfocus();
    await tester.pumpAndSettle();

    expect(currentBorder(), isNull);
  });

  group('one-time hint', () {
    testWidgets(
      'plays the tease after a short delay and calls onHintResolved when '
      'it starts, not when it completes',
      (tester) async {
        var resolvedCount = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FlippableCard(
                text: 'Front',
                isFlipped: false,
                onTap: () {},
                showHint: true,
                onHintResolved: () => resolvedCount++,
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 499));
        expect(resolvedCount, 0, reason: 'still within the pending delay');

        await tester.pump(const Duration(milliseconds: 10));
        expect(resolvedCount, 1, reason: 'the tease has just started');

        await tester.pumpAndSettle();
        expect(resolvedCount, 1, reason: 'completion must not resolve again');
      },
    );

    testWidgets(
      'a tap during the pending delay cancels it, skips the animation, '
      'and calls onHintResolved exactly once',
      (tester) async {
        var resolvedCount = 0;
        var tapped = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FlippableCard(
                text: 'Front',
                isFlipped: false,
                onTap: () => tapped = true,
                showHint: true,
                onHintResolved: () => resolvedCount++,
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.byType(FlippableCard));
        await tester.pump();

        expect(tapped, isTrue);
        expect(resolvedCount, 1);

        await tester.pump(const Duration(seconds: 2));
        expect(resolvedCount, 1, reason: 'the cancelled delay must not fire');
      },
    );

    testWidgets('a tap while the tease is animating stops it immediately', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlippableCard(
              text: 'Front',
              isFlipped: false,
              onTap: () {},
              showHint: true,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byType(FlippableCard));
      await tester.pump();

      final transform = tester.widget<Transform>(
        find.byKey(const Key('hint-tilt-transform')),
      );
      final identity = Matrix4.identity()..setEntry(3, 2, 0.001);
      expect(transform.transform, identity);
    });

    testWidgets('reduced motion keeps the tap icon but skips the tilt', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: FlippableCard(
                text: 'Front',
                isFlipped: false,
                onTap: () {},
                showHint: true,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 300));

      final transform = tester.widget<Transform>(
        find.byKey(const Key('hint-tilt-transform')),
      );
      final identity = Matrix4.identity()..setEntry(3, 2, 0.001);
      expect(transform.transform, identity, reason: 'no tilt when reduced');

      final icon = tester.widget<Opacity>(find.byType(Opacity));
      expect(icon.opacity, greaterThan(0), reason: 'icon still fades in');
    });

    testWidgets(
      'disposing during the pending delay does not throw and does not '
      'call onHintResolved',
      (tester) async {
        var resolvedCount = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FlippableCard(
                text: 'Front',
                isFlipped: false,
                onTap: () {},
                showHint: true,
                onHintResolved: () => resolvedCount++,
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        await tester.pump(const Duration(seconds: 2));

        expect(resolvedCount, 0);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
