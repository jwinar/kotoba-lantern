import 'package:flutter/material.dart';

/// Credits for the third-party material the app ships or renders with.
class AttributionsScreen extends StatelessWidget {
  const AttributionsScreen({super.key});

  static const _entries = <(String, String)>[
    (
      'Vocabulary',
      'The N5-N1 word lists are Jonathan Waller\'s JLPT vocabulary lists '
          '(tanos.co.uk), licensed CC BY, by way of the open-anki-jlpt-decks '
          'project (MIT).\n\n'
          'The JLPT is run by the Japan Foundation and JEES, which have '
          'published no official vocabulary list since 2010. These lists are '
          'widely used reconstructions, not the exam\'s own word list, and '
          'this app is not endorsed by either body.',
    ),
    (
      'Kanji readings & stroke counts',
      'Derived from KANJIDIC2, © the Electronic Dictionary Research and '
          'Development Group, licensed CC BY-SA 4.0. The kanji data this app '
          'ships is a derivative of KANJIDIC2 and is itself CC BY-SA 4.0.',
    ),
    (
      'Example sentences',
      'The 150 example sentences are written for this app by hand, one per '
          'word for the core N5 vocabulary. Words without one simply show no '
          'sentence rather than an automatically matched approximation.',
    ),
    (
      'Type',
      'Zen Kaku Gothic New, by Yoshimichi Ohira, served via the google_fonts '
          'package and licensed under the SIL Open Font License 1.1. It carries '
          'kanji, kana and Latin in one voice, which is why the app uses a '
          'single family throughout.',
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
