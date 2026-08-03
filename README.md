# Kotoba Lantern

A quiet daily Japanese vocabulary deck: **7,897 words across JLPT N5-N1**,
each with its kana reading, romaji and gloss, plus stroke counts and 音/訓
readings for single-kanji words and on-device pronunciation. Flutter, offline,
no account.

<sub>Structure descended from a Mandarin/HSK app of the same shape; the visual
identity ("Chōchin") is its own. See [DESIGN_NOTES.md](DESIGN_NOTES.md) for
what was carried over and what was replaced.</sub>

## What's in it

- **Five levels.** N5 (718 words) through N1 (2,654), picked from a row of
  lamps in the hero. Each level keeps its own lantern, its own history and its
  own recently-viewed list; the streak counts a day studied in any of them.
- **Home** — a night panel holding a paper lantern that fills with light as
  the deck is opened, a 7-day row of streak lamps, and recently viewed words.
  The caption counts what's *still dark*, not what's done.
- **Study card** — oversized headword lit by the lantern's own glow, with a
  slow-breathing ghost echo behind it, the kana reading in lantern light,
  romaji, gloss, and a caption line that adds stroke count and 音/訓 readings
  for single-kanji words.
- **Example sentences** for the 150 core N5 words, with an all-kana reading
  and a translation, each speakable on its own. Words without one show no
  sentence rather than an automatically matched approximation.
- **Word class** for 1406 words — godan / ichidan / irregular verbs, and the
  hand-written classes on the core N5 set. Inferred only where it's provable
  (see `infer_part_of_speech`); never guessed for adjectives.
- **Smart Shuffle** — weighted-random "Next" that favors words you haven't
  learned and haven't just seen. Favoriting a word keeps it in rotation even
  after you mark it learned.
- **Searchable word list** — search by kanji, kana, romaji or meaning, and
  filter to what you haven't learned, what you have, or your favorites.
  Learned/favorite/speak sit on every row.
- **Night and day themes.** Dark-first — the lantern needs a night to glow
  against; the light theme is the same lantern seen by daylight, not an
  inversion. Progress, favorites and streaks are stored on-device.

## Running it

```bash
flutter pub get
flutter run          # with an iOS Simulator booted, or a device attached
```

**iOS only.** Requires the Flutter SDK (Dart `^3.12.2`) and Xcode; the repo
carries no `android/`, web or desktop configuration, and adding one is a
deliberate decision, not a missing file. Bundle identifier:
`com.kotobalantern.kotobaLantern`.

## Tests

```bash
flutter test
```

Covers the Smart Shuffle weighting, the deck's asset loading and integrity,
the on-device progress store, the TTS wrapper's language handling, and a
widget pass over the home screen and the study card.

## The decks

`assets/data/*.json` is generated. Rebuild it with:

```bash
python3 scripts/build_jlpt_data.py            # fetches sources, then builds
python3 scripts/build_jlpt_data.py --offline  # rebuild from scripts/.cache
python3 scripts/verify_assets.py              # what CI checks
```

It writes one file per level plus two shared files (`sentences.json`,
`kanji_info.json`, both keyed by headword/character, since a kanji met in N5
turns up again in N2 compounds).

Word lists are Jonathan Waller's JLPT lists (CC BY) via `open-anki-jlpt-decks`;
kanji detail derives from KANJIDIC2 (CC BY-SA 4.0); the example sentences are
hand-written here. The JLPT has published no official vocabulary list since
2010, so the level boundaries are convention rather than the exam's own list.
Full terms — including the share-alike that `kanji_info.json` inherits — are in
[DATA_LICENSES.md](DATA_LICENSES.md).

## Layout

```
lib/
  data/       JlptRepository - stitches the assets into JapaneseWord
  models/     JapaneseWord, WordProgress
  screens/    home, study card, word list, settings, credits
  services/   providers + on-device stores (progress, view history, TTS, theme)
  theme/      color tokens, fonts, light/dark ThemeData
  widgets/    the study card's shared pieces
scripts/      the deck generator
```
