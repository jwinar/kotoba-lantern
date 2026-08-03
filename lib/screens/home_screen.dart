import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/jlpt_repository.dart';
import '../models/japanese_word.dart';
import '../services/level_providers.dart';
import '../services/view_history_providers.dart';
import '../services/view_history_service.dart';
import '../services/word_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/lantern.dart';
import 'settings_screen.dart';
import 'word_list_screen.dart';
import 'word_screen.dart';

/// The app's home screen: a night hero holding the lantern, a 7-day streak
/// row of lamps, and a "recently viewed" list. Studying itself happens on
/// [WordScreen], reached by tapping the lantern or a recent word.
///
/// The lantern fills with light for every word actually opened on the study
/// card ([ViewHistoryService]) - not for words marked learned. It answers
/// "how much of the deck have I looked at", which is the number that makes
/// a daily habit feel like it's moving. Learned/favorite are a separate,
/// explicit signal and deliberately don't feed it.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late Future<ViewHistorySnapshot> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadSnapshot();
  }

  Future<ViewHistorySnapshot> _loadSnapshot() async {
    final service = ref.read(viewHistoryServiceProvider);
    final level = ref.read(levelProvider);
    final viewedCount = await service.viewedCount(level);
    final recentIds = await service.recentIds(level);
    final activeDateKeys = await service.activeDateKeys();
    final streak = await service.currentStreak();
    return ViewHistorySnapshot(
      viewedCount: viewedCount,
      recentIds: recentIds,
      activeDateKeys: activeDateKeys,
      streak: streak,
    );
  }

  void _reloadHistory() {
    if (!mounted) return;
    final future = _loadSnapshot();
    setState(() {
      _historyFuture = future;
    });
  }

  Future<void> _openWordScreen({int? jumpToIndex}) async {
    if (jumpToIndex != null) {
      final words = await ref.read(wordsProvider.future);
      if (!mounted) return;
      ref.read(currentWordIndexProvider.notifier).jumpTo(jumpToIndex, words.length);
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WordScreen(initialIndex: jumpToIndex)),
    );
    _reloadHistory();
  }

  Future<void> _openWordList(List<JapaneseWord> words) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WordListScreen(words: words)),
    );
    _reloadHistory();
  }

  Future<void> _selectLevel(int level) async {
    await ref.read(levelProvider.notifier).setLevel(level);
    _reloadHistory();
  }

  /// "See all" under Recently viewed - unlike the Library button (the full
  /// deck in canonical order), this shows only the words in
  /// [recentIndices], in that same most-recent-first order. Passes
  /// [globalIndices]/[totalWordCount] through to [WordListScreen] so
  /// tapping a row opens the *actual* word tapped and Prev/Next from there
  /// pages the real deck rather than this short subset.
  Future<void> _openRecentlyViewed(List<JapaneseWord> words, List<int> recentIndices) async {
    final validIndices = recentIndices.toList();
    final recentWords = [for (final i in validIndices) words[i]];
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WordListScreen(
          words: recentWords,
          title: 'Recently Viewed',
          globalIndices: validIndices,
          totalWordCount: words.length,
        ),
      ),
    );
    _reloadHistory();
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    // Settings can reset progress, which puts the lantern out.
    _reloadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final lantern = Theme.of(context).extension<LanternColors>()!;
    final wordsAsync = ref.watch(wordsProvider);
    final level = ref.watch(levelProvider);

    return Scaffold(
      backgroundColor: lantern.pageBackground,
      body: SafeArea(
        bottom: false,
        child: wordsAsync.when(
          loading: () => Center(child: CircularProgressIndicator(color: lantern.accent)),
          error: (err, stack) => Center(child: Text('Failed to load words: $err')),
          data: (words) => FutureBuilder<ViewHistorySnapshot>(
            future: _historyFuture,
            builder: (context, snapshot) {
              final history = snapshot.data ?? ViewHistorySnapshot.empty;
              // History is keyed by word id; the list is keyed by position.
              // Resolve once here so both the "recently viewed" rows and
              // their tap targets agree, and so an id from a word that has
              // since left the deck simply doesn't appear.
              final positionOf = {
                for (var i = 0; i < words.length; i++) words[i].id: i,
              };
              final recentIndices = [
                for (final id in history.recentIds)
                  if (positionOf[id] != null) positionOf[id]!,
              ];
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeroSection(
                      lantern: lantern,
                      level: level,
                      viewedCount: history.viewedCount,
                      total: words.length,
                      onTapLantern: () => _openWordScreen(),
                      onOpenLibrary: () => _openWordList(words),
                      onSettingsTap: _openSettings,
                      onSelectLevel: _selectLevel,
                    ),
                    _StreakSection(
                      lantern: lantern,
                      streak: history.streak,
                      activeDateKeys: history.activeDateKeys,
                    ),
                    _RecentlyViewedSection(
                      lantern: lantern,
                      words: words,
                      recentIndices: recentIndices,
                      onSeeAll: () => _openRecentlyViewed(words, recentIndices),
                      onTapWord: (index) => _openWordScreen(jumpToIndex: index),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The night panel: brand row, proverb, the lantern, and the Library
/// shortcut, over a warm glow that reads as the lantern lighting the panel
/// it hangs in.
class _HeroSection extends StatelessWidget {
  final LanternColors lantern;
  final int level;
  final int viewedCount;
  final int total;
  final VoidCallback onTapLantern;
  final VoidCallback onOpenLibrary;
  final VoidCallback onSettingsTap;
  final ValueChanged<int> onSelectLevel;

  const _HeroSection({
    required this.lantern,
    required this.level,
    required this.viewedCount,
    required this.total,
    required this.onTapLantern,
    required this.onOpenLibrary,
    required this.onSettingsTap,
    required this.onSelectLevel,
  });

  @override
  Widget build(BuildContext context) {
    final lit = total == 0 ? 0.0 : (viewedCount / total).clamp(0.0, 1.0);
    final percentLit = (lit * 100).round();
    final stillDark = (total - viewedCount).clamp(0, total);
    final accent = lantern.accentOnHero;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomCenter,
            colors: [lantern.heroPanelTop, lantern.heroPanelBottom],
            stops: const [0.0, 0.72],
          ),
        ),
        child: Stack(
          children: [
            // The lantern's own light spilling onto the panel. Drawn behind
            // everything, centred on where the lantern hangs, and dimmed
            // with the deck's progress: an unlit lantern casts no glow.
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: LanternGlowPainter(color: accent, intensity: 0.25 + 0.75 * lit),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BrandSeal(lantern: lantern),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 3),
                            Text(
                              'Kotoba Lantern',
                              style: displayFont(fontSize: 21, color: lantern.heroText),
                            ),
                            Text(
                              '日本語 · JLPT ${levelLabel(level)}',
                              style: jpFont(
                                fontSize: 11.5,
                                letterSpacing: 0.6,
                                color: accent.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.settings_outlined, color: lantern.heroText),
                        tooltip: 'Settings',
                        onPressed: onSettingsTap,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      // "Perseverance is strength" - the habit the streak
                      // row below is trying to build, said the old way.
                      '継続は力なり',
                      style: jpFont(
                        fontSize: 13,
                        letterSpacing: 3,
                        color: accent.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _LevelSelector(
                    lantern: lantern,
                    selected: level,
                    onSelect: onSelectLevel,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: GestureDetector(
                      onTap: onTapLantern,
                      child: SizedBox(
                        width: 150,
                        height: 208,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: lit),
                          duration: const Duration(milliseconds: 1100),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return CustomPaint(painter: LanternPainter(lit: value, light: accent), child: child);
                          },
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$viewedCount',
                                  style: displayFont(fontSize: 46, color: lantern.heroText),
                                ),
                                Text(
                                  'OF $total',
                                  style: labelFont(fontSize: 10.5, color: lantern.heroText.withValues(alpha: 0.8)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      // Counts what's left rather than what's done: with an
                      // empty deck "0% lit" is discouraging, while "150
                      // words still dark" is just a fact about the lantern.
                      '$percentLit% lit — $stillDark words still dark',
                      textAlign: TextAlign.center,
                      style: bodyFont(fontSize: 12.5, color: lantern.heroText.withValues(alpha: 0.7)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: onOpenLibrary,
                      icon: Icon(Icons.menu_book_outlined, size: 16, color: accent),
                      label: Text(
                        'Library',
                        style: bodyFont(fontSize: 13, fontWeight: FontWeight.w600, color: accent),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: accent.withValues(alpha: 0.7)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandSeal extends StatelessWidget {
  final LanternColors lantern;

  const _BrandSeal({required this.lantern});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: lantern.accentOnHero,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: lantern.accentOnHero.withValues(alpha: 0.45),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '語',
        style: jpFont(fontSize: 21, fontWeight: FontWeight.w700, color: lantern.heroPanelBottom),
      ),
    );
  }
}

class _StreakSection extends StatelessWidget {
  final LanternColors lantern;
  final int streak;
  final Set<String> activeDateKeys;

  const _StreakSection({
    required this.lantern,
    required this.streak,
    required this.activeDateKeys,
  });

  static const _weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('This week', style: bodyFont(fontSize: 15, fontWeight: FontWeight.w600, color: lantern.ink)),
              Text(
                streak == 1 ? '1-day streak' : '$streak-day streak',
                style: bodyFont(fontSize: 13, color: lantern.accent),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(7, (i) {
              final active = activeDateKeys.contains(ViewHistoryService.dateKey(weekDays[i]));
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == 6 ? 0 : 8),
                  child: Column(
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            // A lit day is a small lantern of its own; an
                            // unlit one is the same lamp, unlit - the
                            // outline stays so the week reads as seven
                            // lamps rather than four shapes and three gaps.
                            color: active ? lantern.accent : Colors.transparent,
                            shape: BoxShape.circle,
                            border: active ? null : Border.all(color: lantern.hairline, width: 1.2),
                            boxShadow: active
                                ? [
                                    BoxShadow(
                                      color: lantern.accent.withValues(alpha: 0.4),
                                      blurRadius: 12,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '灯',
                              style: jpFont(
                                fontSize: 13,
                                color: active
                                    ? lantern.heroPanelBottom
                                    : lantern.subText.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _weekdayLetters[i],
                        style: bodyFont(fontSize: 11, color: lantern.subText),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _RecentlyViewedSection extends StatelessWidget {
  final LanternColors lantern;
  final List<JapaneseWord> words;
  final List<int> recentIndices;
  final VoidCallback onSeeAll;
  final ValueChanged<int> onTapWord;

  const _RecentlyViewedSection({
    required this.lantern,
    required this.words,
    required this.recentIndices,
    required this.onSeeAll,
    required this.onTapWord,
  });

  @override
  Widget build(BuildContext context) {
    final validIndices =
        recentIndices.where((i) => i >= 0 && i < words.length).take(6).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recently viewed',
                style: bodyFont(fontSize: 15, fontWeight: FontWeight.w600, color: lantern.ink),
              ),
              GestureDetector(
                onTap: onSeeAll,
                child: Text('See all', style: bodyFont(fontSize: 13, color: lantern.accent)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (validIndices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Words you view will show up here.',
                style: bodyFont(fontSize: 13, color: lantern.subText),
              ),
            )
          else
            ...List.generate(validIndices.length, (i) {
              final word = words[validIndices[i]];
              final isLast = i == validIndices.length - 1;
              return Column(
                children: [
                  InkWell(
                    onTap: () => onTapWord(validIndices[i]),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 72,
                            child: Text(
                              word.japanese,
                              style: jpFont(fontSize: 22, fontWeight: FontWeight.w500, color: lantern.ink),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  word.kana,
                                  style: jpFont(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: lantern.accent,
                                  ),
                                ),
                                Text(
                                  word.english,
                                  style: bodyFont(fontSize: 13, color: lantern.subText),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: lantern.subText),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast) Divider(height: 1, color: lantern.hairline),
                ],
              );
            }),
        ],
      ),
    );
  }
}

/// The five JLPT levels as a row of small lanterns strung on a wire, N5
/// through N1. The selected one is lit; the rest hang dark.
///
/// A row rather than a dropdown because the level is the single most
/// consequential choice in the app - it decides which 700-2,700 words you
/// are looking at - and because five is few enough to show all of them.
class _LevelSelector extends StatelessWidget {
  final LanternColors lantern;
  final int selected;
  final ValueChanged<int> onSelect;

  const _LevelSelector({
    required this.lantern,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final accent = lantern.accentOnHero;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final level in jlptLevels)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Semantics(
              button: true,
              selected: level == selected,
              label: 'JLPT ${levelLabel(level)}',
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onSelect(level),
                // The pill itself is ~30pt tall; the tap target around it is
                // padded out to iOS's 44pt minimum, so switching levels
                // isn't a game of precision.
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                  decoration: BoxDecoration(
                    color: level == selected ? accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: level == selected
                          ? accent
                          : lantern.heroText.withValues(alpha: 0.22),
                    ),
                    boxShadow: level == selected
                        ? [BoxShadow(color: accent.withValues(alpha: 0.4), blurRadius: 14)]
                        : null,
                  ),
                  child: Text(
                    levelLabel(level),
                    style: bodyFont(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: level == selected
                          ? lantern.heroPanelBottom
                          : lantern.heroText.withValues(alpha: 0.65),
                    ),
                  ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
