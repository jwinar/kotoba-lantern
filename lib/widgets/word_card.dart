import 'package:flutter/material.dart';

import '../models/japanese_word.dart';
import '../theme/app_theme.dart';

/// Shared visual pieces of the word study card: the breathing-echo hero
/// word, the JLPT rail, the example-sentence card, the pager and the wave
/// floor. Kept as its own file so a second level (N4) can reuse the card
/// wholesale rather than growing a second, slightly different one.

/// Motif tokens for the card's decorative layers (breathing echo, side
/// hairlines, wave floor, example-box tint) - separate from
/// [DashboardColors] since these are opacities specific to this card
/// composition, not reusable app-wide tokens.
class CardMotif {
  final double echoOpacityLow;
  final double echoOpacityHigh;
  final double railOpacity;
  final double waveOpacity1;
  final double waveOpacity2;
  final double exampleBoxOpacity;

  const CardMotif({
    required this.echoOpacityLow,
    required this.echoOpacityHigh,
    required this.railOpacity,
    required this.waveOpacity1,
    required this.waveOpacity2,
    required this.exampleBoxOpacity,
  });

  static const light = CardMotif(
    echoOpacityLow: 0.045,
    echoOpacityHigh: 0.08,
    railOpacity: 0.4,
    waveOpacity1: 0.26,
    waveOpacity2: 0.15,
    exampleBoxOpacity: 0.06,
  );

  static const dark = CardMotif(
    echoOpacityLow: 0.05,
    echoOpacityHigh: 0.09,
    railOpacity: 0.28,
    waveOpacity1: 0.14,
    waveOpacity2: 0.09,
    exampleBoxOpacity: 0.08,
  );
}

/// Height reserved at the bottom of the card for [WaveFloorPainter].
const double waveFloorHeight = 165;

/// The word, its breathing ghost echo, kana reading, romaji, gloss, the
/// caption line (word class, plus stroke count and readings for a single
/// kanji), and the action row.
///
/// Sized by character count, but always wrapped defensively in [FittedBox]
/// so neither the headword nor the reading line can overflow - Japanese
/// headwords range from one kanji (山) to eight kana (おねがいします), and
/// the kana line is usually longer than the word above it.
class HeroContent extends StatelessWidget {
  final JapaneseWord word;
  final DashboardColors dashboard;
  final CardMotif motif;
  final VoidCallback onSpeak;
  final bool learned;
  final bool favorite;
  final VoidCallback? onToggleLearned;
  final VoidCallback? onToggleFavorite;

  const HeroContent({
    super.key,
    required this.word,
    required this.dashboard,
    required this.motif,
    required this.onSpeak,
    required this.learned,
    required this.favorite,
    required this.onToggleLearned,
    required this.onToggleFavorite,
  });

  static const _heroSizes = {1: 190.0, 2: 132.0, 3: 96.0, 4: 74.0, 5: 62.0};

  @override
  Widget build(BuildContext context) {
    final charCount = word.japanese.runes.length;
    final heroSize = _heroSizes[charCount] ?? 52.0;
    final echoSize = heroSize * 1.9;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: BreathingEcho(
                    text: word.japanese,
                    fontSize: echoSize,
                    color: dashboard.ink,
                    opacityLow: motif.echoOpacityLow,
                    opacityHigh: motif.echoOpacityHigh,
                  ),
                ),
              ),
              Text(
                word.japanese,
                style: jpFont(fontSize: heroSize, fontWeight: FontWeight.w700, color: dashboard.ink),
                maxLines: 1,
                softWrap: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // The kana reading is the line a learner actually needs; romaji sits
        // under it, smaller and quieter, as the training wheel it is.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            word.kana,
            style: jpFont(fontSize: 26, fontWeight: FontWeight.w600, color: dashboard.accentGold),
            maxLines: 1,
            softWrap: false,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            word.romaji,
            style: bodyFont(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: dashboard.subText,
              letterSpacing: 1.4,
            ),
            maxLines: 1,
            softWrap: false,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          word.english,
          textAlign: TextAlign.center,
          style: displayFont(fontSize: 27, fontWeight: FontWeight.w600, color: dashboard.ink).copyWith(
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            children: [
              for (final segment in captionFor(word))
                TextSpan(
                  text: segment.text,
                  // Japanese segments (音/訓 and the readings themselves)
                  // must name the Japanese face. Left to the italic body
                  // font, which has no CJK coverage, they fall back to
                  // whatever the platform offers - tofu boxes where that's
                  // nothing.
                  style: segment.isJapanese
                      ? jpFont(fontSize: 15, color: dashboard.subText)
                      : bodyFont(
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          color: dashboard.subText,
                          letterSpacing: 0.6,
                        ),
                ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleGlyphButton(
              diameter: 36,
              iconSize: 16,
              color: dashboard.accentGold,
              icon: learned ? Icons.check_circle : Icons.check_circle_outline,
              active: learned,
              activeIconColor: dashboard.heroPanel,
              tooltip: learned ? 'Marked as learned' : 'Mark as learned',
              onTap: onToggleLearned,
            ),
            const SizedBox(width: 16),
            CircleGlyphButton(
              diameter: 44,
              iconSize: 18,
              color: dashboard.accentGold,
              tooltip: 'Hear pronunciation',
              onTap: onSpeak,
            ),
            const SizedBox(width: 16),
            CircleGlyphButton(
              diameter: 36,
              iconSize: 16,
              color: dashboard.accentGold,
              icon: favorite ? Icons.star : Icons.star_border,
              active: favorite,
              activeIconColor: dashboard.heroPanel,
              tooltip: favorite ? 'Favorited' : 'Add to favorites',
              onTap: onToggleFavorite,
            ),
          ],
        ),
      ],
    );
  }
}

