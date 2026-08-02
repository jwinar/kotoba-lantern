import 'package:flutter_test/flutter_test.dart';
import 'package:kotoba_lantern/data/n5_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the full N5 deck from the bundled assets', () async {
    final words = await N5Repository().loadWords();

    expect(words.length, 150);
    expect(words.first.order, 1);
    expect(words.last.order, words.length);
  });

  test('every word carries a reading, a gloss and an example sentence', () async {
    final words = await N5Repository().loadWords();

    for (final word in words) {
      expect(word.kana, isNotEmpty, reason: '${word.japanese} has no kana reading');
      expect(word.romaji, isNotEmpty, reason: '${word.japanese} has no romaji');
      expect(word.english, isNotEmpty, reason: '${word.japanese} has no gloss');
      expect(word.exampleSentence, isNotNull, reason: '${word.japanese} has no example sentence');
      expect(word.exampleSentenceKana, isNotNull);
      expect(word.exampleSentenceEnglish, isNotNull);
    }
  });

  test('kanji info is attached to single-kanji words only', () async {
    final words = await N5Repository().loadWords();
    final water = words.firstWhere((w) => w.japanese == '水');
    final compound = words.firstWhere((w) => w.japanese == '友達');

    expect(water.isSingleKanji, isTrue);
    expect(water.strokeCount, 4);
    expect(water.kunReading, 'みず');
    expect(compound.isSingleKanji, isFalse);
    expect(compound.strokeCount, isNull);
  });

  test('progress ids are unique across the deck', () async {
    final words = await N5Repository().loadWords();

    expect(words.map((w) => w.progressId).toSet().length, words.length);
  });
}
