import 'package:flutter_test/flutter_test.dart';
import 'package:kotoba_lantern/models/japanese_word.dart';
import 'package:kotoba_lantern/services/progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _word = JapaneseWord(
  japanese: '水',
  kana: 'みず',
  romaji: 'mizu',
  english: 'water',
  partOfSpeech: 'noun',
  order: 34,
);

const _other = JapaneseWord(
  japanese: '山',
  kana: 'やま',
  romaji: 'yama',
  english: 'mountain',
  partOfSpeech: 'noun',
  order: 57,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a word with nothing recorded is absent from the map', () async {
    final progress = await ProgressService().loadAll();

    expect(progress, isEmpty);
  });

  test('flags round-trip independently per word', () async {
    final service = ProgressService();

    await service.markSeen(_word);
    await service.setLearned(_word, true);
    await service.setFavorite(_other, true);

    final progress = await service.loadAll();
    expect(progress[_word.progressId]!.seen, isTrue);
    expect(progress[_word.progressId]!.learned, isTrue);
    expect(progress[_word.progressId]!.favorite, isFalse);
    expect(progress[_other.progressId]!.favorite, isTrue);
    expect(progress[_other.progressId]!.seen, isFalse);
  });

  test('unsetting a flag leaves the others intact', () async {
    final service = ProgressService();

    await service.markSeen(_word);
    await service.setLearned(_word, true);
    await service.setLearned(_word, false);

    final progress = await service.loadAll();
    expect(progress[_word.progressId]!.learned, isFalse);
    expect(progress[_word.progressId]!.seen, isTrue);
  });

  test('clear removes every tracked flag', () async {
    final service = ProgressService();

    await service.markSeen(_word);
    await service.setFavorite(_other, true);
    await service.clear();

    expect(await service.loadAll(), isEmpty);
  });
}
