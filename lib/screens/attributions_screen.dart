import 'package:flutter/material.dart';

/// Credits for the third-party material the app ships or renders with.
class AttributionsScreen extends StatelessWidget {
  const AttributionsScreen({super.key});

  static const _entries = <(String, String)>[
    (
      'Vocabulary & example sentences',
      'The bundled JLPT N5 deck is hand-curated for this app (see '
          'scripts/build_n5_data.py). JLPT levels are published by the Japan '
          'Foundation and JEES, which do not release an official vocabulary '
          'list; this deck is our own selection of core N5 words and is not '
          'endorsed by either body.',
    ),
    (
      'Fonts',
      'Noto Serif JP, Cormorant Garamond, Lora and Yuji Syuku, served via '
          'the google_fonts package. All four are licensed under the SIL Open '
          'Font License 1.1.',
    ),
    (
      'Pronunciation',
      'Spoken audio comes from the Japanese voice already installed on your '
          'device, through the flutter_tts package. No audio is recorded, '
          'bundled or sent anywhere.',
    ),
    (
      'Your data',
      'Progress, favorites and streaks are stored only on this device. The '
          'app has no account, no analytics and makes no network requests of '
          'its own.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fonts, data & credits')),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _entries.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final (title, body) = _entries[index];
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(body, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          );
        },
      ),
    );
  }
}
