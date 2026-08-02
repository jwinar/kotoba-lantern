import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/japanese_word.dart';
import '../services/view_history_providers.dart';
import '../services/view_history_service.dart';
import '../services/word_providers.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';
import 'word_list_screen.dart';
import 'word_screen.dart';

/// The app's dashboard home screen: an ink hero with a progress ring, a
/// 7-day streak row, and a "recently viewed" list. Studying itself happens
/// on [WordScreen], reached by tapping the ring or a recent word.
///
/// The ring counts words actually opened on the study card
/// ([ViewHistoryService]), not words marked learned - it answers "how much
/// of the deck have I looked at", which is the number that makes a daily
/// habit feel like it's moving. Learned/favorite are a separate, explicit
/// signal and deliberately don't feed this.
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
    final viewedCount = await service.viewedCount();
    final recentIndices = await service.recentIndices();
    final activeDateKeys = await service.activeDateKeys();
    final streak = await service.currentStreak();
    return ViewHistorySnapshot(
      viewedCount: viewedCount,
      recentIndices: recentIndices,
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
      final words = await ref.read(n5WordsProvider.future);
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

  /// "See all" under Recently viewed - unlike the Library button (the full
  /// deck in canonical order), this shows only the words in
  /// [recentIndices], in that same most-recent-first order. Passes
  /// [globalIndices]/[totalWordCount] through to [WordListScreen] so
  /// tapping a row opens the *actual* word tapped and Prev/Next from there
  /// pages the real deck rather than this short subset.
  Future<void> _openRecentlyViewed(List<JapaneseWord> words, List<int> recentIndices) async {
    final validIndices = recentIndices.where((i) => i >= 0 && i < words.length).toList();
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
    // Settings can reset progress, which empties the ring and the streak.
    _reloadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = Theme.of(context).extension<DashboardColors>()!;
    final wordsAsync = ref.watch(n5WordsProvider);

    return Scaffold(
      backgroundColor: dashboard.pageBackground,
      body: SafeArea(
        bottom: false,
        child: wordsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Failed to load words: $err')),
          data: (words) => FutureBuilder<ViewHistorySnapshot>(
            future: _historyFuture,
            builder: (context, snapshot) {
              final history = snapshot.data ?? ViewHistorySnapshot.empty;
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeroSection(
                      dashboard: dashboard,
                      viewedCount: history.viewedCount,
                      total: words.length,
                      onTapRing: () => _openWordScreen(),
                      onOpenLibrary: () => _openWordList(words),
                      onSettingsTap: _openSettings,
                    ),
                    _StreakSection(
                      dashboard: dashboard,
                      streak: history.streak,
                      activeDateKeys: history.activeDateKeys,
                    ),
                    _RecentlyViewedSection(
                      dashboard: dashboard,
                      words: words,
                      recentIndices: history.recentIndices,
                      onSeeAll: () => _openRecentlyViewed(words, history.recentIndices),
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

/// The dark ink panel at the top: brand row, proverb, progress ring and
/// the Library shortcut, over a 学 watermark and ink-wash waves.
class _HeroSection extends StatelessWidget {
  final DashboardColors dashboard;
  final int viewedCount;
  final int total;
  final VoidCallback onTapRing;
  final VoidCallback onOpenLibrary;
  final VoidCallback onSettingsTap;

  const _HeroSection({
    required this.dashboard,
    required this.viewedCount,
    required this.total,
    required this.onTapRing,
    required this.onOpenLibrary,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = total == 0 ? 0.0 : (viewedCount / total).clamp(0.0, 1.0);
    final percentLabel = total == 0 ? 0 : ((viewedCount / total) * 100).round();

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
      child: ColoredBox(
        color: dashboard.heroPanel,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              right: -36,
              top: -8,
              child: Text(
                '学',
                style: jpFont(
                  fontSize: 220,
                  fontWeight: FontWeight.w700,
                  color: dashboard.accentGold.withValues(alpha: isDark ? 0.14 : 0.20),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _HeroWavePainter(isDark: isDark, waveColor: dashboard.pageBackground),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BrandSeal(dashboard: dashboard),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(
                              'Kotoba Lantern',
                              style: displayFont(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: dashboard.heroText,
                              ),
                            ),
                            Text(
                              '日本語 · JLPT N5',
                              style: jpFont(
                                fontSize: 12,
                                letterSpacing: 0.6,
                                color: dashboard.accentGold.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.settings_outlined, color: dashboard.heroText),
                        tooltip: 'Settings',
                        onPressed: onSettingsTap,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      // "Perseverance is strength" - the habit the streak
                      // row below is trying to build, said the old way.
                      '継続は力なり',
                      style: brushFont(fontSize: 22, color: dashboard.accentGold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: GestureDetector(
                      onTap: onTapRing,
                      child: SizedBox(
                        width: 176,
                        height: 176,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: progress),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return CustomPaint(
                              painter: _RingPainter(
                                progress: value,
                                trackColor: Colors.white.withValues(alpha: isDark ? 0.14 : 0.16),
                                arcColor: dashboard.accentGold,
                                strokeWidth: 9,
                              ),
                              child: child,
                            );
                          },
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$viewedCount',
                                  style: displayFont(
                                    fontSize: 56,
                                    fontWeight: FontWeight.w600,
                                    color: dashboard.heroText,
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                                Text(
                                  'OF $total STUDIED',
                                  style: bodyFont(
                                    fontSize: 11,
                                    letterSpacing: 1.2,
                                    color: dashboard.accentGold.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      '$percentLabel% through JLPT N5 — keep going.',
                      textAlign: TextAlign.center,
                      style: bodyFont(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: dashboard.heroText.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: onOpenLibrary,
                      icon: Icon(Icons.menu_book_outlined, size: 16, color: dashboard.accentGold),
                      label: Text(
                        'Library',
                        style: bodyFont(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: dashboard.accentGold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: dashboard.accentGold.withValues(alpha: 0.6)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
  final DashboardColors dashboard;

  const _BrandSeal({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: dashboard.accentGold,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        '語',
        style: jpFont(fontSize: 22, fontWeight: FontWeight.w700, color: dashboard.heroPanel),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color arcColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.arcColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final arcPaint = Paint()
        ..color = arcColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      const startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.arcColor != arcColor ||
      oldDelegate.strokeWidth != strokeWidth;
}

/// Decorative ink-wash wave bands + scallop arcs along the hero's bottom
/// edge, painted in the page background color at low opacity so they read
/// as a soft transition into the section below.
class _HeroWavePainter extends CustomPainter {
  final bool isDark;
  final Color waveColor;

  _HeroWavePainter({required this.isDark, required this.waveColor});

  @override
  void paint(Canvas canvas, Size size) {
    final band1Opacity = isDark ? 0.16 : 0.28;
    final band2Opacity = isDark ? 0.10 : 0.16;
    final scallopOpacity = isDark ? 0.18 : 0.22;

    void drawBand(double baseY, double amplitude, double opacity) {
      final path = Path()..moveTo(0, baseY);
      final quarter = size.width / 4;
      path.quadraticBezierTo(quarter, baseY - amplitude, quarter * 2, baseY);
      path.quadraticBezierTo(quarter * 3, baseY + amplitude, size.width, baseY);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
      canvas.drawPath(path, Paint()..color = waveColor.withValues(alpha: opacity));
    }

    drawBand(size.height - 50, 10, band1Opacity);
    drawBand(size.height - 30, 8, band2Opacity);

    final scallopPaint = Paint()..color = waveColor.withValues(alpha: scallopOpacity);
    const scallopCount = 3;
    final scallopWidth = size.width / scallopCount;
    for (var i = 0; i < scallopCount; i++) {
      final cx = scallopWidth * (i + 0.5);
      canvas.drawCircle(Offset(cx, size.height), scallopWidth * 0.5, scallopPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HeroWavePainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.waveColor != waveColor;
}

class _StreakSection extends StatelessWidget {
  final DashboardColors dashboard;
  final int streak;
  final Set<String> activeDateKeys;

  const _StreakSection({
    required this.dashboard,
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              style: bodyFont(fontSize: 15, color: dashboard.ink),
              children: [
                const TextSpan(text: 'This week · '),
                TextSpan(
                  text: '$streak-day streak ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                // 火 needs the Japanese face explicitly. Inheriting the
                // body font (Lora, Latin-only) leaves it to whatever the
                // platform happens to fall back to - which renders as a
                // tofu box anywhere without a CJK system font.
                TextSpan(text: '火', style: jpFont(fontSize: 15, color: dashboard.ink)),
              ],
            ),
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
                            color: active ? dashboard.accentGold : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: active
                                ? null
                                : Border.all(color: dashboard.hairline, width: 1.2),
                          ),
                          child: active
                              ? Center(
                                  child: Text(
                                    '火',
                                    style: jpFont(fontSize: 14, color: dashboard.heroPanel),
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _weekdayLetters[i],
                        style: bodyFont(fontSize: 11, color: dashboard.subText),
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
  final DashboardColors dashboard;
  final List<JapaneseWord> words;
  final List<int> recentIndices;
  final VoidCallback onSeeAll;
  final ValueChanged<int> onTapWord;

  const _RecentlyViewedSection({
    required this.dashboard,
    required this.words,
    required this.recentIndices,
    required this.onSeeAll,
    required this.onTapWord,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final validIndices =
        recentIndices.where((i) => i >= 0 && i < words.length).take(6).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _WaveLinePainter(
                color: dashboard.subText.withValues(alpha: isDark ? 0.30 : 0.40),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recently viewed',
                    style: bodyFont(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: dashboard.ink,
                    ),
                  ),
                  GestureDetector(
                    onTap: onSeeAll,
                    child: Text(
                      'See all',
                      style: bodyFont(fontSize: 13, color: dashboard.accentGold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (validIndices.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Words you view will show up here.',
                    style: bodyFont(fontSize: 13, color: dashboard.subText),
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
                                  style: jpFont(fontSize: 22, color: dashboard.ink),
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
                                        color: dashboard.accentGold,
                                      ),
                                    ),
                                    Text(
                                      word.english,
                                      style: bodyFont(fontSize: 13, color: dashboard.subText),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: dashboard.subText),
                            ],
                          ),
                        ),
                      ),
                      if (!isLast) Divider(height: 1, color: dashboard.hairline),
                    ],
                  );
                }),
            ],
          ),
        ],
      ),
    );
  }
}

class _WaveLinePainter extends CustomPainter {
  final Color color;

  _WaveLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * 0.18;
    final path = Path()..moveTo(0, y);
    path.quadraticBezierTo(size.width * 0.25, y - 14, size.width * 0.5, y);
    path.quadraticBezierTo(size.width * 0.75, y + 14, size.width, y);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _WaveLinePainter oldDelegate) => oldDelegate.color != color;
}
