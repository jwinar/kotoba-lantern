import 'package:flutter/material.dart';

import '../models/japanese_word.dart';
import '../theme/app_theme.dart';

/// Shared visual pieces of the word study card: the breathing-echo hero
/// word, the level rail, the example-sentence card, the pager. Kept as its
/// own file so a second level (N4) can reuse the card wholesale rather than
/// growing a second, slightly different one.

/// Motif tokens for the card's decorative layers - separate from
/// [LanternColors] since these are opacities specific to this card
/// composition, not reusable app-wide tokens.
class CardMotif {
  /// The breathing echo behind the headword, at rest and at full breath.
  final double echoOpacityLow;
  final double echoOpacityHigh;

  /// The thin vertical hairlines down the card's sides.
  final double railOpacity;

  /// The lantern-light pool behind the headword.
  final double glowIntensity;

  /// Tint inside the example-sentence box.
  final double exampleBoxOpacity;

  const CardMotif({
    required this.echoOpacityLow,
    required this.echoOpacityHigh,
    required this.railOpacity,
    required this.glowIntensity,
    required this.exampleBoxOpacity,
  });

  /// Day: the glow has to compete with paper, so it stays faint and the
  /// echo leans darker.
  static const light = CardMotif(
    echoOpacityLow: 0.05,
    echoOpacityHigh: 0.09,
    railOpacity: 0.35,
    glowIntensity: 0.28,
    exampleBoxOpacity: 0.07,
  );

  /// Night: the glow is the point.
  static const dark = CardMotif(
    echoOpacityLow: 0.06,
    echoOpacityHigh: 0.11,
    railOpacity: 0.3,
    glowIntensity: 0.75,
    exampleBoxOpacity: 0.11,
  );
}

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
  final LanternColors lantern;
  final CardMotif motif;
  final VoidCallback onSpeak;
  final bool learned;
  final bool favorite;
  final VoidCallback? onToggleLearned;
  final VoidCallback? onToggleFavorite;

  const HeroContent({
    super.key,
    required this.word,
    required this.lantern,
    required this.motif,
    required this.onSpeak,
    required this.learned,
    required this.favorite,
    required this.onToggleLearned,
    required this.onToggleFavorite,
  });

  static const _heroSizes = {1: 190.0, 2: 132.0, 3: 96.0, 4: 74.0, 5: 62.0};

  static double _glossSize(String english) {
    if (english.length > 64) return 17;
    if (english.length > 34) return 20;
    return 24;
  }

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
                    color: lantern.ink,
                    opacityLow: motif.echoOpacityLow,
                    opacityHigh: motif.echoOpacityHigh,
                  ),
                ),
              ),
              Text(
                word.japanese,
                style: jpFont(
                  fontSize: heroSize,
                  fontWeight: FontWeight.w500,
                  color: lantern.ink,
                ),
                maxLines: 1,
                softWrap: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // The kana reading is the line a learner actually needs; romaji
        // sits under it, smaller and tracked out, as the training wheel it
        // is. No italics anywhere - Zen Kaku ships none, and a synthesized
        // slant on kana looks broken.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            word.kana,
            style: jpFont(
              fontSize: 25,
              fontWeight: FontWeight.w600,
              color: lantern.accent,
            ),
            maxLines: 1,
            softWrap: false,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            word.romaji.toUpperCase(),
            style: labelFont(fontSize: 11, color: lantern.subText),
            maxLines: 1,
            softWrap: false,
          ),
        ),
        const SizedBox(height: 12),
        // Imported glosses are comma-joined synonym lists and run to 240
        // characters at the extreme ("to pin down, to hold down, to press
        // down, …"). Long ones step down a size and clamp to three lines:
        // the leading synonyms carry the meaning, and the example sentence
        // and pager underneath have to stay on screen.
        Text(
          word.english,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: displayFont(
            fontSize: _glossSize(word.english),
            color: lantern.ink,
          ).copyWith(height: 1.2),
        ),
        if (captionFor(word).isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            captionFor(word),
            textAlign: TextAlign.center,
            style: bodyFont(fontSize: 13, color: lantern.subText),
          ),
        ],
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleGlyphButton(
              diameter: 36,
              iconSize: 16,
              color: lantern.accent,
              icon: learned ? Icons.check_circle : Icons.check_circle_outline,
              active: learned,
              activeIconColor: lantern.pageBackground,
              tooltip: learned ? 'Marked as learned' : 'Mark as learned',
              onTap: onToggleLearned,
            ),
            const SizedBox(width: 16),
            CircleGlyphButton(
              diameter: 46,
              iconSize: 19,
              color: lantern.accent,
              glow: true,
              tooltip: 'Hear pronunciation',
              onTap: onSpeak,
            ),
            const SizedBox(width: 16),
            CircleGlyphButton(
              diameter: 36,
              iconSize: 16,
              color: lantern.accent,
              icon: favorite ? Icons.star : Icons.star_border,
              active: favorite,
              activeIconColor: lantern.pageBackground,
              tooltip: favorite ? 'Favorited' : 'Add to favorites',
              onTap: onToggleFavorite,
            ),
          ],
        ),
      ],
    );
  }
}

