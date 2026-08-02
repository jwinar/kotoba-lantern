import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'view_history_service.dart';

final viewHistoryServiceProvider = Provider<ViewHistoryService>((ref) {
  return ViewHistoryService();
});

/// A point-in-time snapshot of view history, loaded by HomeScreen. Not a
/// live-streaming provider - the screen reloads it explicitly whenever it
/// becomes visible again (see HomeScreen._reloadHistory), since view
/// history only changes while a different screen is on top.
class ViewHistorySnapshot {
  final int viewedCount;

  /// Most-recent-first word ids. The screen resolves them against the deck
  /// it has loaded; an id that no longer exists (deck regenerated, word
  /// dropped upstream) simply doesn't render.
  final List<String> recentIds;
  final Set<String> activeDateKeys;
  final int streak;

  const ViewHistorySnapshot({
    required this.viewedCount,
    required this.recentIds,
    required this.activeDateKeys,
    required this.streak,
  });

  static const empty = ViewHistorySnapshot(
    viewedCount: 0,
    recentIds: [],
    activeDateKeys: {},
    streak: 0,
  );
}