/// One run of the caption line, tagged with which face has to draw it -
/// the caption mixes Latin ("noun", "7 strokes") with Japanese (音, 訓 and
/// the readings), and no single font in the app covers both.
class CaptionSegment {
  final String text;
  final bool isJapanese;

  const CaptionSegment(this.text, {this.isJapanese = false});
}

/// The caption under the gloss: word class always, plus stroke count and
/// on/kun readings when the headword is a single kanji. A compound or a
/// kana word has neither, so it keeps the plain word-class caption rather
/// than describing one arbitrary character of itself.
List<CaptionSegment> captionFor(JapaneseWord word) {
  final segments = <CaptionSegment>[CaptionSegment(word.partOfSpeech)];
  void add(String japanese) {
    segments.add(const CaptionSegment(' · '));
    segments.add(CaptionSegment(japanese, isJapanese: true));
  }

  if (word.onReading != null) add('音 ${word.onReading}');
  if (word.kunReading != null) add('訓 ${word.kunReading}');
  if (word.strokeCount != null) {
    segments.add(CaptionSegment(' · ${word.strokeCount} strokes'));
  }
  return segments;
}

/// The oversized, near-transparent duplicate of the headword that slowly
/// scales/drifts/fades behind it - the card's cultural treatment. A looping
/// [AnimationController] rather than an implicit animation since it must
/// run continuously, independent of word changes. Respects the platform's
/// reduced-motion setting by holding at the low (resting) opacity instead
/// of animating.
class BreathingEcho extends StatefulWidget {
  final String text;
  final double fontSize;
  final Color color;
  final double opacityLow;
  final double opacityHigh;

  const BreathingEcho({
    super.key,
    required this.text,
    required this.fontSize,
    required this.color,
    required this.opacityLow,
    required this.opacityHigh,
  });

  @override
  State<BreathingEcho> createState() => _BreathingEchoState();
}

class _BreathingEchoState extends State<BreathingEcho> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final bool _reducedMotion;

  @override
  void initState() {
    super.initState();
    // Checked once, outside build(): a running Ticker keeps scheduling
    // frames even if nothing reads its value, so pumpAndSettle-style "wait
    // until idle" logic (tests, but conceivably other tooling) would hang
    // forever if .repeat() started regardless and build() merely chose not
    // to display it.
    _reducedMotion = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 6));
    if (!_reducedMotion) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glyph = Text(
      widget.text,
      style: jpFont(fontSize: widget.fontSize, fontWeight: FontWeight.w900, color: widget.color),
      maxLines: 1,
      softWrap: false,
    );

    if (_reducedMotion) {
      return Opacity(opacity: widget.opacityLow, child: glyph);
    }

    return AnimatedBuilder(
      animation: _controller,
      child: glyph,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        final scale = 1.0 + 0.05 * t;
        final opacity = widget.opacityLow + (widget.opacityHigh - widget.opacityLow) * t;
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, -widget.fontSize * 0.02 * t),
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
    );
  }
}

/// Top-right level rail: a gold-bordered box with "J", "L", "P", "T"
/// stacked above the level's Japanese numeral (N5 → 五).
class JlptRail extends StatelessWidget {
  final DashboardColors dashboard;
  final int level;

  const JlptRail({super.key, required this.dashboard, required this.level});

  static const _numerals = {1: '一', 2: '二', 3: '三', 4: '四', 5: '五'};

