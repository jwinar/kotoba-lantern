import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/japanese_word.dart';
import '../models/word_progress.dart';
import '../services/progress_providers.dart';
import '../services/shuffle_providers.dart';
import '../services/speak.dart';
import '../services/view_history_providers.dart';
import '../services/word_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/lantern.dart';
import '../widgets/word_card.dart';
import 'home_screen.dart' show DeckLoadFailure;
import 'settings_screen.dart';
import 'word_list_screen.dart';

/// The study card: the headword lit by the lantern's own light, with a
/// slow-breathing ghost echo behind it, thin accent hairlines down the
/// sides, and the level rail in the top-right corner.
class WordScreen extends ConsumerWidget {
  /// If provided, the caller has already chosen a word (e.g. tapping a
  /// "Recently viewed" row) and set [currentWordIndexProvider] to match.
  /// Kept as a field only so the screen can be identified in tests and
  /// future deep-link handling; the index itself lives in the provider, so
  /// any other screen watching it stays in sync.
  final int? initialIndex;

  const WordScreen({super.key, this.initialIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lantern = Theme.of(context).extension<LanternColors>()!;
    final wordsAsync = ref.watch(wordsProvider);
    final shuffleMode = ref.watch(shuffleModeProvider);

    return Scaffold(
      backgroundColor: lantern.pageBackground,
      appBar: AppBar(
        backgroundColor: lantern.pageBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 18, color: lantern.ink.withValues(alpha: 0.7)),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Kotoba Lantern',
          style: displayFont(fontSize: 18, color: lantern.ink),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.shuffle,
              color: shuffleMode ? lantern.accent : lantern.ink.withValues(alpha: 0.6),
            ),
            tooltip: shuffleMode ? 'Smart shuffle on' : 'Smart shuffle',
            onPressed: () {
              ref.read(shuffleModeProvider.notifier).toggle();
              ref.read(shuffleHistoryProvider.notifier).clear();
            },
          ),
          IconButton(
            icon: Icon(Icons.list, color: lantern.ink.withValues(alpha: 0.6)),
            tooltip: 'Word list',
            onPressed: wordsAsync.maybeWhen(
              data: (words) => () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => WordListScreen(words: words)),
              ),
              orElse: () => null,
            ),
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: lantern.ink.withValues(alpha: 0.6)),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: wordsAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: lantern.accent)),
        error: (err, stack) => DeckLoadFailure(lantern: lantern, error: err),
        data: (words) => _WordBrowser(words: words, lantern: lantern),
      ),
    );
  }
}

class _WordBrowser extends ConsumerStatefulWidget {
  final List<JapaneseWord> words;
  final LanternColors lantern;

  const _WordBrowser({required this.words, required this.lantern});

  @override
  ConsumerState<_WordBrowser> createState() => _WordBrowserState();
}

class _WordBrowserState extends ConsumerState<_WordBrowser> {
  // The index whose view has already been recorded. Recording happens after
  // the frame, not during build(): both writes touch providers/storage, and
  // Riverpod forbids mutating a provider while the tree is building.
  int? _recordedIndex;

  void _recordView(int index, JapaneseWord word) {
    if (_recordedIndex == index) return;
    _recordedIndex = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(viewHistoryServiceProvider).recordView(word.level, word.id);
      ref.read(wordProgressProvider.notifier).markSeen(word);
    });
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.words;
    final lantern = widget.lantern;

    if (words.isEmpty) {
      return Center(
        child: Text('No words available.', style: bodyFont(color: lantern.ink)),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final motif = isDark ? CardMotif.dark : CardMotif.light;

    final index = ref.watch(currentWordIndexProvider).clamp(0, words.length - 1);
    final word = words[index];
    final notifier = ref.read(currentWordIndexProvider.notifier);
    _recordView(index, word);

    final progressMap = ref.watch(wordProgressProvider).value ?? const <String, WordProgress>{};
    final progress = progressMap[word.id] ?? WordProgress.empty;
    final progressNotifier = ref.read(wordProgressProvider.notifier);

    final shuffleMode = ref.watch(shuffleModeProvider);
    final shuffleHistory = ref.watch(shuffleHistoryProvider);

    Future<void> shuffleNext() async {
      final recentIds = await ref
          .read(viewHistoryServiceProvider)
          .recentIds(word.level, limit: 30);
      if (!mounted) return;
      // History stores ids; the weighting works in positions, so resolve
      // against the deck actually loaded. Ids for words no longer in the
      // deck drop out rather than shifting everything after them.
      final positionOf = {for (var i = 0; i < words.length; i++) words[i].id: i};
      final recentIndices = [
        for (final id in recentIds)
          if (positionOf[id] != null) positionOf[id]!,
      ];
      ref.read(shuffleHistoryProvider.notifier).push(index);
      ref.read(currentWordIndexProvider.notifier).jumpToRandom(
        words: words,
        progress: progressMap,
        recentIndices: recentIndices,
      );
    }

    void shufflePrevious() {
      final previousIndex = ref.read(shuffleHistoryProvider.notifier).pop();
      if (previousIndex != null) {
        ref.read(currentWordIndexProvider.notifier).jumpTo(previousIndex, words.length);
      }
    }

    return Stack(
      children: [
        // The same light the lantern throws on the home screen, here
        // centred behind the headword - the card reads as the page you're
        // holding up to it.
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: LanternGlowPainter(
                color: lantern.accent,
                intensity: motif.glowIntensity,
                center: const Alignment(0, -0.25),
              ),
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          top: 12,
          bottom: 150,
          child: IgnorePointer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 1.2, color: lantern.accent.withValues(alpha: motif.railOpacity)),
                Container(width: 1.2, color: lantern.accent.withValues(alpha: motif.railOpacity)),
              ],
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 28,
          child: LevelRail(lantern: lantern, level: word.level),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: 150,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: HeroContent(
                word: word,
                lantern: lantern,
                motif: motif,
                onSpeak: () => speakOrExplain(context, ref, word.japanese),
                learned: progress.learned,
                favorite: progress.favorite,
                onToggleLearned: () => progressNotifier.setLearned(word, !progress.learned),
                onToggleFavorite: () => progressNotifier.setFavorite(word, !progress.favorite),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (word.exampleSentence != null)
                  ExampleCard(
                    word: word,
                    lantern: lantern,
                    motif: motif,
                    onSpeak: () => speakOrExplain(context, ref, word.exampleSentence!),
                  ),
                const SizedBox(height: 8),
                Pager(
                  lantern: lantern,
                  index: index,
                  total: words.length,
                  onPrevious: shuffleMode
                      ? (shuffleHistory.isNotEmpty ? shufflePrevious : null)
                      : (index > 0 ? notifier.previous : null),
                  onNext: shuffleMode
                      ? () => shuffleNext()
                      : (index < words.length - 1 ? () => notifier.next(words.length) : null),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