/// The caption under the gloss: word class always, plus stroke count and
/// on/kun readings when the headword is a single kanji. A compound or a
/// kana word has neither, so it keeps the plain word-class caption rather
/// than describing one arbitrary character of itself.
///
/// Every part is optional, and most of the deck has only the readings: word
/// class is only present where a human wrote it (see
/// [JapaneseWord.partOfSpeech]), so the line degrades to "音 シ · 訓 わたし ·
/// 7 strokes" or disappears entirely rather than showing a guess.
///
/// One string, not tagged segments: Zen Kaku Gothic New covers Latin and
/// Japanese in a single face, so "pronoun · 音 シ · 訓 わたし · 7 strokes"
/// renders in one style with no fallback gap to design around.
String captionFor(JapaneseWord word) {
  final parts = <String>[if (word.partOfSpeech != null) word.partOfSpeech!];
  if (word.onReading != null) parts.add('音 ${word.onReading}');
  if (word.kunReading != null) parts.add('訓 ${word.kunReading}');
  if (word.strokeCount != null) parts.add('${word.strokeCount} strokes');
  return parts.join(' · ');
}

/// The oversized, near-transparent duplicate of the headword that slowly
/// scales/drifts/fades behind it. A looping [AnimationController] rather
/// than an implicit animation since it must run continuously, independent
/// of word changes. Respects the platform's reduced-motion setting by
/// holding at the low (resting) opacity instead of animating.
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

class _BreathingEchoState extends State<BreathingEcho>
    with SingleTickerProviderStateMixin {
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
    _reducedMotion = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
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
      style: jpFont(
        fontSize: widget.fontSize,
        fontWeight: FontWeight.w700,
        color: widget.color,
      ),
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
        final opacity =
            widget.opacityLow + (widget.opacityHigh - widget.opacityLow) * t;
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

/// Top-right level rail: "N" over the level number in a soft-cornered box.
/// The old JLPT/五 stack was a woodblock device; this is how the exam is
/// actually written on a textbook spine.
class LevelRail extends StatelessWidget {
  final LanternColors lantern;
  final int level;

  const LevelRail({super.key, required this.lantern, required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: lantern.accent.withValues(alpha: 0.7),
          width: 1.4,
        ),
        color: lantern.accent.withValues(alpha: 0.06),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('N', style: labelFont(fontSize: 12, color: lantern.accent)),
          Text(
            '$level',
            style: displayFont(
              fontSize: 20,
              color: lantern.accent,
            ).copyWith(height: 1.05),
          ),
        ],
      ),
    );
  }
}

/// A small circular button used for the TTS buttons (word + example
/// sentence) and, with [active]/[icon] set, the learned/favorite toggles -
/// outlined normally, filled with lantern light when [active]. [glow] adds
/// the same halo the lit lamps carry, for the one primary action.
class CircleGlyphButton extends StatelessWidget {
  final double diameter;
  final double iconSize;
  final Color color;
  final VoidCallback? onTap;
  final IconData icon;
  final bool active;
  final bool glow;
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
    this.glow = false,
    this.activeIconColor,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: glow || active
            ? [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 14)]
            : null,
      ),
      child: Material(
        color: active ? color : Colors.transparent,
        shape: CircleBorder(side: BorderSide(color: color, width: 1.5)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: diameter,
            height: diameter,
            child: Icon(
              icon,
              size: iconSize,
              color: active ? (activeIconColor ?? Colors.white) : color,
            ),
          ),
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
  final LanternColors lantern;
  final CardMotif motif;
  final VoidCallback onSpeak;

  const ExampleCard({
    super.key,
    required this.word,
    required this.lantern,
    required this.motif,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 13, 13, 13),
      decoration: BoxDecoration(
        border: Border.all(
          color: lantern.accent.withValues(alpha: 0.55),
          width: 1.4,
        ),
        borderRadius: BorderRadius.circular(16),
        color: lantern.accent.withValues(alpha: motif.exampleBoxOpacity),
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
                  style: labelFont(fontSize: 9.5, color: lantern.accent),
                ),
                const SizedBox(height: 5),
                Text(
                  word.exampleSentence!,
                  style: jpFont(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: lantern.ink,
                  ),
                ),
                if (word.exampleSentenceKana != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    word.exampleSentenceKana!,
                    style: jpFont(fontSize: 12, color: lantern.subText),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  word.exampleSentenceEnglish ?? '',
                  style: bodyFont(fontSize: 13.5, color: lantern.subText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CircleGlyphButton(
            diameter: 32,
            iconSize: 14,
            color: lantern.accent,
            onTap: onSpeak,
          ),
        ],
      ),
    );
  }
}

/// The "‹ N / total ›" row at the card's foot.
class Pager extends StatelessWidget {
  final LanternColors lantern;
  final int index;
  final int total;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const Pager({
    super.key,
    required this.lantern,
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
          icon: Icon(Icons.arrow_back_ios, size: 18, color: lantern.subText),
          tooltip: 'Previous',
          onPressed: onPrevious,
        ),
        Text(
          '${index + 1} / $total',
          style: labelFont(
            fontSize: 12,
            color: lantern.subText,
            fontWeight: FontWeight.w500,
          ),
        ),
        IconButton(
          icon: Icon(Icons.arrow_forward_ios, size: 18, color: lantern.subText),
          tooltip: 'Next',
          onPressed: onNext,
        ),
      ],
    );
  }
}
