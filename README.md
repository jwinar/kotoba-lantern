# Kotoba Lantern

A quiet daily Japanese vocabulary deck: 150 core **JLPT N5** words, each with
its kana reading, romaji, gloss, an example sentence, and on-device
pronunciation. Flutter, offline, no account.

<sub>Structure descended from a Mandarin/HSK app of the same shape; the visual
identity ("Chōchin") is its own. See [DESIGN_NOTES.md](DESIGN_NOTES.md) for
what was carried over and what was replaced.</sub>

## What's in it

- **Home** — a night panel holding a paper lantern that fills with light as
  the deck is opened, a 7-day row of streak lamps, and recently viewed words.
  The caption counts what's *still dark*, not what's done.
- **Study card** — oversized headword lit by the lantern's own glow, with a
  slow-breathing ghost echo behind it, the kana reading in lantern light,
  romaji, gloss, and a caption line that adds stroke count and 音/訓 readings
  for single-kanji words.
- **Example sentence** per word, with its all-kana reading and a translation,
  each speakable on its own.
- **Smart Shuffle** — weighted-random "Next" that favors words you haven't
  learned and haven't just seen. Favoriting a word keeps it in rotation even
  after you mark it learned.
- **Word list** — the whole deck, with learned/favorite/speak on each row.
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
