import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:solar_icons/solar_icons.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/sema_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/animated_count.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/pressable.dart';
import '../../auth/domain/app_user.dart';
import '../../reports/application/report_filter.dart';
import '../../reports/application/report_providers.dart';
import '../../reports/domain/report_enums.dart';
import '../../reports/presentation/widgets/report_card.dart';
import 'home_widgets.dart';

/// The staff console: campus-wide KPIs, category load and the triage queue.
class StaffDashboard extends ConsumerWidget {
  const StaffDashboard({super.key, required this.user});

  final AppUser user;

  void _openQueue(WidgetRef ref, BuildContext context, ReportStatus? status) {
    ref.read(reportFilterProvider.notifier)
      ..clear()
      ..scope(ReportScope.campus)
      ..status(status);
    context.go('/reports');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final statsAsync = ref.watch(campusStatsProvider);
    final queue = ref.watch(attentionQueueProvider);
    final stats = statsAsync.value;

    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.gutter, Space.md, Space.gutter, Space.xxl),
      children: [
        HomeHeader(user: user, subtitle: 'Campus console'),
        const SizedBox(height: Space.md),
        TonePill(label: 'Staff console', tone: c.azure, icon: SolarIconsBold.shieldUser),
        const SizedBox(height: Space.md),
        _KpiHero(open: stats?.open ?? 0, rate: stats?.resolutionRate ?? 0, average: stats?.averageResolution),
        const SizedBox(height: Space.md),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: Space.sm,
          crossAxisSpacing: Space.sm,
          childAspectRatio: 1.45,
          children: [
            StatTile(
              icon: SolarIconsBold.letter,
              value: stats?.submitted ?? 0,
              label: 'New, awaiting triage',
              tone: c.amber,
              onTap: () => _openQueue(ref, context, ReportStatus.submitted),
            ),
            StatTile(
              icon: SolarIconsBold.hourglass,
              value: stats?.active ?? 0,
              label: 'Being worked on',
              tone: c.sky,
              onTap: () => _openQueue(ref, context, ReportStatus.inProgress),
            ),
            StatTile(
              icon: SolarIconsBold.checkCircle,
              value: stats?.resolved ?? 0,
              label: 'Resolved',
              tone: c.emerald,
              onTap: () => _openQueue(ref, context, ReportStatus.resolved),
            ),
            StatTile(
              icon: SolarIconsBold.closeCircle,
              value: stats?.closed ?? 0,
              label: 'Closed',
              tone: c.crimson,
              onTap: () => _openQueue(ref, context, ReportStatus.rejected),
            ),
          ],
        ),
        if (stats != null && stats.total > 0) ...[
          const SizedBox(height: Space.lg),
          const SectionHeader('Load by category'),
          SemaCard(
            child: Column(
              children: [
                for (final entry
                    in (stats.byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value))))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        CategoryBadge(entry.key, size: 30),
                        const SizedBox(width: Space.sm),
                        SizedBox(width: 82, child: Text(entry.key.label, style: context.text.labelLarge)),
                        Expanded(
                          child: GrowBar(fraction: entry.value / stats.total, color: entry.key.tone(c).fg),
                        ),
                        const SizedBox(width: Space.sm),
                        SizedBox(
                          width: 28,
                          child: Text(
                            '${entry.value}',
                            textAlign: TextAlign.end,
                            style: context.text.titleSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: Space.lg),
        SectionHeader(
          'Needs attention',
          action: 'Open queue',
          onAction: () => _openQueue(ref, context, null),
        ),
        queue.when(
          loading: () => const ReportListSkeleton(count: 3),
          error: (e, _) => EmptyState.error(e),
          data: (reports) => reports.isEmpty
              ? const EmptyState(
                  icon: SolarIconsBold.cupStar,
                  title: 'All clear',
                  message: 'Every report on campus has been handled.',
                )
              : Column(
                  children: [
                    for (final (i, r) in reports.take(5).indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Space.sm),
                        child: ReportCard(report: r)
                            .animate()
                            .fadeIn(delay: Motion.stagger * i)
                            .slideY(begin: 0.08),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _KpiHero extends StatelessWidget {
  const _KpiHero({required this.open, required this.rate, required this.average});

  final int open;
  final double rate;
  final Duration? average;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final onHero = c.onBrand;
    // Secondary lines stay fully opaque: faded white on the gradient read as blurry.
    final faded = onHero;
    return SemaCard(
      gradient: c.hero,
      borderRadius: Radii.panel,
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Open incidents', style: context.text.titleSmall?.copyWith(color: faded)),
          AnimatedCount(
            value: open,
            style: context.text.displayLarge?.copyWith(color: onHero),
          ),
          const SizedBox(height: Space.md),
          Row(
            children: [
              Text('Resolution rate', style: context.text.labelMedium?.copyWith(color: faded)),
              const Spacer(),
              AnimatedCount(
                value: (rate * 100).round(),
                suffix: '%',
                style: context.text.titleSmall?.copyWith(color: onHero),
              ),
            ],
          ),
          const SizedBox(height: Space.xs),
          GrowBar(fraction: rate, color: onHero, track: onHero.withValues(alpha: 0.2)),
          const SizedBox(height: Space.md),
          Row(
            children: [
              Icon(SolarIconsOutline.clockCircle, size: 16, color: faded),
              const SizedBox(width: 6),
              Text(
                average == null
                    ? 'No resolved reports yet'
                    : 'Average fix time ${Formatters.duration(average!)}',
                style: context.text.labelMedium?.copyWith(color: faded),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: Motion.medium).slideY(begin: 0.05);
  }
}
