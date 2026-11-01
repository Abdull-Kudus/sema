import 'package:flutter/material.dart';

/// Raw colour values for Sema. This is the only file allowed to contain hex
/// codes; everything else reads colours through [SemaColors] or the
/// [ColorScheme].
///
/// The brand colour is Azure (#0067FF).
abstract final class AppPalette {
  // Brand
  static const azure = Color(0xFF0067FF);
  static const azureDeep = Color(0xFF0047B3);
  static const azureBright = Color(0xFF4D94FF);
  static const azureMist = Color(0xFFE6F0FF);
  static const azureNight = Color(0xFF001A40);

  // Neutrals (light), cool grey to sit with the azure
  static const white = Color(0xFFFFFFFF);
  static const snow = Color(0xFFF5F7FA);
  static const cloud = Color(0xFFE6EAF0);
  static const ink = Color(0xFF0B0F17);
  static const slate = Color(0xFF64708A);

  // Neutrals (dark)
  static const black = Color(0xFF000000);
  static const onyx = Color(0xFF0A0C10);
  static const graphite = Color(0xFF15181E);
  static const smoke = Color(0xFF252A33);
  static const ash = Color(0xFF98A2B3);

  // Signals
  static const amber = Color(0xFFB7791F);
  static const amberMist = Color(0xFFFFF4DE);
  // Cyan rather than blue so it never reads as the brand colour.
  static const sky = Color(0xFF0891B2);
  static const skyMist = Color(0xFFE0F5FA);
  static const emerald = Color(0xFF15803D);
  static const emeraldMist = Color(0xFFE3F7EA);
  static const crimson = Color(0xFFDC2626);
  static const crimsonMist = Color(0xFFFDE8E8);
  static const lime = Color(0xFF4D7C0F);
  static const limeMist = Color(0xFFECF7D9);
  static const orange = Color(0xFFEA580C);
  static const orangeMist = Color(0xFFFFEDE2);
  static const pink = Color(0xFFDB2777);
  static const pinkMist = Color(0xFFFDE7F1);
}
