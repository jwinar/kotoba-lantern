import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kotoba Lantern's "Chōchin" identity - a night ground, a paper lantern
/// that fills with light as the deck is learned, and gothic type.
///
/// The palette is deliberately dark-first: this is an app people open in
/// the evening, and the lantern metaphor only works against a night. The
/// light theme is a *day* version of the same idea (paper lantern seen in
/// daylight), not an inversion of these values - see [LanternColors.light].
@immutable
class LanternColors extends ThemeExtension<LanternColors> {
  /// The page ground.
  final Color pageBackground;

  /// Top and bottom of the hero panel's vertical gradient. The panel stays
  /// dark in both themes: the lantern needs a night to glow against.
  final Color heroPanelTop;
  final Color heroPanelBottom;

  /// Body text on [pageBackground].
  final Color ink;

  /// Secondary text.
  final Color subText;

  /// Lantern light - the app's single accent. There is no second accent
  /// and no gold anywhere; everything that needs emphasis borrows this.
  final Color accent;

  /// Hairline rules and inactive borders.
  final Color hairline;

  /// Text on the hero panel, which is dark in both themes.
  final Color heroText;

  const LanternColors({
    required this.pageBackground,
    required this.heroPanelTop,
    required this.heroPanelBottom,
    required this.ink,
    required this.subText,
    required this.accent,
    required this.hairline,
    required this.heroText,
  });

  /// Night. The default, and the one the design is drawn for.
  static const dark = LanternColors(
    pageBackground: Color(0xFF14100F),
    heroPanelTop: Color(0xFF2C1D22),
    heroPanelBottom: Color(0xFF14100F),
    ink: Color(0xFFF1EADC),
    subText: Color(0xFF97897C),
    accent: Color(0xFFE4762E),
    hairline: Color(0x29F1EADC),
    heroText: Color(0xFFF6F1E4),
  );

  /// Day. Warm paper ground, but the hero panel stays a deep plum and the
  /// accent darkens to hold contrast on paper (#B85418 clears 4.5:1 on
  /// #F6F1E4; the night accent would not).
  static const light = LanternColors(
    pageBackground: Color(0xFFF6F1E4),
    heroPanelTop: Color(0xFF2C1D22),
    heroPanelBottom: Color(0xFF1A1315),
    ink: Color(0xFF23201C),
    subText: Color(0xFF7A6E63),
    accent: Color(0xFFB85418),
    hairline: Color(0x2423201C),
    heroText: Color(0xFFF6F1E4),
  );

  /// The accent as it appears *on the hero panel*, which is dark in both
  /// themes - so the light theme's darkened accent would disappear there.
  Color get accentOnHero => dark.accent;

  @override
  LanternColors copyWith({
    Color? pageBackground,
    Color? heroPanelTop,
    Color? heroPanelBottom,
    Color? ink,
    Color? subText,
    Color? accent,
    Color? hairline,
    Color? heroText,
  }) {
    return LanternColors(
      pageBackground: pageBackground ?? this.pageBackground,
      heroPanelTop: heroPanelTop ?? this.heroPanelTop,
      heroPanelBottom: heroPanelBottom ?? this.heroPanelBottom,
      ink: ink ?? this.ink,
      subText: subText ?? this.subText,
      accent: accent ?? this.accent,
      hairline: hairline ?? this.hairline,
      heroText: heroText ?? this.heroText,
    );
  }

  @override
  LanternColors lerp(ThemeExtension<LanternColors>? other, double t) {
    if (other is! LanternColors) return this;
    return LanternColors(
      pageBackground: Color.lerp(pageBackground, other.pageBackground, t)!,
      heroPanelTop: Color.lerp(heroPanelTop, other.heroPanelTop, t)!,
      heroPanelBottom: Color.lerp(heroPanelBottom, other.heroPanelBottom, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      subText: Color.lerp(subText, other.subText, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      heroText: Color.lerp(heroText, other.heroText, t)!,
    );
  }
}

/// Zen Kaku Gothic New, used for every role in the app - Japanese and
/// Latin alike.
///
/// One family everywhere is the point of this direction: the serif pairing
/// the app started with (Cormorant/Lora/Noto Serif) read as a museum label,
/// and dropping it is what makes this look like something made in 2026.
/// Zen Kaku carries kanji, kana and Latin in one voice, so a caption that
/// mixes "pronoun" with 訓 わたし no longer needs two faces to render one
/// line.
///
/// It ships no italic. Nothing in the app asks for one: emphasis is done
/// with weight, tracking and the accent instead of a synthesized slant.
TextStyle _zen({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? letterSpacing,
  List<FontFeature>? fontFeatures,
  double? height,
}) => GoogleFonts.zenKakuGothicNew(
  fontSize: fontSize,
  fontWeight: fontWeight,
  color: color,
  letterSpacing: letterSpacing,
  fontFeatures: fontFeatures,
  height: height,
);

/// Display role - headings and the big numerals in the lantern. Digits are
/// tabular by default so a count doesn't jitter as it climbs.
TextStyle displayFont({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? letterSpacing,
  List<FontFeature>? fontFeatures,
}) => _zen(
  fontSize: fontSize,
  fontWeight: fontWeight ?? FontWeight.w600,
  color: color,
  letterSpacing: letterSpacing ?? -0.2,
  fontFeatures: fontFeatures ?? const [FontFeature.tabularFigures()],
);

/// Body/UI role.
TextStyle bodyFont({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? letterSpacing,
  List<FontFeature>? fontFeatures,
}) => _zen(
  fontSize: fontSize,
  fontWeight: fontWeight,
  color: color,
  letterSpacing: letterSpacing,
  fontFeatures: fontFeatures,
);

/// Japanese text. Same family - kept as its own function because the call
/// sites mean something by it, and a future direction may split the two
/// again.
TextStyle jpFont({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? letterSpacing,
}) => _zen(
  fontSize: fontSize,
  fontWeight: fontWeight,
  color: color,
  letterSpacing: letterSpacing,
);

/// Small tracked-out label ("OF 150", "EXAMPLE SENTENCE"). The one place
/// the type system leans on letter-spacing rather than weight.
TextStyle labelFont({double? fontSize, Color? color, FontWeight? fontWeight}) => _zen(
  fontSize: fontSize,
  fontWeight: fontWeight ?? FontWeight.w600,
  color: color,
  letterSpacing: 1.4,
);

/// Formats an integer with thousands separators (`10057` → `10,057`).
/// Small enough not to warrant pulling in `intl` for.
String formatThousands(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

class AppTheme {
  static ThemeData get light => _build(Brightness.light, LanternColors.light);

  static ThemeData get dark => _build(Brightness.dark, LanternColors.dark);

  static ThemeData _build(Brightness brightness, LanternColors lantern) {
    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      scaffoldBackgroundColor: lantern.pageBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: LanternColors.dark.accent,
        brightness: brightness,
      ),
    );
    return base.copyWith(
      extensions: [lantern],
      textTheme: GoogleFonts.zenKakuGothicNewTextTheme(base.textTheme),
    );
  }
}
