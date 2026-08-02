import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/japanese_word.dart';
import '../models/word_progress.dart';
import 'progress_service.dart';

final progressServiceProvider = Provider<ProgressService>((ref) {
  return ProgressService();
});

/// Every word's tracked state, keyed by [JapaneseWord.id].
///
/// Loaded once from [ProgressService] and then patched in memory as flags
/// are toggled, so the UI updates on the same frame as the tap while the
/// write happens underneath. Missing key = [WordProgress.empty]; callers
/// should read it that way rather than treating absence as an error.
class WordProgressNotifier extends AsyncNotifier<Map<String, WordProgress>> {
  @override
  Future<Map<String, WordProgress>> build() {
    return ref.read(progressServiceProvider).loadAll();
  }

  Future<void> markSeen(JapaneseWord word) async {
    if (state.value?[word.id]?.seen ?? false) return;
    _patch(word.id, (progress) => progress.copyWith(seen: true));
    await ref.read(progressServiceProvider).markSeen(word);
  }

  Future<void> setLearned(JapaneseWord word, bool value) async {
    _patch(word.id, (progress) => progress.copyWith(learned: value));
    await ref.read(progressServiceProvider).setLearned(word, value);
  }

  Future<void> setFavorite(JapaneseWord word, bool value) async {
    _patch(word.id, (progress) => progress.copyWith(favorite: value));
    await ref.read(progressServiceProvider).setFavorite(word, value);
  }

  Future<void> clear() async {
    state = const AsyncData<Map<String, WordProgress>>({});
    await ref.read(progressServiceProvider).clear();
  }

  void _patch(String progressId, WordProgress Function(WordProgress) update) {
    final current = state.value ?? const <String, WordProgress>{};
    final updated = update(current[progressId] ?? WordProgress.empty);
    final next = Map<String, WordProgress>.from(current);
    if (updated.isEmpty) {
      next.remove(progressId);
    } else {
      next[progressId] = updated;
    }
    state = AsyncData(next);
  }
}

final wordProgressProvider =
    AsyncNotifierProvider<WordProgressNotifier, Map<String, WordProgress>>(
      WordProgressNotifier.new,
    );
