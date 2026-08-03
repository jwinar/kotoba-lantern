import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/japanese_word.dart';
import '../models/word_progress.dart';
import '../services/progress_providers.dart';
import '../services/speak.dart';
import '../services/word_providers.dart';
import '../theme/app_theme.dart';
import 'word_screen.dart';

/// Which slice of the deck the list is showing.
enum DeckFilter {
  all('All'),
  unlearned('Not learned'),
  learned('Learned'),
  favorites('Favorites');

  const DeckFilter(this.label);

  final String label;
}

/// The deck as a searchable list. Tapping a row opens the full study card
/// for that word; the trailing icons toggle learned/favorite and speak the
/// word without leaving the list.
///
/// Search and filtering matter here in a way they didn't when this was a
/// 150-word screen: N1 is 2,654 rows, and scrolling to a particular word is
/// not a plan. Search matches the written form, the kana, the romaji and
/// the English gloss, so it works whichever of those the user has in mind.
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
class WordListScreen extends ConsumerStatefulWidget {
  final List<JapaneseWord> words;

  /// Defaults to the level of the words being shown, so the Library button
  /// and "Recently viewed → See all" both say what deck you're looking at.
  final String? title;
  final List<int>? globalIndices;
  final int? totalWordCount;

  const WordListScreen({
    super.key,
    required this.words,
    this.title,
    this.globalIndices,
    this.totalWordCount,
  });

  @override
  ConsumerState<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends ConsumerState<WordListScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  DeckFilter _filter = DeckFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesQuery(JapaneseWord word, String query) {
    if (query.isEmpty) return true;
    return word.japanese.contains(query) ||
        word.kana.contains(query) ||
        word.romaji.toLowerCase().contains(query) ||
        word.english.toLowerCase().contains(query);
  }

  bool _matchesFilter(WordProgress progress) {
    return switch (_filter) {
      DeckFilter.all => true,
      DeckFilter.unlearned => !progress.learned,
      DeckFilter.learned => progress.learned,
      DeckFilter.favorites => progress.favorite,
    };
  }

  @override
  Widget build(BuildContext context) {
    final lantern = Theme.of(context).extension<LanternColors>()!;
    final progressMap =
        ref.watch(wordProgressProvider).value ?? const <String, WordProgress>{};
    final progressNotifier = ref.read(wordProgressProvider.notifier);
    final query = _query.trim().toLowerCase();

    // Filtering keeps each row's real deck index alongside it, so tapping a
    // filtered row still opens the right word and pages the real deck.
    final rows = <(JapaneseWord, int)>[];
    for (var i = 0; i < widget.words.length; i++) {
      final word = widget.words[i];
      final progress = progressMap[word.id] ?? WordProgress.empty;
      if (!_matchesFilter(progress)) continue;
      if (!_matchesQuery(word, query)) continue;
      rows.add((word, widget.globalIndices?[i] ?? i));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title ??
              (widget.words.isEmpty
                  ? 'Word list'
                  : 'JLPT N${widget.words.first.level}'),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search kanji, kana, romaji or meaning',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final filter in DeckFilter.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(filter.label),
                            selected: _filter == filter,
                            onSelected: (_) => setState(() => _filter = filter),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: rows.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  query.isNotEmpty
                      ? 'No words match “$_query”.'
                      : switch (_filter) {
                          DeckFilter.favorites =>
                            'No favorites yet. Star a word to keep it in rotation.',
                          DeckFilter.learned =>
                            'Nothing marked learned in this level yet.',
                          DeckFilter.unlearned =>
                            'Every word in this level is marked learned.',
                          DeckFilter.all => 'This deck is empty.',
                        },
                  textAlign: TextAlign.center,
                  style: bodyFont(fontSize: 14, color: lantern.subText),
                ),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Row(
                    children: [
                      Text(
                        rows.length == widget.words.length
                            ? '${rows.length} words'
                            : '${rows.length} of ${widget.words.length} words',
                        style: bodyFont(fontSize: 12, color: lantern.subText),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final (word, globalIndex) = rows[index];
                      final progress =
                          progressMap[word.id] ?? WordProgress.empty;

                      return ListTile(
                        leading: SizedBox(
                          width: 64,
                          child: Text(
                            word.japanese,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        title: Text(
                          word.kana,
                          style: TextStyle(
                            color: lantern.accent,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          word.english,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                progress.learned
                                    ? Icons.check_circle
                                    : Icons.check_circle_outline,
                                color: progress.learned ? lantern.accent : null,
                              ),
                              tooltip: progress.learned
                                  ? 'Marked as learned'
                                  : 'Mark as learned',
                              onPressed: () => progressNotifier.setLearned(
                                word,
                                !progress.learned,
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                progress.favorite
                                    ? Icons.star
                                    : Icons.star_border,
                                color: progress.favorite
                                    ? lantern.accent
                                    : null,
                              ),
                              tooltip: progress.favorite
                                  ? 'Favorited'
                                  : 'Add to favorites',
                              onPressed: () => progressNotifier.setFavorite(
                                word,
                                !progress.favorite,
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.volume_up),
                              tooltip: 'Hear pronunciation',
                              onPressed: () =>
                                  speakOrExplain(context, ref, word.japanese),
                            ),
                          ],
                        ),
                        onTap: () {
                          ref
                              .read(currentWordIndexProvider.notifier)
                              .jumpTo(
                                globalIndex,
                                widget.totalWordCount ?? widget.words.length,
                              );
                          // Push rather than pop-and-rely-on-an-underlying-
                          // WordScreen: this list is opened both from within
                          // WordScreen (where a pop would land back on it) and
                          // standalone from the Library button (where a pop
                          // just returns to the caller with the word never
                          // shown). Pushing works either way;
                          // currentWordIndexProvider is shared state, so any
                          // WordScreen already on the stack stays in sync.
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  WordScreen(initialIndex: globalIndex),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
