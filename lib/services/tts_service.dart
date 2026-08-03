import 'package:flutter_tts/flutter_tts.dart';

/// The outcome of asking the device to speak.
enum SpeakResult {
  /// The engine accepted the utterance.
  spoken,

  /// The device has no Japanese voice installed. Nothing was spoken, and
  /// nothing the app can do will change that - the user has to add the
  /// voice in iOS Settings → Accessibility → Spoken Content → Voices.
  noJapaneseVoice,

  /// The engine failed for some other reason.
  failed,
}

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

  /// Cached so a device without a Japanese voice isn't re-interrogated on
  /// every tap; null until the first attempt.
  bool? _japaneseAvailable;

  /// True when the device can actually speak Japanese.
  ///
  /// A device with no Japanese voice accepts `speak` and stays silent,
  /// which reads as a broken button. Asking first lets the caller say
  /// what's wrong instead.
  Future<bool> isJapaneseAvailable() async {
    if (_japaneseAvailable != null) return _japaneseAvailable!;
    try {
      final available = await _tts.isLanguageAvailable('ja-JP');
      _japaneseAvailable = available == true;
    } catch (_) {
      // Some engines don't implement the query; assume yes rather than
      // disabling audio on a device that may well work.
      _japaneseAvailable = true;
    }
    return _japaneseAvailable!;
  }

  Future<SpeakResult> speak(String text) async {
    if (!await isJapaneseAvailable()) return SpeakResult.noJapaneseVoice;
    try {
      if (!_languageSet) {
        await _tts.setLanguage('ja-JP');
        _languageSet = true;
      }
      await _tts.stop();
      await _tts.speak(text);
      return SpeakResult.spoken;
    } catch (_) {
      return SpeakResult.failed;
    }
  }
}
