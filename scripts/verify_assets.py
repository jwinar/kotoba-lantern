#!/usr/bin/env python3
"""Checks the generated decks without needing the network.

CI runs this instead of regenerating: the generator pulls from upstream word
lists, so a byte-for-byte comparison would fail whenever someone else fixes a
typo in a list, which says nothing about this repo. These invariants are what
the app actually depends on.
"""

import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from romaji import is_kana  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, "assets", "data")
MINIMUM = {5: 600, 4: 600, 3: 1800, 2: 1600, 1: 2400}

failures = []


def check(condition: bool, message: str) -> None:
    if not condition:
        failures.append(message)


def main() -> None:
    ids = set()
    total = 0
    for level, minimum in MINIMUM.items():
        with open(os.path.join(DATA, f"jlpt_n{level}.json"), encoding="utf-8") as handle:
            words = json.load(handle)
        check(len(words) >= minimum, f"N{level}: only {len(words)} words, expected >= {minimum}")
        total += len(words)
        for index, word in enumerate(words, start=1):
            where = f"N{level} #{index} ({word.get('japanese')})"
            for field in ("japanese", "kana", "romaji", "english"):
                check(bool(word.get(field)), f"{where}: empty {field}")
            check(word.get("level") == level, f"{where}: level is {word.get('level')}")
            check(word.get("order") == index, f"{where}: order out of sequence")
            check(is_kana(word["kana"]), f"{where}: reading is not kana")
            word_id = f"{level}_{word['japanese']}"
            check(word_id not in ids, f"{where}: duplicate id {word_id}")
            ids.add(word_id)

    with open(os.path.join(DATA, "sentences.json"), encoding="utf-8") as handle:
        sentences = json.load(handle)
    for headword, sentence in sentences.items():
        for field in ("japanese", "kana", "english"):
            check(bool(sentence.get(field)), f"sentence for {headword}: empty {field}")

    with open(os.path.join(DATA, "kanji_info.json"), encoding="utf-8") as handle:
        kanji = json.load(handle)
    for character, info in kanji.items():
        check(len(character) == 1, f"kanji_info key {character!r} is not a single character")
        check(isinstance(info.get("strokes"), int), f"{character}: no stroke count")

    print(f"{total} words · {len(sentences)} sentences · {len(kanji)} kanji")
    if failures:
        print(f"\n{len(failures)} problem(s):")
        for failure in failures[:25]:
            print(f"  - {failure}")
        raise SystemExit(1)
    print("all invariants hold")


if __name__ == "__main__":
    main()
