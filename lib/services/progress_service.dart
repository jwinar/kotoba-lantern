import 'package:shared_preferences/shared_preferences.dart';

import '../models/japanese_word.dart';
import '../models/word_progress.dart';

/// On-device store for per-word seen/learned/favorite state.
///
/// Three parallel `SharedPreferences` string lists of [JapaneseWord.id]
/// rather than one serialized map: each flag is set independently, membership
/// is the whole payload, and a corrupted or half-written list degrades to
/// "that flag is missing" instead of losing all progress at once. There is
/// deliberately no account or sync layer - progress is local to the device,
/// and everything the app shows is derived from these three sets.
class ProgressService {
  static const String _keySeen = 'progress.seen';
  static const String _keyLearned = 'progress.learned';
  static const String _keyFavorite = 'progress.favorite';
  static const String _keySchema = 'progress.schema';

  /// v1 keyed words by `{level}_{order}` - a position in a 150-word
  /// hand-written deck. v2 keys them by `{level}_{headword}`. The two can't
  /// be translated into each other (the deck v1 indexed no longer exists),
  /// so the old entries are dropped on first read rather than left to sit
  /// in storage forever, never matching anything and quietly counting
  /// toward nothing.
  static const int _schemaVersion = 2;

  Future<SharedPreferences> _prefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getInt(_keySchema) != _schemaVersion) {
      for (final key in [_keySeen, _keyLearned, _keyFavorite]) {
        final ids = prefs.getStringList(key);
        if (ids == null) continue;
        // A v1 id is level_digits; anything else is already v2.
        final kept = ids
            .where((id) => !RegExp(r'^\d+_\d+$').hasMatch(id))
            .toList();
        if (kept.length != ids.length) {
          await prefs.setStringList(key, kept);
        }
      }
      await prefs.setInt(_keySchema, _schemaVersion);
    }
    return prefs;
  }

  Future<Map<String, WordProgress>> loadAll() async {
    final prefs = await _prefs();
    final seen = (prefs.getStringList(_keySeen) ?? const <String>[]).toSet();
    final learned = (prefs.getStringList(_keyLearned) ?? const <String>[])
        .toSet();
    final favorite = (prefs.getStringList(_keyFavorite) ?? const <String>[])
        .toSet();

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

  Future<void> markSeen(JapaneseWord word) => _setFlag(_keySeen, word.id, true);

  Future<void> setLearned(JapaneseWord word, bool value) =>
      _setFlag(_keyLearned, word.id, value);

  Future<void> setFavorite(JapaneseWord word, bool value) =>
      _setFlag(_keyFavorite, word.id, value);

  /// Clears every tracked flag. Offered from Settings; the caller is
  /// responsible for confirming with the user first.
  Future<void> clear() async {
    final prefs = await _prefs();
    await prefs.remove(_keySeen);
    await prefs.remove(_keyLearned);
    await prefs.remove(_keyFavorite);
  }

  Future<void> _setFlag(String key, String progressId, bool value) async {
    final prefs = await _prefs();
    final ids = (prefs.getStringList(key) ?? const <String>[]).toSet();
    final changed = value ? ids.add(progressId) : ids.remove(progressId);
    if (!changed) return;
    await prefs.setStringList(key, ids.toList()..sort());
  }
}
