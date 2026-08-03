import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tts_providers.dart';
import 'tts_service.dart';

/// Speaks [text], and says something if the device can't.
///
/// Every speak button in the app goes through here. A device with no
/// Japanese voice installed accepts the request and stays silent, which is
/// indistinguishable from a broken button - so the one case worth
/// explaining gets a message that names the fix.
Future<void> speakOrExplain(
  BuildContext context,
  WidgetRef ref,
  String text,
) async {
  final result = await ref.read(ttsServiceProvider).speak(text);
  if (result == SpeakResult.spoken || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        result == SpeakResult.noJapaneseVoice
            ? 'No Japanese voice on this device. Add one in Settings → '
                  'Accessibility → Spoken Content → Voices → Japanese.'
            : "The device's speech engine didn't respond.",
      ),
      duration: const Duration(seconds: 5),
    ),
  );
}
