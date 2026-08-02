import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/japanese_word.dart';
import '../models/word_progress.dart';
import '../services/progress_providers.dart';
import '../services/tts_providers.dart';
import '../services/word_providers.dart';
import '../theme/app_theme.dart';
import 'word_screen.dart';

/// The deck as a list. Tapping a row opens the full study card for that
/// word; the trailing icons toggle learned/favorite and speak the word
/// without leaving the list.
///
/// [words] is shown as-is, in whatever order the caller passes - normally
/// the full deck in canonical order, where each row's position already
/// equals its real word index. [globalIndices], if given, is a parallel
/// list of each row's *real* deck index for a caller showing a
/// reordered/filtered subset (HomeScreen's "Recently viewed → See all").
/// Without it, opening a word from a subset would jump to the wrong word
/// entirely (row position mistaken for its real index) and Prev/Next from
/// there would page through the subset instead of the real deck.
/// [totalWordCount] must then be the real deck size (it defaults to
/// `words.length`, correct only when not using [globalIndices]) so
/// index-clamping isn't done against the subset's smaller size.
class WordListScreen extends ConsumerWidget {
  final List<JapaneseWord> words;
  final String title;
  final List<int>? globalIndices;
  final int? totalWordCount;

  const WordListScreen({
    super.key,
    required this.words,
    this.title = 'JLPT N5 Word List',
    this.globalIndices,
    this.totalWordCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lantern = Theme.of(context).extension<LanternColors>()!;
    final progressMap = ref.watch(wordProgressProvider).value ?? const <String, WordProgress>{};
    final progressNotifier = ref.read(wordProgressProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.separated(
        itemCount: words.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final word = words[index];
          final globalIndex = globalIndices != null ? globalIndices![index] : index;
          final progress = progressMap[word.progressId] ?? WordProgress.empty;

          return ListTile(
            leading: SizedBox(
              width: 64,
              child: Text(
                word.japanese,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            title: Text(
              word.kana,
              style: TextStyle(color: lantern.accent, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(word.english, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    progress.learned ? Icons.check_circle : Icons.check_circle_outline,
                    color: progress.learned ? lantern.accent : null,
                  ),
                  tooltip: progress.learned ? 'Marked as learned' : 'Mark as learned',
                  onPressed: () => progressNotifier.setLearned(word, !progress.learned),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    progress.favorite ? Icons.star : Icons.star_border,
                    color: progress.favorite ? lantern.accent : null,
                  ),
                  tooltip: progress.favorite ? 'Favorited' : 'Add to favorites',
                  onPressed: () => progressNotifier.setFavorite(word, !progress.favorite),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.volume_up),
                  tooltip: 'Hear pronunciation',
                  onPressed: () => ref.read(ttsServiceProvider).speak(word.japanese),
                ),
              ],
            ),
            onTap: () {
              ref
                  .read(currentWordIndexProvider.notifier)
                  .jumpTo(globalIndex, totalWordCount ?? words.length);
              // Push rather than pop-and-rely-on-an-underlying-WordScreen:
              // this list is opened both from within WordScreen (where a
              // pop would land back on it) and standalone from HomeScreen's
              // Library button (where a pop just returns to the caller with
              // the word never shown). Pushing works correctly either way;
              // currentWordIndexProvider is shared state, so any WordScreen
              // already on the stack stays in sync too.
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => WordScreen(initialIndex: globalIndex)),
              );
            },
          );
        },
      ),
    );
  }
}
