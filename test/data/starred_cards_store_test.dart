import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aff_flashcards/data/starred_cards_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('loadStarredIds returns an empty set when nothing is starred', () async {
    final ids = await const StarredCardsStore().loadStarredIds();
    expect(ids, isEmpty);
  });

  test(
    'setStarred(id, true) adds the id, and it persists across instances',
    () async {
      await const StarredCardsStore().setStarred('card-1', true);

      final ids = await const StarredCardsStore().loadStarredIds();
      expect(ids, {'card-1'});
    },
  );

  test('setStarred(id, false) removes a previously starred id', () async {
    const store = StarredCardsStore();
    await store.setStarred('card-1', true);
    await store.setStarred('card-2', true);

    await store.setStarred('card-1', false);

    final ids = await store.loadStarredIds();
    expect(ids, {'card-2'});
  });
}
