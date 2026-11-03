import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:solar_icons/solar_icons.dart';

import '../../../core/config/app_config.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/sema_colors.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/sema_logo.dart';
import '../../reports/domain/report_enums.dart';
import '../application/auth_providers.dart';

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
              const Align(alignment: Alignment.centerLeft, child: SemaLogo(size: 36)),
              const Expanded(child: _HeroPreview()),
              Text.rich(
                TextSpan(
                  text: 'Speak up.\n',
                  children: [
                    TextSpan(
                      text: 'Fix campus.',
                      style: TextStyle(color: c.brand),
                    ),
                  ],
                ),
                style: context.text.displayMedium,
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
              const SizedBox(height: Space.sm),
              Text(
                'Report broken facilities, outages and safety concerns at ${AppConfig.institution}, '
                'and follow every fix from submitted to resolved.',
                style: context.text.bodyLarge?.copyWith(color: c.muted),
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: Space.lg),
              FilledButton(onPressed: () => context.push('/sign-up'), child: const Text('Create account')),
              const SizedBox(height: Space.sm),
              OutlinedButton(
                onPressed: () => context.push('/sign-in'),
                child: const Text('I already have an account'),
              ),
              const SizedBox(height: Space.xs),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: loading
                          ? null
                          : () => ref.read(authControllerProvider.notifier).signInWithGoogle(),
                      icon: const Icon(SolarIconsBold.squareAcademicCap, size: 18),
                      label: const Text('ALU Google'),
                    ),
                  ),
                  Container(width: 1, height: 20, color: c.line),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => context.push(Routes.supervisorSignIn),
                      icon: const Icon(SolarIconsBold.shieldUser, size: 18),
                      label: const Text('Supervisor portal'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.sm),
            ],
          ),
        ),
      ),
    );
  }
}

/// Floating example cards that preview what the app does.
class _HeroPreview extends StatelessWidget {
  const _HeroPreview();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget card(ReportCategory cat, String title, ReportStatus status, double angle) => Transform.rotate(
      angle: angle,
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(Space.sm),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: Radii.card,
          border: Border.all(color: c.line),
          boxShadow: [
            BoxShadow(color: c.brand.withValues(alpha: 0.12), blurRadius: 30, offset: const Offset(0, 12)),
          ],
        ),
        child: Row(
          children: [
            Icon(cat.icon, color: cat.tone(c).fg),
            const SizedBox(width: Space.xs),
            Expanded(
              child: Text(
                title,
                style: context.text.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            StatusPill(status, dense: true),
          ],
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, box) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
                width: box.maxHeight * 0.75,
                height: box.maxHeight * 0.75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [c.brand.withValues(alpha: 0.28), c.brand.withValues(alpha: 0)],
                  ),
                ),
              )
              .animate(onPlay: (a) => a.repeat(reverse: true))
              .scaleXY(begin: 0.9, end: 1.05, duration: 3.seconds),
          const SemaMark(size: 96)
              .animate()
              .scale(duration: Motion.slow, curve: Curves.easeOutBack)
              .then()
              .shimmer(duration: 1400.ms),
          Positioned(
            top: box.maxHeight * 0.08,
            left: 0,
            child: card(ReportCategory.water, 'No water in Block B', ReportStatus.inProgress, -0.05),
          ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2),
          Positioned(
            bottom: box.maxHeight * 0.08,
            right: 0,
            child: card(ReportCategory.internet, 'Library Wi-Fi down', ReportStatus.resolved, 0.04),
          ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.2),
        ],
      ),
    );
  }
}
