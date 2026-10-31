import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_tokens.dart';
import '../widgets/sema_logo.dart';

/// Shown for the moment Firebase restores the session.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: const SemaLogo(
          size: 52,
          showTagline: true,
        ).animate().fadeIn(duration: Motion.medium).scaleXY(begin: 0.9, curve: Curves.easeOutBack),
      ),
    );
  }
}
