import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/progress_providers.dart';
import '../services/theme_mode_providers.dart';
import '../services/view_history_providers.dart';
import '../services/level_providers.dart';
import '../services/word_providers.dart';
import 'attributions_screen.dart';
import 'word_list_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _resetProgress(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset progress?'),
        content: const Text(
          'This clears every learned and favorited word, the progress ring '
          'and your streak. The deck itself is untouched, and this cannot be '
          'undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // Both stores, one action: the ring and the streak read view history
    // while learned/favorite read the progress store, but to the user
    // that's all "my progress".
    await ref.read(wordProgressProvider.notifier).clear();
    await ref.read(viewHistoryServiceProvider).clear();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Progress reset.')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final level = ref.watch(levelProvider);
    final wordsAsync = ref.watch(wordsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text('Word list'),
            subtitle: Text(
              wordsAsync.maybeWhen(
                data: (words) =>
                    'Browse all ${words.length} JLPT ${levelLabel(level)} words',
                orElse: () => 'Browse the JLPT ${levelLabel(level)} deck',
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: wordsAsync.maybeWhen(
              data: (words) =>
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WordListScreen(words: words),
                    ),
                  ),
              orElse: () => null,
            ),
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'Appearance',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (selection) =>
                  ref.read(themeModeProvider.notifier).setMode(selection.first),
            ),
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Fonts, data & credits'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AttributionsScreen()),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.restart_alt,
              color: Theme.of(context).colorScheme.error,
            ),
            title: const Text('Reset progress'),
            subtitle: const Text(
              'Clears learned, favorites, the ring and the streak',
            ),
            onTap: () => _resetProgress(context, ref),
          ),
        ],
      ),
    );
  }
}
