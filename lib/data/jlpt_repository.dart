import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/japanese_word.dart';

/// The five JLPT levels, easiest first - the order they're offered in.
const List<int> jlptLevels = [5, 4, 3, 2, 1];

/// Loads a level's deck, stitching together the three assets
/// `scripts/build_jlpt_data.py` writes: the per-level word list, the shared
/// example sentences, and the shared kanji info.
///
/// Sentences and kanji info are shared files rather than per-level ones
/// because both are keyed by headword/character, and a kanji used in an N5
/// word turns up again in N2 compounds - one copy, looked up by whichever
/// level is open.
class JlptRepository {
  static const String _sentencesAsset = 'assets/data/sentences.json';
  static const String _kanjiInfoAsset = 'assets/data/kanji_info.json';

  static String levelAsset(int level) => 'assets/data/jlpt_n$level.json';

  /// Decodes an asset without `rootBundle.loadString`.
  ///
  /// loadString hands large payloads to a background isolate, which used to
  /// deadlock under flutter_test's mocked asset channel; N1 is 315KB, well
  /// past where that mattered. Decoding the bytes here keeps every level on
  /// the same code path in tests and on device.
  static Future<dynamic> _decode(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    return jsonDecode(utf8.decode(data.buffer.asUint8List()));
  }

  Future<List<JapaneseWord>> loadLevel(int level) async {
    assert(jlptLevels.contains(level), 'no such JLPT level: N$level');
    final results = await Future.wait([
      _decode(levelAsset(level)),
      _decode(_sentencesAsset),
      _decode(_kanjiInfoAsset),
    ]);
    final decoded = results[0] as List<dynamic>;
    final sentences = results[1] as Map<String, dynamic>;
    final kanjiInfo = results[2] as Map<String, dynamic>;

    return decoded.map((e) {
      final json = e as Map<String, dynamic>;
      final japanese = json['japanese'] as String;
      final sentence = sentences[japanese] as Map<String, dynamic>?;
      // Kanji info describes *a* character, so it only makes sense for a
      // headword that is exactly one kanji - 友達 has no single stroke
      // count, and showing 友's would be a lie about the word on screen.
      final info = japanese.runes.length == 1
          ? kanjiInfo[japanese] as Map<String, dynamic>?
          : null;
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
  }
}
