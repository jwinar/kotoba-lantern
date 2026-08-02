/// One entry in a JLPT deck.
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
  /// "expression".
  ///
  /// Null for most of the deck: the imported word lists carry no word
  /// class, and inferring one from an English gloss ("to …" → verb) would
  /// be wrong often enough to teach the wrong thing. Only the hand-curated
  /// N5 words have it, and the card omits the line when it's absent rather
  /// than guessing.
  final String? partOfSpeech;

  /// 5 (N5) through 1 (N1).
  final int level;

  /// Position in the level's canonical order (1-based). Display order
  /// only - [id] is what progress is keyed by.
  final int order;

  /// An example sentence using this word: the sentence itself, its all-kana
  /// reading, and an English translation. Present for the 150 hand-written
  /// N5 words and null for the rest of the deck, so display always treats
  /// them as optional.
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
    required this.order,
    this.partOfSpeech,
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
      partOfSpeech: json['partOfSpeech'] as String?,
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

  /// Stable identity for progress and view history: level plus the written
  /// form, e.g. `5_私`.
  ///
  /// Deliberately not the list position. The deck is generated from
  /// upstream word lists (see scripts/build_jlpt_data.py), so a
  /// regeneration can insert, drop or reorder entries; anything keyed by
  /// index would silently start pointing at a different word. A headword is
  /// unique within its level - the generator enforces that - and means the
  /// same thing across rebuilds.
  String get id => '${level}_$japanese';
}
