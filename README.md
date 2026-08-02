# Kotoba Lantern

A quiet daily Japanese vocabulary deck: 150 core **JLPT N5** words, each with
its kana reading, romaji, gloss, an example sentence, and on-device
pronunciation. Flutter, offline, no account.

<sub>Design descended from a Mandarin/HSK app of the same shape — see
[DESIGN_NOTES.md](DESIGN_NOTES.md) for what was carried over and what was
rebuilt for Japanese.</sub>

## What's in it

- **Dashboard home** — ink hero panel with a progress ring (words opened, out
  of 150), a 7-day streak row, and recently viewed words.
- **Study card** — oversized headword with a slow-breathing ghost echo behind
  it, kana reading in gold, romaji, gloss, and a caption line that adds stroke
  count and 音/訓 readings for single-kanji words.
- **Example sentence** per word, with its all-kana reading and a translation,
  each speakable on its own.
- **Smart Shuffle** — weighted-random "Next" that favors words you haven't
  learned and haven't just seen. Favoriting a word keeps it in rotation even
  after you mark it learned.
- **Word list** — the whole deck, with learned/favorite/speak on each row.
- Light and dark themes; progress, favorites and streaks stored on-device.

## Running it

```bash
flutter pub get
flutter run
```

Requires the Flutter SDK (Dart `^3.12.2`). Android and iOS are the supported
targets; there is no web or desktop configuration.

## Tests

```bash
flutter test
```

Covers the Smart Shuffle weighting, the deck's asset loading and integrity,
the on-device progress store, the TTS wrapper's language handling, and a
widget pass over the home screen and the study card.

## The deck

`assets/data/*.json` is generated — edit
[`scripts/build_n5_data.py`](scripts/build_n5_data.py) and re-run it:

```bash
python3 scripts/build_n5_data.py
```

It writes three files (word list, sentences, single-kanji info) rather than
one, deliberately: a single large JSON asset makes `rootBundle.loadString`
hang under `flutter_test`'s mocked asset channel.

The word list is hand-curated core N5 vocabulary. The JLPT is run by the Japan
Foundation and JEES, which publish no official vocabulary list — this is our
own selection and is not endorsed by either body.

## Layout

```
lib/
  data/       N5Repository - stitches the three assets into JapaneseWord
  models/     JapaneseWord, WordProgress
  screens/    home, study card, word list, settings, credits
  services/   providers + on-device stores (progress, view history, TTS, theme)
  theme/      color tokens, fonts, light/dark ThemeData
  widgets/    the study card's shared pieces
scripts/      the deck generator
```
