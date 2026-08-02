"""Kana → romaji, in the plain style this app uses.

No macrons and no apostrophes: おおきい is "ookii", not "ōkii", and しんぶん
is "shinbun", not "shimbun". That matches how a beginner types Japanese on a
keyboard, which is the only romaji worth teaching at N5 - it round-trips.

Hepburn otherwise: し shi, ち chi, つ tsu, ふ fu, じ ji, しゃ sha, っ doubles
the following consonant (っち → tchi).
"""

_DIGRAPHS = {
    "きゃ": "kya", "きゅ": "kyu", "きょ": "kyo",
    "しゃ": "sha", "しゅ": "shu", "しょ": "sho",
    "ちゃ": "cha", "ちゅ": "chu", "ちょ": "cho",
    "にゃ": "nya", "にゅ": "nyu", "にょ": "nyo",
    "ひゃ": "hya", "ひゅ": "hyu", "ひょ": "hyo",
    "みゃ": "mya", "みゅ": "myu", "みょ": "myo",
    "りゃ": "rya", "りゅ": "ryu", "りょ": "ryo",
    "ぎゃ": "gya", "ぎゅ": "gyu", "ぎょ": "gyo",
    "じゃ": "ja", "じゅ": "ju", "じょ": "jo",
    "ぢゃ": "ja", "ぢゅ": "ju", "ぢょ": "jo",
    "びゃ": "bya", "びゅ": "byu", "びょ": "byo",
    "ぴゃ": "pya", "ぴゅ": "pyu", "ぴょ": "pyo",
    "ふぁ": "fa", "ふぃ": "fi", "ふぇ": "fe", "ふぉ": "fo",
    "うぃ": "wi", "うぇ": "we", "うぉ": "wo",
    "ゔぁ": "va", "ゔぃ": "vi", "ゔぇ": "ve", "ゔぉ": "vo",
    "てぃ": "ti", "でぃ": "di", "とぅ": "tu", "どぅ": "du",
    "しぇ": "she", "ちぇ": "che", "じぇ": "je",
}

_SINGLES = {
    "あ": "a", "い": "i", "う": "u", "え": "e", "お": "o",
    "か": "ka", "き": "ki", "く": "ku", "け": "ke", "こ": "ko",
    "が": "ga", "ぎ": "gi", "ぐ": "gu", "げ": "ge", "ご": "go",
    "さ": "sa", "し": "shi", "す": "su", "せ": "se", "そ": "so",
    "ざ": "za", "じ": "ji", "ず": "zu", "ぜ": "ze", "ぞ": "zo",
    "た": "ta", "ち": "chi", "つ": "tsu", "て": "te", "と": "to",
    "だ": "da", "ぢ": "ji", "づ": "zu", "で": "de", "ど": "do",
    "な": "na", "に": "ni", "ぬ": "nu", "ね": "ne", "の": "no",
    "は": "ha", "ひ": "hi", "ふ": "fu", "へ": "he", "ほ": "ho",
    "ば": "ba", "び": "bi", "ぶ": "bu", "べ": "be", "ぼ": "bo",
    "ぱ": "pa", "ぴ": "pi", "ぷ": "pu", "ぺ": "pe", "ぽ": "po",
    "ま": "ma", "み": "mi", "む": "mu", "め": "me", "も": "mo",
    "や": "ya", "ゆ": "yu", "よ": "yo",
    "ら": "ra", "り": "ri", "る": "ru", "れ": "re", "ろ": "ro",
    "わ": "wa", "ゐ": "wi", "ゑ": "we", "を": "o", "ん": "n",
    "ゃ": "ya", "ゅ": "yu", "ょ": "yo",
    "ぁ": "a", "ぃ": "i", "ぅ": "u", "ぇ": "e", "ぉ": "o",
    "ゔ": "vu", "ー": "",
    "・": " ", "　": " ", " ": " ",
    "～": "-", "〜": "-",
}


def katakana_to_hiragana(text: str) -> str:
    out = []
    for ch in text:
        code = ord(ch)
        # Katakana block maps onto hiragana with a fixed offset, except for
        # the small vowel marks and ー, which are shared or handled above.
        if 0x30A1 <= code <= 0x30F6:
            out.append(chr(code - 0x60))
        else:
            out.append(ch)
    return "".join(out)


def to_romaji(kana: str) -> str:
    """Converts a kana reading to romaji. Non-kana characters are passed
    through unchanged, so a reading that still has kanji in it comes back
    visibly wrong rather than silently mangled - the generator checks for
    that."""
    text = katakana_to_hiragana(kana)
    out = []
    i = 0
    while i < len(text):
        pair = text[i : i + 2]
        if pair in _DIGRAPHS:
            out.append(_DIGRAPHS[pair])
            i += 2
            continue
        ch = text[i]
        if ch == "っ":
            # Sokuon: double the consonant that follows. ch → t, so っち is
            # "tchi" rather than "cchi".
            nxt = text[i + 1 : i + 3]
            following = _DIGRAPHS.get(nxt) or _SINGLES.get(text[i + 1], "") if i + 1 < len(text) else ""
            if following.startswith("ch"):
                out.append("t")
            elif following:
                out.append(following[0])
            i += 1
            continue
        if ch == "ー":
            # Long-vowel mark: repeat the previous vowel.
            if out and out[-1] and out[-1][-1] in "aiueo":
                out.append(out[-1][-1])
            i += 1
            continue
        out.append(_SINGLES.get(ch, ch))
        i += 1
    return "".join(out).strip()


def is_kana(text: str) -> bool:
    """True for a reading the card can show as furigana. The wave dash is
    allowed: ～えん ("-en") is a real vocabulary item, an affix rather than a
    standalone word, and the dash is part of how it's written."""
    return all(
        0x3041 <= ord(c) <= 0x309F
        or 0x30A1 <= ord(c) <= 0x30FF
        or c in "ー・　 ～〜"
        for c in text
    )
