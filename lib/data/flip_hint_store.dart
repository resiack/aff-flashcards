import 'package:shared_preferences/shared_preferences.dart';

class FlipHintStore {
  const FlipHintStore();

  static const _prefsKey = 'has_seen_flip_hint';

  Future<bool> hasSeenHint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false;
  }

  Future<void> markHintSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
  }
}
