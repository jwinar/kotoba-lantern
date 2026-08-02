import 'package:shared_preferences/shared_preferences.dart';

/// Persisted record of which words have been viewed, used by the home
/// screen for the lantern, the streak row and "recently viewed" - and by
/// Smart Shuffle, to steer away from what was just shown.
///
/// Two deliberate shapes:
///
/// * **Word ids, not indices.** An earlier version stored positions in the
///   deck, which only held while the deck never changed. The decks are now
///   generated from upstream word lists, so a regeneration can reorder or
///   insert entries and every stored position would quietly point at a
///   different word. Ids ([JapaneseWord.id]) mean the same thing across
///   rebuilds.
/// * **Per level for words, global for days.** Which words you've seen is a
///   fact about a deck; whether you studied on a given day is a fact about
///   you, so the streak counts a day spent in any level.
class ViewHistoryService {
  static const String _keySchema = 'viewHistory.schema';
  static const String _keyActiveDates = 'viewHistory.activeDates';

  static const int _recentLimit = 30;
  static const int _activeDatesLimit = 400;

  /// Bumped when the stored shape changes. v1 stored deck positions under
  /// `viewHistory.viewedIndices` / `.recentIndices`; those can't be
  /// translated into ids, since the deck they indexed (a hand-written
  /// 150-word N5 set) no longer exists. [_migrate] drops them and keeps the
  /// day list, which is still true.
  static const int _schemaVersion = 2;

  static String _viewedKey(int level) => 'viewHistory.viewed.n$level';
  static String _recentKey(int level) => 'viewHistory.recent.n$level';

  Future<SharedPreferences> _prefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getInt(_keySchema) != _schemaVersion) {
      await _migrate(prefs);
    }
    return prefs;
  }

  Future<void> _migrate(SharedPreferences prefs) async {
    await prefs.remove('viewHistory.viewedIndices');
    await prefs.remove('viewHistory.recentIndices');
    await prefs.setInt(_keySchema, _schemaVersion);
  }

  Future<void> recordView(int level, String wordId) async {
    final prefs = await _prefs();

    final viewed = (prefs.getStringList(_viewedKey(level)) ?? const <String>[]).toSet();
    if (viewed.add(wordId)) {
      await prefs.setStringList(_viewedKey(level), viewed.toList());
    }

    final recent = prefs.getStringList(_recentKey(level)) ?? <String>[];
    recent.remove(wordId);
    recent.insert(0, wordId);
    if (recent.length > _recentLimit) {
      recent.removeRange(_recentLimit, recent.length);
    }
    await prefs.setStringList(_recentKey(level), recent);

    final today = dateKey(DateTime.now());
    final activeDates = prefs.getStringList(_keyActiveDates) ?? <String>[];
    if (!activeDates.contains(today)) {
      activeDates.add(today);
      if (activeDates.length > _activeDatesLimit) {
        activeDates.removeAt(0);
      }
      await prefs.setStringList(_keyActiveDates, activeDates);
    }
  }

  Future<int> viewedCount(int level) async {
    final prefs = await _prefs();
    return (prefs.getStringList(_viewedKey(level)) ?? const []).length;
  }

  /// Most-recent-first word ids for [level].
  Future<List<String>> recentIds(int level, {int limit = 6}) async {
    final prefs = await _prefs();
    final recent = prefs.getStringList(_recentKey(level)) ?? const [];
    return recent.take(limit).toList();
  }

  Future<Set<String>> activeDateKeys() async {
    final prefs = await _prefs();
    return (prefs.getStringList(_keyActiveDates) ?? const []).toSet();
  }

  /// Consecutive days (ending today) with at least one word viewed.
  Future<int> currentStreak() async {
    final active = await activeDateKeys();
    var streak = 0;
    var day = DateTime.now();
    while (active.contains(dateKey(day))) {
      streak += 1;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Clears view history for every level. Paired with [ProgressService.clear]
  /// behind Settings' single "reset progress" action - the lantern and the
  /// streak are progress as far as the user is concerned, even though they
  /// live in a different store.
  Future<void> clear() async {
    final prefs = await _prefs();
    for (final level in const [1, 2, 3, 4, 5]) {
      await prefs.remove(_viewedKey(level));
      await prefs.remove(_recentKey(level));
    }
    await prefs.remove(_keyActiveDates);
  }

  static String dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
