import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/japanese_word.dart';

/// Loads the bundled JLPT N5 deck, stitching the three assets
/// `scripts/build_n5_data.py` writes into one list of [JapaneseWord].
class N5Repository {
  static const String _assetPath = 'assets/data/n5.json';

  // Example sentences and kanji info live in separate asset files rather
  // than as extra fields on n5.json. Not a data-modeling preference: a
  // single large JSON makes `rootBundle.loadString` hang under
  // flutter_test's mocked asset channel (the Mandarin app this design came
  // from hit the same wall at ~66KB and split its asset the same way).
  // Several smaller files sidestep that threshold entirely.
  static const String _sentencesAssetPath = 'assets/data/n5_sentences.json';
  static const String _kanjiInfoAssetPath = 'assets/data/n5_kanji_info.json';

  Future<List<JapaneseWord>> loadWords() async {
    final results = await Future.wait([
      rootBundle.loadString(_assetPath),
      rootBundle.loadString(_sentencesAssetPath),
      rootBundle.loadString(_kanjiInfoAssetPath),
    ]);
    final decoded = jsonDecode(results[0]) as List<dynamic>;
    final sentences = jsonDecode(results[1]) as Map<String, dynamic>;
    final kanjiInfo = jsonDecode(results[2]) as Map<String, dynamic>;

    final words = decoded.map((e) {
      final json = e as Map<String, dynamic>;
      final sentence = sentences[json['japanese']] as Map<String, dynamic>?;
      final info = kanjiInfo[json['japanese']] as Map<String, dynamic>?;
      return JapaneseWord.fromJson({
        ...json,
        if (sentence != null) 'exampleSentence': sentence['japanese'],
        if (sentence != null) 'exampleSentenceKana': sentence['kana'],
        if (sentence != null) 'exampleSentenceEnglish': sentence['english'],
        if (info != null) 'strokeCount': info['strokes'],
        if (info != null) 'onReading': info['on'],
        if (info != null) 'kunReading': info['kun'],
      });
    }).toList()..sort((a, b) => a.order.compareTo(b.order));
    return words;
  }
}
