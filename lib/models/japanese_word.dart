/// One entry in the study deck.
///
/// [japanese] is the word as it is normally written (kanji where a word
/// normally takes kanji, kana where it doesn't - あなた, たくさん and the
/// greetings are kana words, not missing data). [kana] is always the full
/// reading, so it doubles as the furigana line on the study card, and
/// [romaji] is there for the first weeks before kana reading is fluent.
class JapaneseWord {
  final String japanese;
  final String kana;
  final String romaji;
  final String english;

  /// Word class as it's useful to a learner - "godan verb", "ichidan
  /// verb", "i-adjective", "na-adjective", "noun", "counter",
  /// "expression". Conjugation depends on this in a way it doesn't in the
  /// Mandarin deck this design came from, so it earns its place on the
  /// card's caption line rather than being a filing detail.
  final String partOfSpeech;

  /// 5 for JLPT N5, the only level in the deck today. Paired with [order]
  /// (unique within a level) as the stable `{level}_{order}` key
  /// [progressId] hands to the progress store, so adding N4 later doesn't
  /// collide with progress already recorded against N5.
  final int level;

  /// Position in the deck's canonical order (1-based).
  final int order;

  /// An example sentence using this word: the sentence itself, its all-kana
  /// reading, and an English translation. Every word in the bundled N5 deck
  /// has one, but display should still treat them as optional - a future
  /// level may not.
  final String? exampleSentence;
  final String? exampleSentenceKana;
  final String? exampleSentenceEnglish;

  /// Stroke count and the character's most common on/kun readings. Only
  /// populated for single-kanji words - a compound has no single stroke
  /// count, and a kana word has no kanji reading at all, so those are left
  /// null rather than guessing which character to describe.
  final int? strokeCount;
  final String? onReading;
  final String? kunReading;

  const JapaneseWord({
    required this.japanese,
    required this.kana,
    required this.romaji,
    required this.english,
    required this.partOfSpeech,
    required this.order,
    this.level = 5,
    this.exampleSentence,
    this.exampleSentenceKana,
    this.exampleSentenceEnglish,
    this.strokeCount,
    this.onReading,
    this.kunReading,
  });

  factory JapaneseWord.fromJson(Map<String, dynamic> json) {
    return JapaneseWord(
      japanese: json['japanese'] as String,
      kana: json['kana'] as String,
      romaji: json['romaji'] as String,
      english: json['english'] as String,
      partOfSpeech: json['partOfSpeech'] as String,
      order: json['order'] as int,
      level: json['level'] as int? ?? 5,
      exampleSentence: json['exampleSentence'] as String?,
      exampleSentenceKana: json['exampleSentenceKana'] as String?,
      exampleSentenceEnglish: json['exampleSentenceEnglish'] as String?,
      strokeCount: json['strokeCount'] as int?,
      onReading: json['onReading'] as String?,
      kunReading: json['kunReading'] as String?,
    );
  }

  /// True when the headword is a single kanji, i.e. when [strokeCount] and
  /// the readings are meaningful.
  bool get isSingleKanji => strokeCount != null;

  /// Stable key identifying this word in the progress store, across app
  /// sessions and (later) levels.
  String get progressId => '${level}_$order';
}
