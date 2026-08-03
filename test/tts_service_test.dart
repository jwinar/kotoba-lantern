import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:kotoba_lantern/services/tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter_tts');
  final calls = <MethodCall>[];
  var japaneseAvailable = true;

  setUp(() {
    calls.clear();
    japaneseAvailable = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      // The service asks whether Japanese exists before speaking; the real
      // plugin answers this one with a bool.
      if (call.method == 'isLanguageAvailable') return japaneseAvailable;
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('speak sets ja-JP on the first call, then stops and speaks', () async {
    final service = TtsService(flutterTts: FlutterTts());

    await service.speak('水');

    expect(calls.map((c) => c.method),
        ['isLanguageAvailable', 'setLanguage', 'stop', 'speak']);
    expect(calls[1].arguments, 'ja-JP');
    expect(calls[3].arguments, '水');
  });

  test('speak does not re-set the language on subsequent calls', () async {
    final service = TtsService(flutterTts: FlutterTts());

    await service.speak('水');
    calls.clear();
    await service.speak('山');

    expect(calls.map((c) => c.method), ['stop', 'speak']);
    expect(calls[1].arguments, '山');
  });

  test('a device with no Japanese voice reports it instead of staying silent',
      () async {
    japaneseAvailable = false;
    final service = TtsService(flutterTts: FlutterTts());

    expect(await service.speak('水'), SpeakResult.noJapaneseVoice);
    expect(calls.map((c) => c.method), ['isLanguageAvailable']);
  });
}
