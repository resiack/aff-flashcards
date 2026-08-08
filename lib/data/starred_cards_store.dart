import 'package:shared_preferences/shared_preferences.dart';

class StarredCardsStore {
  const StarredCardsStore();

  static const _prefsKey = 'starred_card_ids';

  Future<Set<String>> loadStarredIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_prefsKey) ?? const []).toSet();
  }

  Future<void> setStarred(String cardId, bool starred) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList(_prefsKey) ?? const []).toSet();
    if (starred) {
      ids.add(cardId);
    } else {
      ids.remove(cardId);
    }
    await prefs.setStringList(_prefsKey, ids.toList());
  }
}
