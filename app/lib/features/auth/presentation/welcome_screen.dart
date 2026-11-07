import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:solar_icons/solar_icons.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/sema_colors.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/sema_logo.dart';
import '../../reports/domain/report_enums.dart';
import '../application/auth_providers.dart';
import 'auth_widgets.dart';

/// First screen: one illustration, one line of copy, clear actions.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final loading = ref.watch(authControllerProvider).isLoading;

    ref.listen(authControllerProvider, (_, next) {
      if (next.hasError) Toast.show(context, next.error.toString(), error: true);
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: Space.md),
              const Align(alignment: Alignment.centerLeft, child: SemaLogo(size: 32)),
              const Expanded(child: Center(child: _CampusIllustration())),
              Text.rich(
                TextSpan(
                  text: 'Speak up.\n',
                  children: [
                    TextSpan(
                      text: 'Fix campus.',
                      style: TextStyle(color: c.brandText),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: context.text.displayMedium,
              ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.08),
              const SizedBox(height: Space.xs),
              Text(
                'Report campus issues and track every fix.',
                textAlign: TextAlign.center,
                style: context.text.bodyLarge?.copyWith(color: c.muted),
              ).animate().fadeIn(delay: 250.ms),
              const SizedBox(height: Space.lg),
              FilledButton(onPressed: () => context.push(Routes.signUp), child: const Text('Create account')),
              const SizedBox(height: Space.sm),
              OutlinedButton(onPressed: () => context.push(Routes.signIn), child: const Text('Sign in')),
              const SizedBox(height: Space.sm),
              GoogleButton(
                loading: loading,
                onPressed: () => ref.read(authControllerProvider.notifier).signInWithGoogle(),
              ),
              const SizedBox(height: Space.xs),
              TextButton.icon(
                onPressed: () => context.push(Routes.supervisorSignIn),
                icon: const Icon(SolarIconsOutline.shieldUser, size: 18),
                label: const Text('Supervisor portal'),
              ),
              const SizedBox(height: Space.xs),
            ],
          ),
        ),
      ),
    );
  }
}

/// An original, flat illustration: the Sema mark at the centre of two rings,
/// with the kinds of issue students report slowly orbiting it. The orbit
/// stops when the phone asks apps to reduce motion.
class _CampusIllustration extends StatefulWidget {
  const _CampusIllustration();

  @override
  State<_CampusIllustration> createState() => _CampusIllustrationState();
}

class _CampusIllustrationState extends State<_CampusIllustration> with SingleTickerProviderStateMixin {
  static const _orbit = [
    ReportCategory.water,
    ReportCategory.electricity,
    ReportCategory.internet,
    ReportCategory.safety,
    ReportCategory.sanitation,
    ReportCategory.furniture,
  ];

  late final _spin = AnimationController(vsync: this, duration: Motion.orbit);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    MediaQuery.disableAnimationsOf(context) ? _spin.stop() : _spin.repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LayoutBuilder(
      builder: (context, box) {
        final size = (box.maxHeight < box.maxWidth ? box.maxHeight : box.maxWidth).clamp(160.0, 300.0);
        final badge = size * 0.15;
        // Badges travel between the inner and outer ring.
        final radius = size * 0.41;
        Widget ring(double f) => Container(
          width: size * f,
          height: size * f,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: f > 0.8 ? c.brandSoft.withValues(alpha: 0.45) : c.brandSoft,
            border: Border.all(color: c.line),
          ),
        );
        return SizedBox.square(
          dimension: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ring(1),
              ring(0.66),
              SemaMark(size: size * 0.3).animate().scale(duration: Motion.slow, curve: Curves.easeOutBack),
              // One builder moves every badge; each stays upright as it circles.
              AnimatedBuilder(
                animation: _spin,
                builder: (context, _) => Stack(
                  alignment: Alignment.center,
                  children: [
                    for (final (i, cat) in _orbit.indexed)
                      Transform.translate(
                        offset: Offset.fromDirection(
                          (_spin.value + i / _orbit.length) * 2 * math.pi - math.pi / 2,
                          radius,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: c.page,
                            borderRadius: BorderRadius.circular(badge * 0.4),
                          ),
                          child: CategoryBadge(cat, size: badge),
                        ),
                      ),
                  ],
                ),
              ).animate().fadeIn(delay: Motion.stagger * 3, duration: Motion.slow),
            ],
          ),
        );
      },
    );
  }
}
