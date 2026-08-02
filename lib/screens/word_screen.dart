import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/japanese_word.dart';
import '../models/word_progress.dart';
import '../services/progress_providers.dart';
import '../services/shuffle_providers.dart';
import '../services/tts_providers.dart';
import '../services/view_history_providers.dart';
import '../services/word_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/word_card.dart';
import 'settings_screen.dart';
import 'word_list_screen.dart';

/// The study card: an oversized headword with a slow-breathing ghost echo
/// behind it, thin gold side hairlines, an ink-wash wave at the card's
/// foot, and the JLPT rail in the top-right corner.
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
    final dashboard = Theme.of(context).extension<DashboardColors>()!;
    final wordsAsync = ref.watch(n5WordsProvider);
    final shuffleMode = ref.watch(shuffleModeProvider);

    return Scaffold(
      backgroundColor: dashboard.pageBackground,
      appBar: AppBar(
        backgroundColor: dashboard.pageBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 18, color: dashboard.ink.withValues(alpha: 0.7)),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Kotoba Lantern',
          style: displayFont(fontSize: 22, fontWeight: FontWeight.w600, color: dashboard.ink),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.shuffle,
              color: shuffleMode ? dashboard.accentGold : dashboard.ink.withValues(alpha: 0.6),
            ),
            tooltip: shuffleMode ? 'Smart shuffle on' : 'Smart shuffle',
            onPressed: () {
              ref.read(shuffleModeProvider.notifier).toggle();
              ref.read(shuffleHistoryProvider.notifier).clear();
            },
          ),
          IconButton(
            icon: Icon(Icons.list, color: dashboard.ink.withValues(alpha: 0.6)),
            tooltip: 'Word list',
            onPressed: wordsAsync.maybeWhen(
              data: (words) => () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => WordListScreen(words: words)),
              ),
              orElse: () => null,
            ),
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: dashboard.ink.withValues(alpha: 0.6)),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: wordsAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: dashboard.accentGold)),
        error: (err, stack) => Center(child: Text('Failed to load words: $err')),
        data: (words) => _WordBrowser(words: words, dashboard: dashboard),
      ),
    );
  }
}

class _WordBrowser extends ConsumerStatefulWidget {
  final List<JapaneseWord> words;
  final DashboardColors dashboard;

  const _WordBrowser({required this.words, required this.dashboard});

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
      ref.read(viewHistoryServiceProvider).recordView(index);
      ref.read(wordProgressProvider.notifier).markSeen(word);
    });
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.words;
    final dashboard = widget.dashboard;

    if (words.isEmpty) {
      return Center(
        child: Text('No words available.', style: bodyFont(color: dashboard.ink)),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final motif = isDark ? CardMotif.dark : CardMotif.light;

    final index = ref.watch(currentWordIndexProvider).clamp(0, words.length - 1);
    final word = words[index];
    final notifier = ref.read(currentWordIndexProvider.notifier);
    _recordView(index, word);

    final progressMap = ref.watch(wordProgressProvider).value ?? const <String, WordProgress>{};
    final progress = progressMap[word.progressId] ?? WordProgress.empty;
    final progressNotifier = ref.read(wordProgressProvider.notifier);

    final shuffleMode = ref.watch(shuffleModeProvider);
    final shuffleHistory = ref.watch(shuffleHistoryProvider);
    final ttsService = ref.read(ttsServiceProvider);

    Future<void> shuffleNext() async {
      final recentIndices = await ref.read(viewHistoryServiceProvider).recentIndices(limit: 30);
      if (!mounted) return;
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
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: waveFloorHeight,
          child: CustomPaint(
            painter: WaveFloorPainter(
              color: dashboard.accentGold,
              opacity1: motif.waveOpacity1,
              opacity2: motif.waveOpacity2,
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          top: 12,
          bottom: waveFloorHeight,
          child: IgnorePointer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 1.5, color: dashboard.accentGold.withValues(alpha: motif.railOpacity)),
                Container(width: 1.5, color: dashboard.accentGold.withValues(alpha: motif.railOpacity)),
              ],
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 30,
          child: JlptRail(dashboard: dashboard, level: word.level),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: waveFloorHeight,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: HeroContent(
                word: word,
                dashboard: dashboard,
                motif: motif,
                onSpeak: () => ttsService.speak(word.japanese),
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
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (word.exampleSentence != null)
                  ExampleCard(
                    word: word,
                    dashboard: dashboard,
                    onSpeak: () => ttsService.speak(word.exampleSentence!),
                  ),
                const SizedBox(height: 12),
                Pager(
                  dashboard: dashboard,
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
