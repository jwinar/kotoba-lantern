import 'package:flutter_tts/flutter_tts.dart';

/// Wraps [FlutterTts] to speak Japanese (ja-JP) text on demand, using the
/// on-device TTS engine (free, works offline).
///
/// Speaking the written form rather than the kana reading is deliberate:
/// Japanese TTS voices read kanji in context, and handing them the kana
/// instead loses the pitch and phrasing cues that make a sentence sound
/// like a sentence.
class TtsService {
  TtsService({FlutterTts? flutterTts}) : _tts = flutterTts ?? FlutterTts();

  final FlutterTts _tts;
  bool _languageSet = false;

  Future<void> speak(String text) async {
    if (!_languageSet) {
      await _tts.setLanguage('ja-JP');
      _languageSet = true;
    }
    await _tts.stop();
    await _tts.speak(text);
  }
}
