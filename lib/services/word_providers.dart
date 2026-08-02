import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/n5_repository.dart';
import '../models/japanese_word.dart';
import '../models/word_progress.dart';

final n5RepositoryProvider = Provider<N5Repository>((ref) {
  return N5Repository();
});

// retry: disabled. A local asset load either succeeds or genuinely fails -
// retrying doesn't help, and Riverpod's default retry-with-backoff timer
// outlives a single test's pumpAndSettle, tripping flutter_test's "no
// pending timers after dispose" check on any transient first-attempt
// failure.
final n5WordsProvider = FutureProvider<List<JapaneseWord>>((ref) {
  return ref.watch(n5RepositoryProvider).loadWords();
}, retry: (retryCount, error) => null);

class CurrentWordIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void next(int wordCount) {
    if (wordCount == 0) return;
    if (state < wordCount - 1) {
      state = state + 1;
    }
  }

  void previous() {
    if (state > 0) {
      state = state - 1;
    }
  }

  void jumpTo(int index, int wordCount) {
    if (wordCount == 0) return;
    state = index.clamp(0, wordCount - 1);
  }

  /// Smart Shuffle's "Next": jumps to a weighted-random word rather than
  /// index+1. See [pickWeightedRandomIndex] for the weighting itself.
  void jumpToRandom({
    required List<JapaneseWord> words,
    required Map<String, WordProgress> progress,
    required List<int> recentIndices,
  }) {
    if (words.isEmpty) return;
    state = pickWeightedRandomIndex(
      words: words,
      progress: progress,
      recentIndices: recentIndices,
      excludeIndex: state,
    );
  }
}

final currentWordIndexProvider =
    NotifierProvider<CurrentWordIndexNotifier, int>(
      CurrentWordIndexNotifier.new,
    );

/// Picks a weighted-random index into [words] for Smart Shuffle, favoring
/// words that are NOT learned and were NOT recently viewed - "smart" in
/// the sense of steering practice toward what still needs it, not a
/// flat/uniform shuffle. A word that is learned *and* favorited keeps full
/// weight: favoriting is the "keep showing me this one" override.
///
/// [recentIndices] is most-recent-first (ViewHistoryService.recentIndices'
/// own order); an index's position there scales its weight down towards
/// [_recentFloor] the closer to the front it is, and anything outside that
/// window (or never viewed at all) gets full weight. [excludeIndex] (the
/// word currently on screen) is heavily downweighted rather than
/// physically excluded, so Next rarely - but can still, for a tiny word
/// list - repeat the word just shown.
const double _learnedWeight = 0.2;
const double _recentFloor = 0.1;
const double _excludeWeight = 0.05;

int pickWeightedRandomIndex({
  required List<JapaneseWord> words,
  required Map<String, WordProgress> progress,
  required List<int> recentIndices,
  int? excludeIndex,
  Random? random,
}) {
  assert(words.isNotEmpty, 'pickWeightedRandomIndex requires a non-empty word list');
  if (words.length == 1) return 0;

  final rng = random ?? Random();
  final recencyRank = <int, int>{
    for (var i = 0; i < recentIndices.length; i++) recentIndices[i]: i,
  };

  final weights = List<double>.generate(words.length, (i) {
    final wordProgress = progress[words[i].progressId];
    final demoted = (wordProgress?.learned ?? false) && !(wordProgress?.favorite ?? false);
    var weight = demoted ? _learnedWeight : 1.0;

    final rank = recencyRank[i];
    if (rank != null) {
      weight *= _recentFloor + (1 - _recentFloor) * (rank / recentIndices.length);
    }

    if (i == excludeIndex) weight *= _excludeWeight;
    return max(weight, 0.001);
  });

  final total = weights.fold<double>(0, (sum, w) => sum + w);
  var target = rng.nextDouble() * total;
  for (var i = 0; i < weights.length; i++) {
    target -= weights[i];
    if (target <= 0) return i;
  }
  return words.length - 1;
}
