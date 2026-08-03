#!/usr/bin/env python3
"""Builds the app's JLPT N5-N1 assets.

Run from the repo root:

    python3 scripts/build_jlpt_data.py          # downloads sources if needed
    python3 scripts/build_jlpt_data.py --offline  # cache only, no network

Writes, into assets/data/:

  jlpt_n5.json … jlpt_n1.json   one file per level, in list order
  sentences.json                 example sentences, keyed by headword
  kanji_info.json                strokes + on/kun for every kanji used

Sources (downloaded into scripts/.cache/, which is gitignored):

  Vocabulary  jamsinclair/open-anki-jlpt-decks - MIT, and the word lists
              themselves come from Jonathan Waller's tanos.co.uk lists,
              licensed CC BY. These are reconstructions: the JLPT has
              published no official vocabulary list since the 2010 redesign,
              so treat level boundaries as well-established convention
              rather than as the exam's own word list.
  Kanji       davidluzgouveia/kanji-data, derived from KANJIDIC2
              (Electronic Dictionary Research and Development Group,
              CC BY-SA 4.0). Only the KANJIDIC-derived fields are used -
              strokes and on/kun readings - never the WaniKani ones.
  Sentences   hand-written for this app, carried over from the original
              150-word N5 deck (scripts/curated_n5.json).

Curated data always wins over generated: where curated_n5.json has a
romaji or a part of speech for a word, the imported record keeps it.
"""

import argparse
import csv
import json
import os
import sys
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from romaji import is_kana, to_romaji  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CACHE = os.path.join(ROOT, "scripts", ".cache")
OUT_DIR = os.path.join(ROOT, "assets", "data")
CURATED = os.path.join(ROOT, "scripts", "curated_n5.json")

VOCAB_URL = "https://raw.githubusercontent.com/jamsinclair/open-anki-jlpt-decks/main/src/n{level}.csv"
KANJI_URL = "https://raw.githubusercontent.com/davidluzgouveia/kanji-data/master/kanji.json"

LEVELS = [5, 4, 3, 2, 1]

# Readings where kana does not map to romaji mechanically, because the kana
# is orthographic rather than phonetic - は and へ as particles. Rare inside
# single vocabulary entries, so a small table beats a parser.
ROMAJI_OVERRIDES = {
    "こんにちは": "konnichiwa",
    "こんばんは": "konbanwa",
    "では": "dewa",
    "それでは": "soredewa",
}


def fetch(url: str, filename: str, offline: bool) -> str:
    os.makedirs(CACHE, exist_ok=True)
    path = os.path.join(CACHE, filename)
    if os.path.exists(path) and os.path.getsize(path) > 0:
        return path
    if offline:
        raise SystemExit(f"--offline but {path} is missing; run once with network access")
    print(f"  fetching {url}")
    with urllib.request.urlopen(url, timeout=120) as response, open(path, "wb") as handle:
        handle.write(response.read())
    return path


def is_kanji(ch: str) -> bool:
    return 0x4E00 <= ord(ch) <= 0x9FFF


def normalize(expression: str, reading: str) -> tuple[str, str]:
    """Turns a source row into the single primary form the card shows.

    The lists carry four shapes that aren't a plain word:

      足; 脚          variants, semicolon-separated → keep the first
      けっこん (する)  a parenthetical noting the word also takes する
      (〜を) とお      a parenthetical noting the usual particle
      ～円 / お～      an affix, marked with a wave dash - kept as-is,
                      since "-en" *is* the vocabulary item

    Variants and parentheticals are dropped rather than shown: the card has
    one headword line and one furigana line, and "足; 脚" in 190pt type is
    not a word anyone is learning.
    """
    def first_variant(value: str) -> str:
        # Variants are separated by ";" in most rows, by the ideographic
        # comma 、 in a handful (回る、回す), and by a plain comma in one.
        for separator in (";", "、", "，", ","):
            value = value.split(separator)[0]
        return value.strip()

    def strip_parentheticals(value: str) -> str:
        """Parentheses mean three different things in these lists:

          しまった (かん)      a word-class marker → drop
          スーパー (マーケット) an optional longer form → drop, the word is スーパー
          ～(に) ついて        an inline particle → keep the content, drop the
                              brackets, so the headword reads ～について
          (花を〜) 生ける      a usage note before the word → drop

        A trailing or leading group is a note about the word; a group in the
        middle is part of it.
        """
        value = value.replace("（", "(").replace("）", ")")
        while "(" in value and ")" in value:
            start = value.index("(")
            end = value.index(")", start)
            inner = value[start + 1 : end]
            leading = value[:start].strip()
            trailing = value[end + 1 :].strip()
            if not leading or not trailing:
                # A note hanging off one end - drop the whole group.
                value = (leading + " " + trailing).strip()
            else:
                # Bracketed material between two halves of the word itself.
                value = f"{leading}{inner}{trailing}"
        return " ".join(value.split())

    expression = strip_parentheticals(first_variant(expression))
    reading = strip_parentheticals(first_variant(reading))
    reading = " ".join(reading.split())
    # A few rows have the two columns the wrong way round (expression
    # いただく, reading 頂く). Detect it by which side is kana rather than
    # hard-coding the words.
    if reading and not is_kana(reading) and is_kana(expression):
        expression, reading = reading, expression
    return expression, reading or expression


def clean_reading(reading: str) -> str:
    """KANJIDIC kun readings carry okurigana markers (みず-, た.べる) that are
    noise on a study card."""
    return reading.replace("-", "").replace(".", "").strip()


