import 'package:shared_preferences/shared_preferences.dart';

import '../models/japanese_word.dart';
import '../models/word_progress.dart';

/// On-device store for per-word seen/learned/favorite state.
///
/// Three parallel `SharedPreferences` string lists of [JapaneseWord.progressId]
/// rather than one serialized map: each flag is set independently, membership
/// is the whole payload, and a corrupted or half-written list degrades to
/// "that flag is missing" instead of losing all progress at once. There is
/// deliberately no account or sync layer - progress is local to the device,
/// and everything the app shows is derived from these three sets.
class ProgressService {
  static const String _keySeen = 'progress.seen';
  static const String _keyLearned = 'progress.learned';
  static const String _keyFavorite = 'progress.favorite';

  Future<Map<String, WordProgress>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = (prefs.getStringList(_keySeen) ?? const <String>[]).toSet();
    final learned = (prefs.getStringList(_keyLearned) ?? const <String>[]).toSet();
    final favorite = (prefs.getStringList(_keyFavorite) ?? const <String>[]).toSet();

    final progress = <String, WordProgress>{};
    for (final id in {...seen, ...learned, ...favorite}) {
      progress[id] = WordProgress(
        seen: seen.contains(id),
        learned: learned.contains(id),
        favorite: favorite.contains(id),
      );
    }
    return progress;
  }

  Future<void> markSeen(JapaneseWord word) => _setFlag(_keySeen, word.progressId, true);

  Future<void> setLearned(JapaneseWord word, bool value) =>
      _setFlag(_keyLearned, word.progressId, value);

  Future<void> setFavorite(JapaneseWord word, bool value) =>
      _setFlag(_keyFavorite, word.progressId, value);

  /// Clears every tracked flag. Offered from Settings; the caller is
  /// responsible for confirming with the user first.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySeen);
    await prefs.remove(_keyLearned);
    await prefs.remove(_keyFavorite);
  }

  Future<void> _setFlag(String key, String progressId, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList(key) ?? const <String>[]).toSet();
    final changed = value ? ids.add(progressId) : ids.remove(progressId);
    if (!changed) return;
    await prefs.setStringList(key, ids.toList()..sort());
  }
}
