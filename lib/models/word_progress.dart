/// A single word's tracked state, stored on-device (see
/// [ProgressService]). `seen` is written automatically the first time the
/// word is shown on the study card; `learned` and `favorite` are only ever
/// set by an explicit tap - never inferred from view count, so a word never
/// shows as "learned" without the user actually saying so.
///
/// `favorite` is the "keep showing me this one" override: Smart Shuffle
/// down-weights a learned word, but a learned *and* favorited word keeps
/// its full weight in the rotation.
class WordProgress {
  final bool seen;
  final bool learned;
  final bool favorite;

  const WordProgress({
    this.seen = false,
    this.learned = false,
    this.favorite = false,
  });

  static const empty = WordProgress();

  WordProgress copyWith({bool? seen, bool? learned, bool? favorite}) {
    return WordProgress(
      seen: seen ?? this.seen,
      learned: learned ?? this.learned,
      favorite: favorite ?? this.favorite,
    );
  }

  /// True when nothing is tracked - used to drop empty entries rather than
  /// persisting rows that say nothing.
  bool get isEmpty => !seen && !learned && !favorite;

  @override
  bool operator ==(Object other) =>
      other is WordProgress &&
      other.seen == seen &&
      other.learned == learned &&
      other.favorite == favorite;

  @override
  int get hashCode => Object.hash(seen, learned, favorite);
}
