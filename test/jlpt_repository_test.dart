import 'package:flutter_test/flutter_test.dart';
import 'package:kotoba_lantern/data/jlpt_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Sizes are asserted loosely: the decks are generated from upstream word
  // lists, so an exact count would break on every harmless upstream fix,
  // while an order-of-magnitude check still catches a level that failed to
  // load or got truncated.
  const expectedMinimum = {5: 600, 4: 600, 3: 1800, 2: 1600, 1: 2400};

  test('every level loads', () async {
    final repository = JlptRepository();
    for (final level in jlptLevels) {
      final words = await repository.loadLevel(level);
      expect(
        words.length,
        greaterThanOrEqualTo(expectedMinimum[level]!),
        reason: 'N$level looks truncated at ${words.length} words',
      );
      expect(words.first.order, 1);
      expect(words.every((w) => w.level == level), isTrue);
    }
  });

  test('ids are unique within a level and distinct across levels', () async {
    final repository = JlptRepository();
    final allIds = <String>{};
    for (final level in jlptLevels) {
      final words = await repository.loadLevel(level);
      final ids = words.map((w) => w.id).toSet();
      expect(ids.length, words.length, reason: 'duplicate id inside N$level');
      expect(allIds.intersection(ids), isEmpty, reason: 'id collision across levels');
      allIds.addAll(ids);
    }
    expect(allIds.length, greaterThan(7000));
  });

  test('every word carries a reading and a gloss', () async {
    for (final level in jlptLevels) {
      final words = await JlptRepository().loadLevel(level);
      for (final word in words) {
        expect(word.kana, isNotEmpty, reason: '${word.japanese} has no reading');
        expect(word.romaji, isNotEmpty, reason: '${word.japanese} has no romaji');
        expect(word.english, isNotEmpty, reason: '${word.japanese} has no gloss');
      }
    }
  });

  test('kanji info attaches to single-kanji headwords only', () async {
    final words = await JlptRepository().loadLevel(5);
    final water = words.firstWhere((w) => w.japanese == '水');
    final compound = words.firstWhere((w) => w.japanese == '友達');

    expect(water.isSingleKanji, isTrue);
    expect(water.strokeCount, 4);
    expect(water.onReading, 'スイ');
    expect(water.kunReading, 'みず');
    expect(compound.isSingleKanji, isFalse);
    expect(compound.strokeCount, isNull);
  });

  test('the hand-written example sentences survive into the deck', () async {
    final words = await JlptRepository().loadLevel(5);
    final withSentences = words.where((w) => w.exampleSentence != null).toList();

    expect(withSentences.length, greaterThanOrEqualTo(140));
    final watashi = words.firstWhere((w) => w.japanese == '私');
    expect(watashi.exampleSentence, '私は学生です。');
    expect(watashi.exampleSentenceKana, 'わたしはがくせいです。');
    expect(watashi.exampleSentenceEnglish, 'I am a student.');
  });
}
