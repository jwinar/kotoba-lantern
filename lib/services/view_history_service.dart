import 'package:shared_preferences/shared_preferences.dart';

/// Persisted record of which words have been viewed, used by the dashboard
/// home screen for the progress ring, the streak row, and "recently
/// viewed" - and by Smart Shuffle, to steer away from what was just shown.
///
/// Indices, not word ids: everything reading this store is positional
/// (which card to open, which row to draw), and the deck's canonical order
/// is stable. If a future release reorders or extends the deck, this store
/// needs a version key and a migration.
class ViewHistoryService {
  static const String _keyViewedIndices = 'viewHistory.viewedIndices';
  static const String _keyRecentIndices = 'viewHistory.recentIndices';
  static const String _keyActiveDates = 'viewHistory.activeDates';

  static const int _recentLimit = 30;
  static const int _activeDatesLimit = 60;

  Future<void> recordView(int index) async {
    final prefs = await SharedPreferences.getInstance();

    final viewed = (prefs.getStringList(_keyViewedIndices) ?? const <String>[]).toSet();
    viewed.add(index.toString());
    await prefs.setStringList(_keyViewedIndices, viewed.toList());

    final recent = prefs.getStringList(_keyRecentIndices) ?? <String>[];
    recent.remove(index.toString());
    recent.insert(0, index.toString());
    if (recent.length > _recentLimit) {
      recent.removeRange(_recentLimit, recent.length);
    }
    await prefs.setStringList(_keyRecentIndices, recent);

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

  Future<int> viewedCount() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_keyViewedIndices) ?? const []).length;
  }

  Future<List<int>> recentIndices({int limit = 6}) async {
    final prefs = await SharedPreferences.getInstance();
    final recent = prefs.getStringList(_keyRecentIndices) ?? const [];
    return recent.take(limit).map(int.parse).toList();
  }

  Future<Set<String>> activeDateKeys() async {
    final prefs = await SharedPreferences.getInstance();
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

  /// Clears view history. Paired with [ProgressService.clear] behind
  /// Settings' single "reset progress" action - the ring and streak are
  /// progress as far as the user is concerned, even though they live in a
  /// different store.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyViewedIndices);
    await prefs.remove(_keyRecentIndices);
    await prefs.remove(_keyActiveDates);
  }

  static String dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
