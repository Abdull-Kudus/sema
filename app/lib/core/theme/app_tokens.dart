import 'package:flutter/widgets.dart';

/// Spacing follows an 8pt rhythm with 4pt half-steps.
abstract final class Space {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;

  /// Horizontal page gutter.
  static const gutter = 20.0;
}

abstract final class Radii {
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const pill = 999.0;

  static const card = BorderRadius.all(Radius.circular(md));
  static const panel = BorderRadius.all(Radius.circular(lg));
  static const field = BorderRadius.all(Radius.circular(14));
}

abstract final class Motion {
  static const fast = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 600);
  static const counter = Duration(milliseconds: 1100);
  static const stagger = Duration(milliseconds: 60);

  /// One full lap of the welcome-screen orbit: slow enough to stay calm.
  static const orbit = Duration(seconds: 30);
}
