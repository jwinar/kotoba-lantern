import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tts_service.dart';

final ttsServiceProvider = Provider<TtsService>((ref) {
  return TtsService();
});
