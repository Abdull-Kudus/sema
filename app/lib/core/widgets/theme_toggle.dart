import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solar_icons/solar_icons.dart';

import '../theme/sema_colors.dart';
import '../theme/theme_controller.dart';

/// Sun / moon button that flips between light and dark, saved like the
/// Profile setting. Available before sign-in.
class ThemeToggle extends ConsumerWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = context.isDark;
    return IconButton(
      tooltip: dark ? 'Switch to light mode' : 'Switch to dark mode',
      onPressed: () => ref.read(themeModeProvider.notifier).set(dark ? ThemeMode.light : ThemeMode.dark),
      style: IconButton.styleFrom(side: BorderSide(color: context.colors.line)),
      icon: Icon(dark ? SolarIconsOutline.sun : SolarIconsOutline.moon, color: context.colors.text),
    );
  }
}