  @override
  Widget build(BuildContext context) {
    final letterStyle = displayFont(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: dashboard.accentGold,
    ).copyWith(height: 1.15);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: dashboard.accentGold, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('J', style: letterStyle),
          Text('L', style: letterStyle),
          Text('P', style: letterStyle),
          Text('T', style: letterStyle),
          const SizedBox(height: 6),
          Container(width: 16, height: 1.5, color: dashboard.accentGold.withValues(alpha: 0.5)),
          const SizedBox(height: 6),
          Text(_numerals[level] ?? '$level', style: brushFont(fontSize: 20, color: dashboard.accentGold)),
        ],
      ),
    );
  }
}

/// A small circular button used for the TTS buttons (word + example
/// sentence) and, with [active]/[icon] set, the learned/favorite toggles -
/// outlined normally, filled solid gold with a contrasting icon when
/// [active] is true.
class CircleGlyphButton extends StatelessWidget {
  final double diameter;
  final double iconSize;
  final Color color;
  final VoidCallback? onTap;
  final IconData icon;
  final bool active;
  final Color? activeIconColor;
  final String? tooltip;

  const CircleGlyphButton({
    super.key,
    required this.diameter,
    required this.iconSize,
    required this.color,
    required this.onTap,
    this.icon = Icons.volume_up,
    this.active = false,
    this.activeIconColor,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: active ? color : Colors.transparent,
      shape: CircleBorder(side: BorderSide(color: color, width: 1.5)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: Icon(icon, size: iconSize, color: active ? (activeIconColor ?? Colors.white) : color),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// The bottom card: the word's example sentence, its kana reading and the
/// English translation, with its own speak button. Callers render this only
/// `if (word.exampleSentence != null)`.
class ExampleCard extends StatelessWidget {
  final JapaneseWord word;
  final DashboardColors dashboard;
  final VoidCallback onSpeak;

  const ExampleCard({
    super.key,
    required this.word,
    required this.dashboard,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final motif = isDark ? CardMotif.dark : CardMotif.light;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 15),
      decoration: BoxDecoration(
        border: Border.all(color: dashboard.accentGold, width: 1.5),
        borderRadius: BorderRadius.circular(10),
        color: dashboard.accentGold.withValues(alpha: motif.exampleBoxOpacity),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EXAMPLE SENTENCE',
                  style: bodyFont(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: dashboard.accentGold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  word.exampleSentence!,
                  style: jpFont(fontSize: 19, fontWeight: FontWeight.w600, color: dashboard.ink),
                ),
                if (word.exampleSentenceKana != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    word.exampleSentenceKana!,
                    style: jpFont(fontSize: 12.5, color: dashboard.subText),
                  ),
                ],
                const SizedBox(height: 3),
                Text(
                  word.exampleSentenceEnglish ?? '',
                  style: bodyFont(fontSize: 14, fontStyle: FontStyle.italic, color: dashboard.subText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CircleGlyphButton(diameter: 30, iconSize: 13, color: dashboard.accentGold, onTap: onSpeak),
        ],
      ),
    );
  }
}

/// The "‹ N / total ›" row at the card's foot.
class Pager extends StatelessWidget {
  final DashboardColors dashboard;
  final int index;
  final int total;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const Pager({
    super.key,
    required this.dashboard,
    required this.index,
    required this.total,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 18, color: dashboard.subText),
          tooltip: 'Previous',
          onPressed: onPrevious,
        ),
        Text(
          '${index + 1} / $total',
          style: bodyFont(
            fontSize: 12,
            color: dashboard.subText,
            letterSpacing: 1,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        IconButton(
          icon: Icon(Icons.arrow_forward_ios, size: 18, color: dashboard.subText),
          tooltip: 'Next',
          onPressed: onNext,
        ),
      ],
    );
  }
}

/// Two stacked ink-wash wave bands along the card's foot (330x150 reference
/// viewBox, stretched horizontally to the real card width).
class WaveFloorPainter extends CustomPainter {
  final Color color;
  final double opacity1;
  final double opacity2;

  WaveFloorPainter({required this.color, required this.opacity1, required this.opacity2});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 330, 1);

    final band1 = Path()
      ..moveTo(-10, 90)
      ..cubicTo(40, 50, 90, 106, 140, 74)
      ..cubicTo(195, 38, 250, 98, 340, 60)
      ..lineTo(340, 150)
      ..lineTo(-10, 150)
      ..close();
    canvas.drawPath(band1, Paint()..color = color.withValues(alpha: opacity1));

    final band2 = Path()
      ..moveTo(-10, 108)
      ..cubicTo(50, 74, 100, 118, 150, 88)
      ..cubicTo(210, 54, 265, 108, 340, 76)
      ..lineTo(340, 150)
      ..lineTo(-10, 150)
      ..close();
    canvas.drawPath(band2, Paint()..color = color.withValues(alpha: opacity2));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant WaveFloorPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.opacity1 != opacity1 ||
      oldDelegate.opacity2 != opacity2;
}
