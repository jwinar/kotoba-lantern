import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:kotoba_lantern/services/tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter_tts');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
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

    expect(calls.map((c) => c.method), ['setLanguage', 'stop', 'speak']);
    expect(calls[0].arguments, 'ja-JP');
    expect(calls[2].arguments, '水');
  });

  test('speak does not re-set the language on subsequent calls', () async {
    final service = TtsService(flutterTts: FlutterTts());

    await service.speak('水');
    calls.clear();
    await service.speak('山');

    expect(calls.map((c) => c.method), ['stop', 'speak']);
    expect(calls[1].arguments, '山');
  });
}
