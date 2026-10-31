import 'package:flutter/material.dart';

import 'app_palette.dart';

/// A foreground/background pair used for chips, badges and icon circles.
@immutable
class Tone {
  const Tone(this.fg, this.bg);

  final Color fg;
  final Color bg;

  static Tone lerp(Tone a, Tone b, double t) => Tone(Color.lerp(a.fg, b.fg, t)!, Color.lerp(a.bg, b.bg, t)!);
}

/// Semantic colours for Sema surfaces, read with `context.colors`.
@immutable
class SemaColors extends ThemeExtension<SemaColors> {
  const SemaColors({
    required this.page,
    required this.panel,
    required this.card,
    required this.line,
    required this.text,
    required this.muted,
    required this.brand,
    required this.brandDeep,
    required this.brandSoft,
    required this.onBrand,
    required this.heroStart,
    required this.heroEnd,
    required this.amber,
    required this.sky,
    required this.violet,
    required this.emerald,
    required this.crimson,
    required this.teal,
    required this.orange,
    required this.pink,
    required this.skeleton,
  });

  final Color page;
  final Color panel;
  final Color card;
  final Color line;
  final Color text;
  final Color muted;
  final Color brand;
  final Color brandDeep;
  final Color brandSoft;
  final Color onBrand;
  final Color heroStart;
  final Color heroEnd;
  final Tone amber;
  final Tone sky;
  final Tone violet;
  final Tone emerald;
  final Tone crimson;
  final Tone teal;
  final Tone orange;
  final Tone pink;
  final Color skeleton;

  LinearGradient get hero =>
      LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [heroStart, heroEnd]);

  static const light = SemaColors(
    page: AppPalette.white,
    panel: AppPalette.snow,
    card: AppPalette.white,
    line: AppPalette.cloud,
    text: AppPalette.ink,
    muted: AppPalette.slate,
    brand: AppPalette.jacaranda,
    brandDeep: AppPalette.jacarandaDeep,
    brandSoft: AppPalette.jacarandaMist,
    onBrand: AppPalette.white,
    heroStart: AppPalette.jacarandaBright,
    heroEnd: AppPalette.jacarandaDeep,
    amber: Tone(AppPalette.amber, AppPalette.amberMist),
    sky: Tone(AppPalette.sky, AppPalette.skyMist),
    violet: Tone(AppPalette.violet, AppPalette.violetMist),
    emerald: Tone(AppPalette.emerald, AppPalette.emeraldMist),
    crimson: Tone(AppPalette.crimson, AppPalette.crimsonMist),
    teal: Tone(AppPalette.teal, AppPalette.tealMist),
    orange: Tone(AppPalette.orange, AppPalette.orangeMist),
    pink: Tone(AppPalette.pink, AppPalette.pinkMist),
    skeleton: AppPalette.cloud,
  );

  static final dark = SemaColors(
    page: AppPalette.black,
    panel: AppPalette.onyx,
    card: AppPalette.graphite,
    line: AppPalette.smoke,
    text: AppPalette.white,
    muted: AppPalette.ash,
    brand: AppPalette.jacarandaBright,
    brandDeep: AppPalette.jacaranda,
    brandSoft: AppPalette.jacarandaNight,
    onBrand: AppPalette.white,
    heroStart: AppPalette.jacaranda,
    heroEnd: AppPalette.jacarandaNight,
    amber: Tone(AppPalette.amberMist, AppPalette.amber.withValues(alpha: 0.22)),
    sky: Tone(AppPalette.skyMist, AppPalette.sky.withValues(alpha: 0.24)),
    violet: Tone(AppPalette.violetMist, AppPalette.violet.withValues(alpha: 0.26)),
    emerald: Tone(AppPalette.emeraldMist, AppPalette.emerald.withValues(alpha: 0.26)),
    crimson: Tone(AppPalette.crimsonMist, AppPalette.crimson.withValues(alpha: 0.24)),
    teal: Tone(AppPalette.tealMist, AppPalette.teal.withValues(alpha: 0.26)),
    orange: Tone(AppPalette.orangeMist, AppPalette.orange.withValues(alpha: 0.24)),
    pink: Tone(AppPalette.pinkMist, AppPalette.pink.withValues(alpha: 0.24)),
    skeleton: AppPalette.smoke,
  );

  @override
  SemaColors copyWith() => this;

  @override
  SemaColors lerp(covariant SemaColors? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return SemaColors(
      page: c(page, other.page),
      panel: c(panel, other.panel),
      card: c(card, other.card),
      line: c(line, other.line),
      text: c(text, other.text),
      muted: c(muted, other.muted),
      brand: c(brand, other.brand),
      brandDeep: c(brandDeep, other.brandDeep),
      brandSoft: c(brandSoft, other.brandSoft),
      onBrand: c(onBrand, other.onBrand),
      heroStart: c(heroStart, other.heroStart),
      heroEnd: c(heroEnd, other.heroEnd),
      amber: Tone.lerp(amber, other.amber, t),
      sky: Tone.lerp(sky, other.sky, t),
      violet: Tone.lerp(violet, other.violet, t),
      emerald: Tone.lerp(emerald, other.emerald, t),
      crimson: Tone.lerp(crimson, other.crimson, t),
      teal: Tone.lerp(teal, other.teal, t),
      orange: Tone.lerp(orange, other.orange, t),
      pink: Tone.lerp(pink, other.pink, t),
      skeleton: c(skeleton, other.skeleton),
    );
  }
}

extension SemaThemeX on BuildContext {
  SemaColors get colors => Theme.of(this).extension<SemaColors>()!;
  TextTheme get text => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
