import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the study card is cycling sequentially (Prev/Next by index) or
/// via Smart Shuffle (weighted-random - see word_providers.dart's
/// pickWeightedRandomIndex). Session-only: it resets to sequential on each
/// app launch rather than persisting a mode choice indefinitely.
class ShuffleModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final shuffleModeProvider = NotifierProvider<ShuffleModeNotifier, bool>(
  ShuffleModeNotifier.new,
);

/// Back-stack of word indices visited while shuffling, so Previous can
/// step back through what Smart Shuffle actually showed instead of
/// falling back to sequential index-1 (which would be a different word
/// than "the one shown before this one"). Cleared whenever shuffle mode
/// is toggled, so each shuffle session starts fresh.
class ShuffleHistoryNotifier extends Notifier<List<int>> {
  @override
  List<int> build() => const [];

  void push(int index) => state = [...state, index];

  /// Removes and returns the most recent entry, or null if empty.
  int? pop() {
    if (state.isEmpty) return null;
    final last = state.last;
    state = state.sublist(0, state.length - 1);
    return last;
  }

  void clear() => state = const [];
}

final shuffleHistoryProvider =
    NotifierProvider<ShuffleHistoryNotifier, List<int>>(
      ShuffleHistoryNotifier.new,
    );
