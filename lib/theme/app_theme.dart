import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kotoba Lantern brand accent - gold, used for readings and highlights on
/// the plain list screens.
const Color kotobaGold = Color(0xFFD4A72C);

/// Color tokens for the dashboard-style home screen and the study card.
/// The hero panel is always a dark "ink" surface regardless of the app's
/// light/dark mode, so it needs its own token set rather than reusing the
/// Material [ColorScheme].
@immutable
class DashboardColors extends ThemeExtension<DashboardColors> {
  final Color pageBackground;
  final Color heroPanel;
  final Color ink;
  final Color subText;
  final Color accentGold;
  final Color hairline;
  final Color heroText;

  const DashboardColors({
    required this.pageBackground,
    required this.heroPanel,
    required this.ink,
    required this.subText,
    required this.accentGold,
    required this.hairline,
    required this.heroText,
  });

  static const light = DashboardColors(
    pageBackground: Color(0xFFF7F3EA),
    heroPanel: Color(0xFF2A2317),
    ink: Color(0xFF2A251C),
    subText: Color(0xFF8B8173),
    accentGold: Color(0xFFC09437),
    hairline: Color(0x1F2A251C),
    heroText: Color(0xFFF7F3EA),
  );

  static const dark = DashboardColors(
    pageBackground: Color(0xFF141109),
    heroPanel: Color(0xFF211A10),
    ink: Color(0xFFECE4D4),
    subText: Color(0xFF9A9082),
    accentGold: Color(0xFFD9B25C),
    hairline: Color(0x23ECE4D4),
    heroText: Color(0xFFF7F3EA),
  );

  @override
  DashboardColors copyWith({
    Color? pageBackground,
    Color? heroPanel,
    Color? ink,
    Color? subText,
    Color? accentGold,
    Color? hairline,
    Color? heroText,
  }) {
    return DashboardColors(
      pageBackground: pageBackground ?? this.pageBackground,
      heroPanel: heroPanel ?? this.heroPanel,
      ink: ink ?? this.ink,
      subText: subText ?? this.subText,
      accentGold: accentGold ?? this.accentGold,
      hairline: hairline ?? this.hairline,
      heroText: heroText ?? this.heroText,
    );
  }

  @override
  DashboardColors lerp(ThemeExtension<DashboardColors>? other, double t) {
    if (other is! DashboardColors) return this;
    return DashboardColors(
      pageBackground: Color.lerp(pageBackground, other.pageBackground, t)!,
      heroPanel: Color.lerp(heroPanel, other.heroPanel, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      subText: Color.lerp(subText, other.subText, t)!,
      accentGold: Color.lerp(accentGold, other.accentGold, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      heroText: Color.lerp(heroText, other.heroText, t)!,
    );
  }
}

/// Display/numeral font (hero numerals, headings) - Cormorant Garamond.
TextStyle displayFont({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  List<FontFeature>? fontFeatures,
}) => GoogleFonts.cormorantGaramond(
  fontSize: fontSize,
  fontWeight: fontWeight,
  color: color,
  fontFeatures: fontFeatures,
);

/// Body font - Lora.
TextStyle bodyFont({
  double? fontSize,
  FontWeight? fontWeight,
  FontStyle? fontStyle,
  Color? color,
  double? letterSpacing,
  List<FontFeature>? fontFeatures,
}) => GoogleFonts.lora(
  fontSize: fontSize,
  fontWeight: fontWeight,
  fontStyle: fontStyle,
  color: color,
  letterSpacing: letterSpacing,
  fontFeatures: fontFeatures,
);

/// Japanese text font - Noto Serif JP. Covers kanji, hiragana and katakana
/// with the same serif (明朝) weight the rest of the type is set in.
TextStyle jpFont({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? letterSpacing,
}) => GoogleFonts.notoSerifJp(
  fontSize: fontSize,
  fontWeight: fontWeight,
  color: color,
  letterSpacing: letterSpacing,
);

/// Brush accent font - Yuji Syuku, a hand-brushed Japanese face. Used for
/// the brand seal and the proverb line in the hero, nothing else: it is a
/// display face and unreadable at body sizes.
TextStyle brushFont({double? fontSize, Color? color}) =>
    GoogleFonts.yujiSyuku(fontSize: fontSize, color: color);

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
  static ThemeData get light => _build(Brightness.light, DashboardColors.light);

  static ThemeData get dark => _build(Brightness.dark, DashboardColors.dark);

  static ThemeData _build(Brightness brightness, DashboardColors dashboard) {
    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      scaffoldBackgroundColor: dashboard.pageBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kotobaGold,
        brightness: brightness,
      ),
    );
    return base.copyWith(extensions: [dashboard]);
  }
}
