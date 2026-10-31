import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// A number that counts up to its value and eases between later values.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({super.key, required this.value, this.style, this.suffix = ''});

  final num value;
  final TextStyle? style;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: Motion.counter,
      curve: Curves.easeOutExpo,
      builder: (context, v, _) => Text(
        '${v.round()}$suffix',
        style: (style ?? const TextStyle()).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      ),
    );
  }
}