def load_curated() -> dict:
    if not os.path.exists(CURATED):
        return {}
    with open(CURATED, encoding="utf-8") as handle:
        return {entry["japanese"]: entry for entry in json.load(handle)}


def romaji_for(kana: str, curated: dict | None) -> str:
    if curated and curated.get("romaji"):
        return curated["romaji"]
    if kana in ROMAJI_OVERRIDES:
        return ROMAJI_OVERRIDES[kana]
    return to_romaji(kana)


def build_level(level: int, curated: dict, offline: bool, already: set) -> list:
    path = fetch(VOCAB_URL.format(level=level), f"n{level}.csv", offline)
    words = []
    seen = set()
    with open(path, encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            expression, reading = normalize(
                row.get("expression") or "", row.get("reading") or ""
            )
            meaning = (row.get("meaning") or "").strip()
            if not expression or not meaning:
                continue
            if expression in seen or expression in already:
                continue
            seen.add(expression)

            entry = curated.get(expression)
            record = {
                "japanese": expression,
                "kana": reading,
                "romaji": romaji_for(reading, entry),
                "english": meaning,
                "level": level,
                "order": len(words) + 1,
            }
            # Word class is only trustworthy where a human wrote it. The
            # source lists carry none, and guessing "godan verb" from a
            # gloss that starts with "to " would be wrong often enough to
            # mislead - the card simply omits the line when it's absent.
            if entry and entry.get("partOfSpeech"):
                record["partOfSpeech"] = entry["partOfSpeech"]
            words.append(record)
    return words


def build_kanji_info(all_words: list, offline: bool) -> dict:
    path = fetch(KANJI_URL, "kanji.json", offline)
    with open(path, encoding="utf-8") as handle:
        source = json.load(handle)

    used = {ch for word in all_words for ch in word["japanese"] if is_kanji(ch)}
    info = {}
    for ch in sorted(used):
        entry = source.get(ch)
        if not entry:
            continue
        record = {}
        if entry.get("strokes"):
            record["strokes"] = entry["strokes"]
        on = [clean_reading(r) for r in entry.get("readings_on") or []]
        kun = [clean_reading(r) for r in entry.get("readings_kun") or []]
        # On readings are conventionally written in katakana and kun in
        # hiragana; the source stores both in hiragana.
        if on:
            record["on"] = "".join(chr(ord(c) + 0x60) if 0x3041 <= ord(c) <= 0x3096 else c for c in on[0])
        if kun:
            record["kun"] = kun[0]
        if record:
            info[ch] = record
    return info


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--offline", action="store_true", help="use scripts/.cache only")
    args = parser.parse_args()

    os.makedirs(OUT_DIR, exist_ok=True)
    curated = load_curated()
    print(f"curated entries: {len(curated)}")

    all_words = []
    per_level = {}
    # Levels are walked easiest-first, and a word claimed by an easier level
    # is dropped from the harder ones: the source lists overlap, and a word
    # learned at N5 shouldn't reappear as a fresh N3 card with its own
    # separate progress.
    claimed: set = set()
    for level in LEVELS:
        words = build_level(level, curated, args.offline, claimed)
        per_level[level] = words
        claimed.update(word["japanese"] for word in words)
        all_words.extend(words)
        print(f"  N{level}: {len(words)} words")

    # Readings must be kana. Anything else means a malformed source row and
    # would render as a broken furigana line on the card.
    bad = [w for w in all_words if not is_kana(w["kana"])]
    if bad:
        raise SystemExit(f"{len(bad)} entries have non-kana readings, e.g. {[b['japanese'] for b in bad[:5]]}")

    # Curated words the source list writes differently (ご飯 vs ごはん,
    # 勉強する vs 勉強) or simply doesn't carry. They're ordinary N5
    # vocabulary and each one has a hand-written example sentence, so they
    # join the end of N5 rather than being dropped on a spelling mismatch.
    extra = [entry for word, entry in curated.items() if word not in claimed]
    for entry in extra:
        record = {
            "japanese": entry["japanese"],
            "kana": entry["kana"],
            "romaji": entry["romaji"],
            "english": entry["english"],
            "level": 5,
            "order": len(per_level[5]) + 1,
        }
        if entry.get("partOfSpeech"):
            record["partOfSpeech"] = entry["partOfSpeech"]
        per_level[5].append(record)
        all_words.append(record)
    if extra:
        print(f"  + {len(extra)} curated words appended to N5")

    kanji_info = build_kanji_info(all_words, args.offline)

    sentences = {}
    for entry in curated.values():
        if entry.get("exampleSentence"):
            sentences[entry["japanese"]] = {
                "japanese": entry["exampleSentence"],
                "kana": entry["exampleSentenceKana"],
                "english": entry["exampleSentenceEnglish"],
            }

    def write(name, payload):
        path = os.path.join(OUT_DIR, name)
        with open(path, "w", encoding="utf-8") as handle:
            json.dump(payload, handle, ensure_ascii=False, separators=(",", ":"))
            handle.write("\n")
        print(f"  wrote {name} ({os.path.getsize(path) / 1024:.0f} KB)")

    print("output:")
    for level in LEVELS:
        write(f"jlpt_n{level}.json", per_level[level])
    write("sentences.json", sentences)
    write("kanji_info.json", kanji_info)

    covered = sum(1 for w in all_words if w["japanese"] in sentences)
    with_pos = sum(1 for w in all_words if w.get("partOfSpeech"))
    print(
        f"\n{len(all_words)} words across {len(LEVELS)} levels · "
        f"{len(kanji_info)} kanji · {covered} with an example sentence · "
        f"{with_pos} with a word class"
    )


if __name__ == "__main__":
    main()
