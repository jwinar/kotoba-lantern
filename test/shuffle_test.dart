import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kotoba_lantern/models/japanese_word.dart';
import 'package:kotoba_lantern/models/word_progress.dart';
import 'package:kotoba_lantern/services/word_providers.dart';

List<JapaneseWord> _words(int count) => List.generate(
  count,
  (i) => JapaneseWord(
    japanese: '語$i',
    kana: 'ご$i',
    romaji: 'go$i',
    english: 'word $i',
    partOfSpeech: 'noun',
    order: i,
  ),
);

Map<String, int> _tally(
  List<JapaneseWord> words, {
  required Map<String, WordProgress> progress,
  required List<int> recentIndices,
  int? excludeIndex,
  int trials = 4000,
}) {
  final counts = {for (final w in words) w.japanese: 0};
  final rng = Random(42);
  for (var i = 0; i < trials; i++) {
    final picked = pickWeightedRandomIndex(
      words: words,
      progress: progress,
      recentIndices: recentIndices,
      excludeIndex: excludeIndex,
      random: rng,
    );
    counts[words[picked].japanese] = counts[words[picked].japanese]! + 1;
  }
  return counts;
}

void main() {
  group('pickWeightedRandomIndex', () {
    test('a single-word list always returns index 0', () {
      final words = _words(1);
      for (var i = 0; i < 10; i++) {
        expect(pickWeightedRandomIndex(words: words, progress: const {}, recentIndices: const []), 0);
      }
    });

    test('always returns an in-range index', () {
      final words = _words(20);
      final rng = Random(7);
      for (var i = 0; i < 500; i++) {
        final index = pickWeightedRandomIndex(
          words: words,
          progress: const {},
          recentIndices: const [3, 4, 5],
          excludeIndex: 9,
          random: rng,
        );
        expect(index, inInclusiveRange(0, words.length - 1));
      }
    });

    test('learned words are picked far less often than unlearned ones', () {
      final words = _words(10);
      final counts = _tally(
        words,
        // The first five are learned, the rest are not.
        progress: {
          for (final word in words.take(5)) word.progressId: const WordProgress(learned: true),
        },
        recentIndices: const [],
      );
      final learned = counts.entries.take(5).fold<int>(0, (sum, e) => sum + e.value);
      final unlearned = counts.entries.skip(5).fold<int>(0, (sum, e) => sum + e.value);
      expect(learned, lessThan(unlearned ~/ 2));
    });

    test('a favorited word keeps full weight even once learned', () {
      final words = _words(10);
      final counts = _tally(
        words,
        progress: {
          words[0].progressId: const WordProgress(learned: true),
          words[1].progressId: const WordProgress(learned: true, favorite: true),
        },
        recentIndices: const [],
      );
      expect(counts['語1'], greaterThan(counts['語0']! * 2));
    });

    test('recently viewed words are picked less often, most-recent least', () {
      final words = _words(10);
      final counts = _tally(
        words,
        progress: const {},
        // Most-recent-first: index 0 was just seen, index 1 before that.
        recentIndices: const [0, 1, 2],
      );
      expect(counts['語0'], lessThan(counts['語1']!));
      expect(counts['語1'], lessThan(counts['語2']!));
      expect(counts['語2'], lessThan(counts['語9']!));
    });

    test('the current word is rarely repeated', () {
      final words = _words(10);
      final counts = _tally(words, progress: const {}, recentIndices: const [], excludeIndex: 4);
      final others = counts.entries.where((e) => e.key != '語4').map((e) => e.value);
      expect(counts['語4'], lessThan(others.reduce(min) ~/ 2));
    });
  });
}
