import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aff_flashcards/data/flip_hint_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('hasSeenHint returns false when nothing has been stored', () async {
    final seen = await const FlipHintStore().hasSeenHint();
    expect(seen, isFalse);
  });

  test('markHintSeen persists across instances', () async {
    await const FlipHintStore().markHintSeen();

    final seen = await const FlipHintStore().hasSeenHint();
    expect(seen, isTrue);
  });

  test('markHintSeen is idempotent', () async {
    await const FlipHintStore().markHintSeen();
    await const FlipHintStore().markHintSeen();

    final seen = await const FlipHintStore().hasSeenHint();
    expect(seen, isTrue);
  });
}
