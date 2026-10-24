import 'package:flutter/material.dart';

/// Colours taken from the web app (css/style.css), so the two feel like one
/// product: deep emerald, warm parchment, antique gold.
abstract final class Brand {
  static const emerald900 = Color(0xFF064E3B);
  static const emerald800 = Color(0xFF065F46);
  static const emerald700 = Color(0xFF047857);
  static const emerald600 = Color(0xFF059669);
  static const emerald500 = Color(0xFF10B981);
  static const emerald400 = Color(0xFF34D399);
  static const emerald50 = Color(0xFFECFDF5);

  static const gold500 = Color(0xFFD4A21A);
  static const gold400 = Color(0xFFEAB932);
  static const gold300 = Color(0xFFF7D56B);

  static const displayFont = 'PlayfairDisplay';
  static const arabicFont = 'Amiri';
}

/// Colours with a job ("the page", "a selected card") rather than a hue, so
/// screens look right in both light and dark mode without checking which one
/// is on.
@immutable
class VegukinPalette extends ThemeExtension<VegukinPalette> {
  const VegukinPalette({
    required this.page,
    required this.card,
    required this.cardSelected,
    required this.hairline,
    required this.hairlineStrong,
    required this.ink,
    required this.inkSoft,
    required this.inkMuted,
    required this.accent,
    required this.action,
    required this.badge,
    required this.gold,
    required this.goldSoft,
    required this.hero,
  });

  final Color page;
  final Color card;
  final Color cardSelected;
  final Color hairline;
  final Color hairlineStrong;
  final Color ink;
  final Color inkSoft;
  final Color inkMuted;

  /// Emerald for text, borders and checks.
  final Color accent;

  /// Fill of the main button.
  final Color action;

  /// Background of the small letter tile on a language option.
  final Color badge;
  final Color gold;
  final Color goldSoft;

  /// The emerald gradient behind the welcome header, top-left to bottom-right.
  final List<Color> hero;

  static const light = VegukinPalette(
    page: Color(0xFFF9F7F4),
    card: Color(0xFFFFFFFF),
    cardSelected: Brand.emerald50,
    hairline: Color(0xFFE8E3DB),
    hairlineStrong: Color(0xFFDBD4C9),
    ink: Color(0xFF292524),
    inkSoft: Color(0xFF57534E),
    inkMuted: Color(0xFF78716C),
    accent: Brand.emerald700,
    action: Brand.emerald700,
    badge: Color(0xFFF2EEE8),
    gold: Brand.gold500,
    goldSoft: Brand.gold300,
    hero: [Color(0xFF053F31), Brand.emerald800, Brand.emerald700],
  );

  static const dark = VegukinPalette(
    page: Color(0xFF141210),
    card: Color(0xFF201D1A),
    cardSelected: Color(0xFF13261F),
    hairline: Color(0x17FFFFFF),
    hairlineStrong: Color(0x29FFFFFF),
    ink: Color(0xFFE6E1DB),
    inkSoft: Color(0xFFA49D95),
    inkMuted: Color(0xFF7D766E),
    accent: Brand.emerald400,
    action: Brand.emerald600,
    badge: Color(0xFF2A2623),
    gold: Brand.gold400,
    goldSoft: Brand.gold300,
    hero: [Color(0xFF02261D), Color(0xFF053F31), Brand.emerald900],
  );

  static VegukinPalette of(BuildContext context) =>
      Theme.of(context).extension<VegukinPalette>()!;

  @override
  VegukinPalette copyWith() => this;

  @override
  VegukinPalette lerp(VegukinPalette? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return VegukinPalette(
      page: mix(page, other.page),
      card: mix(card, other.card),
      cardSelected: mix(cardSelected, other.cardSelected),
      hairline: mix(hairline, other.hairline),
      hairlineStrong: mix(hairlineStrong, other.hairlineStrong),
      ink: mix(ink, other.ink),
      inkSoft: mix(inkSoft, other.inkSoft),
      inkMuted: mix(inkMuted, other.inkMuted),
      accent: mix(accent, other.accent),
      action: mix(action, other.action),
      badge: mix(badge, other.badge),
      gold: mix(gold, other.gold),
      goldSoft: mix(goldSoft, other.goldSoft),
      hero: List.generate(hero.length, (i) => mix(hero[i], other.hero[i])),
    );
  }
}

abstract final class VegukinTheme {
  static ThemeData get light => _build(Brightness.light, VegukinPalette.light);
  static ThemeData get dark => _build(Brightness.dark, VegukinPalette.dark);

  static ThemeData _build(Brightness brightness, VegukinPalette p) {
    final scheme = ColorScheme.fromSeed(
      seedColor: Brand.emerald700,
      brightness: brightness,
    ).copyWith(
      primary: p.action,
      onPrimary: Colors.white,
      surface: p.page,
      onSurface: p.ink,
      outline: p.hairlineStrong,
      outlineVariant: p.hairline,
    );

    final base = ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: p.page,
      extensions: [p],
    );

    TextStyle display(TextStyle? style) => (style ?? const TextStyle()).copyWith(
          fontFamily: Brand.displayFont,
          fontWeight: FontWeight.w600,
          color: p.ink,
          letterSpacing: 0,
        );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineMedium: display(base.textTheme.headlineMedium),
        headlineSmall: display(base.textTheme.headlineSmall).copyWith(
          fontSize: 25,
          height: 1.2,
        ),
        titleLarge: display(base.textTheme.titleLarge),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.action,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          // From the theme rather than a bare TextStyle: a button's text
          // style replaces the inherited one, font family included.
          textStyle: base.textTheme.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
