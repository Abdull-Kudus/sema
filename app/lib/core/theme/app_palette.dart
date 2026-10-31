import 'package:flutter/material.dart';

/// Raw colour values for Sema. This is the only file allowed to contain hex
/// codes; everything else reads colours through [SemaColors] or the
/// [ColorScheme].
///
/// The brand colour is "Jacaranda", after the violet trees that line Kigali's
/// streets in bloom season.
abstract final class AppPalette {
  // Brand
  static const jacaranda = Color(0xFF5B3FE4);
  static const jacarandaDeep = Color(0xFF3A22B8);
  static const jacarandaBright = Color(0xFF8C73FF);
  static const jacarandaMist = Color(0xFFEFEBFF);
  static const jacarandaNight = Color(0xFF1E1638);

  // Neutrals (light)
  static const white = Color(0xFFFFFFFF);
  static const snow = Color(0xFFF6F5FA);
  static const cloud = Color(0xFFE9E7F1);
  static const ink = Color(0xFF0E0D14);
  static const slate = Color(0xFF6B6880);

  // Neutrals (dark)
  static const black = Color(0xFF000000);
  static const onyx = Color(0xFF0C0B10);
  static const graphite = Color(0xFF17161D);
  static const smoke = Color(0xFF26242F);
  static const ash = Color(0xFF9E9BB0);

  // Signals
  static const amber = Color(0xFFB7791F);
  static const amberMist = Color(0xFFFFF4DE);
  static const sky = Color(0xFF2563EB);
  static const skyMist = Color(0xFFE6EEFF);
  static const violet = Color(0xFF7C3AED);
  static const violetMist = Color(0xFFF1E9FF);
  static const emerald = Color(0xFF15803D);
  static const emeraldMist = Color(0xFFE3F7EA);
  static const crimson = Color(0xFFDC2626);
  static const crimsonMist = Color(0xFFFDE8E8);
  static const teal = Color(0xFF0F8B8D);
  static const tealMist = Color(0xFFE0F5F5);
  static const orange = Color(0xFFEA580C);
  static const orangeMist = Color(0xFFFFEDE2);
  static const pink = Color(0xFFDB2777);
  static const pinkMist = Color(0xFFFDE7F1);
}
