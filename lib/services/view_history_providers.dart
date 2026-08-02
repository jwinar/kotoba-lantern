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
  final List<int> recentIndices;
  final Set<String> activeDateKeys;
  final int streak;

  const ViewHistorySnapshot({
    required this.viewedCount,
    required this.recentIndices,
    required this.activeDateKeys,
    required this.streak,
  });

  static const empty = ViewHistorySnapshot(
    viewedCount: 0,
    recentIndices: [],
    activeDateKeys: {},
    streak: 0,
  );
}
