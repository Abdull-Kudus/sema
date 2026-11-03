import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_tokens.dart';
import 'sema_colors.dart';

abstract final class AppTheme {
  static const fontFamily = 'ClashGrotesk';

  static ThemeData light() => _build(SemaColors.light, Brightness.light);
  static ThemeData dark() => _build(SemaColors.dark, Brightness.dark);

  static ThemeData _build(SemaColors c, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: c.brand, brightness: brightness).copyWith(
      primary: c.brand,
      onPrimary: c.onBrand,
      primaryContainer: c.brandSoft,
      onPrimaryContainer: c.brandDeep,
      surface: c.page,
      onSurface: c.text,
      onSurfaceVariant: c.muted,
      surfaceContainerLowest: c.card,
      surfaceContainerLow: c.panel,
      surfaceContainer: c.panel,
      outline: c.line,
      outlineVariant: c.line,
      error: c.crimson.fg,
    );

    final text = _textTheme(c);
    final fieldBorder = OutlineInputBorder(
      borderRadius: Radii.field,
      borderSide: BorderSide(color: c.line),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
      textTheme: text,
      scaffoldBackgroundColor: c.page,
      extensions: [c],
      // Flat design: plain ripples and no shadows anywhere, so surfaces are
      // separated by borders and colour, never by elevation.
      splashFactory: InkRipple.splashFactory,
      shadowColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: c.page,
        foregroundColor: c.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: text.titleMedium,
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: c.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.card,
          side: BorderSide(color: c.line),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.panel,
        hintStyle: text.bodyMedium?.copyWith(color: c.muted),
        labelStyle: text.bodyMedium?.copyWith(color: c.muted),
        contentPadding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: 16),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(borderSide: BorderSide(color: c.brand, width: 1.6)),
        errorBorder: fieldBorder.copyWith(borderSide: BorderSide(color: c.crimson.fg)),
        focusedErrorBorder: fieldBorder.copyWith(borderSide: BorderSide(color: c.crimson.fg, width: 1.6)),
        prefixIconColor: c.muted,
        suffixIconColor: c.muted,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.brand,
          foregroundColor: c.onBrand,
          minimumSize: const Size.fromHeight(54),
          textStyle: text.titleSmall,
          shape: const RoundedRectangleBorder(borderRadius: Radii.card),
        ).copyWith(elevation: _flat),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.text,
          minimumSize: const Size.fromHeight(54),
          side: BorderSide(color: c.line),
          textStyle: text.titleSmall,
          shape: const RoundedRectangleBorder(borderRadius: Radii.card),
        ).copyWith(elevation: _flat),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.brandText,
          textStyle: text.labelLarge,
        ).copyWith(elevation: _flat),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.panel,
        selectedColor: c.brand,
        side: BorderSide(color: c.line),
        labelStyle: text.labelMedium,
        secondaryLabelStyle: text.labelMedium?.copyWith(color: c.onBrand),
        shape: const StadiumBorder(),
        showCheckmark: false,
        elevation: 0,
        pressElevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: Space.xs, vertical: 6),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: c.panel,
          selectedBackgroundColor: c.brand,
          selectedForegroundColor: c.onBrand,
          foregroundColor: c.text,
          side: BorderSide(color: c.line),
          textStyle: text.labelLarge,
        ).copyWith(elevation: _flat),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: c.line,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: Radii.panel),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium?.copyWith(color: c.muted),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.text,
        elevation: 0,
        contentTextStyle: text.bodyMedium?.copyWith(color: c.page),
        shape: const RoundedRectangleBorder(borderRadius: Radii.card),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        textStyle: text.bodyLarge,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.card,
          side: BorderSide(color: c.line),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: c.text, borderRadius: BorderRadius.circular(Radii.sm)),
        textStyle: text.bodySmall?.copyWith(color: c.page),
      ),
      switchTheme: SwitchThemeData(trackOutlineColor: WidgetStatePropertyAll(c.line)),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.brand, linearTrackColor: c.brandSoft),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static const _flat = WidgetStatePropertyAll<double>(0);

  static TextTheme _textTheme(SemaColors c) {
    TextStyle s(double size, FontWeight weight, {double height = 1.3, double spacing = 0, Color? color}) =>
        TextStyle(
          fontFamily: fontFamily,
          fontSize: size,
          fontWeight: weight,
          height: height,
          letterSpacing: spacing,
          color: color ?? c.text,
        );

    return TextTheme(
      displayLarge: s(44, FontWeight.w600, height: 1.05, spacing: -1.2),
      displayMedium: s(36, FontWeight.w600, height: 1.08, spacing: -0.9),
      displaySmall: s(30, FontWeight.w600, height: 1.1, spacing: -0.6),
      headlineLarge: s(28, FontWeight.w600, height: 1.15, spacing: -0.5),
      headlineMedium: s(24, FontWeight.w600, height: 1.2, spacing: -0.4),
      headlineSmall: s(20, FontWeight.w600, height: 1.25, spacing: -0.2),
      titleLarge: s(18, FontWeight.w600, height: 1.3),
      titleMedium: s(16, FontWeight.w600, height: 1.3),
      titleSmall: s(15, FontWeight.w500, height: 1.3),
      bodyLarge: s(16, FontWeight.w400, height: 1.5),
      bodyMedium: s(14, FontWeight.w400, height: 1.5),
      bodySmall: s(12.5, FontWeight.w400, height: 1.45, color: c.muted),
      labelLarge: s(14, FontWeight.w500),
      labelMedium: s(12.5, FontWeight.w500),
      labelSmall: s(11, FontWeight.w500, spacing: 0.6, color: c.muted),
    );
  }
}
