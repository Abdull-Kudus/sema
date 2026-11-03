import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sema/core/theme/sema_colors.dart';

/// WCAG contrast ratio between two opaque colours.
double _ratio(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Every text colour must reach WCAG AA (4.5:1) on the surface it sits on,
/// in both themes. Pill backgrounds are translucent in dark mode, so they are
/// blended over the card colour first.
void main() {
  for (final (name, c) in [('light', SemaColors.light), ('dark', SemaColors.dark)]) {
    group('$name theme', () {
      test('body and muted text on page, panel and card', () {
        for (final surface in [c.page, c.panel, c.card]) {
          expect(_ratio(c.text, surface), greaterThanOrEqualTo(4.5));
          expect(_ratio(c.muted, surface), greaterThanOrEqualTo(4.5));
        }
      });

      test('brand text and text on brand', () {
        for (final surface in [c.page, c.panel, c.card]) {
          expect(_ratio(c.brandText, surface), greaterThanOrEqualTo(4.5));
        }
        expect(_ratio(c.onBrand, c.brand), greaterThanOrEqualTo(4.5));
        expect(_ratio(c.onBrand, c.heroEnd), greaterThanOrEqualTo(4.5));
      });

      final tones = {
        'azure': c.azure,
        'amber': c.amber,
        'sky': c.sky,
        'emerald': c.emerald,
        'crimson': c.crimson,
        'lime': c.lime,
        'orange': c.orange,
        'pink': c.pink,
      };
      for (final MapEntry(key: tone, value: t) in tones.entries) {
        test('$tone pill text', () {
          final bg = Color.alphaBlend(t.bg, c.card);
          expect(_ratio(t.fg, bg), greaterThanOrEqualTo(4.5), reason: '$tone in $name');
        });
      }
    });
  }
}
