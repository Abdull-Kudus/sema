import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:solar_icons/solar_icons.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/sema_colors.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/sema_logo.dart';
import '../../auth/domain/app_user.dart';
import '../../reports/application/report_filter.dart';
import '../../reports/application/report_providers.dart';
import '../../reports/domain/report.dart';
import '../../reports/domain/report_enums.dart';
import '../../reports/presentation/widgets/report_card.dart';
import 'home_widgets.dart';

class StudentHome extends ConsumerWidget {
  const StudentHome({super.key, required this.user});

  final AppUser user;

  void _openReports(WidgetRef ref, BuildContext context, ReportStatus? status) {
    ref.read(reportFilterProvider.notifier)
      ..clear()
      ..scope(ReportScope.mine)
      ..status(status);
    context.go('/reports');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final stats = ref.watch(myStatsProvider);
    final mine = ref.watch(myReportsProvider);
    final trending = ref.watch(trendingProvider).value ?? const <Report>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.gutter, Space.md, Space.gutter, Space.xxl),
      children: [
        HomeHeader(user: user, subtitle: 'Help make our campus better'),
        const SizedBox(height: Space.lg),
        const _ReportHero(),
        const SizedBox(height: Space.lg),
        SectionHeader('Your reports', action: 'See all', onAction: () => _openReports(ref, context, null)),
        _StatsGrid(
          total: stats.value?.total ?? 0,
          submitted: stats.value?.submitted ?? 0,
          active: stats.value?.active ?? 0,
          resolved: stats.value?.resolved ?? 0,
          onTap: (s) => _openReports(ref, context, s),
        ),
        if (trending.isNotEmpty) ...[
          const SizedBox(height: Space.lg),
          const SectionHeader('Trending on campus'),
          SizedBox(
            height: 128,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: trending.length,
              separatorBuilder: (_, _) => const SizedBox(width: Space.sm),
              itemBuilder: (_, i) => _TrendingCard(report: trending[i]),
            ),
          ),
        ],
        const SizedBox(height: Space.lg),
        const SectionHeader('Recent activity'),
        mine.when(
          loading: () => const ReportListSkeleton(count: 3),
          error: (e, _) => EmptyState.error(e),
          data: (reports) => reports.isEmpty
              ? SemaCard(
                  child: Row(
                    children: [
                      Icon(SolarIconsBold.confetti, color: c.brandText, size: 32),
                      const SizedBox(width: Space.sm),
                      Expanded(
                        child: Text(
                          'No reports yet. Spotted something broken? Tap Report and it reaches campus staff in seconds.',
                          style: context.text.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    for (final (i, r) in reports.take(3).indexed)
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

class _ReportHero extends StatelessWidget {
  const _ReportHero();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(gradient: c.hero, borderRadius: Radii.panel),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -20,
            child: Opacity(opacity: 0.18, child: SemaMark(size: 160, glyph: c.onBrand)),
          ),
          Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'See an issue\non campus?',
                  style: context.text.headlineMedium?.copyWith(color: c.onBrand),
                ),
                const SizedBox(height: Space.xs),
                Text(
                  'Report it in under a minute and follow every step until it is fixed.',
                  style: context.text.bodyMedium?.copyWith(color: c.onBrand.withValues(alpha: 0.85)),
                ),
                const SizedBox(height: Space.md),
                Pressable(
                  onTap: () => context.push('/report/new'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: 14),
                    decoration: BoxDecoration(color: c.card, borderRadius: Radii.card),
                    child: Row(
                      children: [
                        Icon(SolarIconsBold.addCircle, color: c.brandText),
                        const SizedBox(width: Space.xs),
                        Expanded(
                          child: Text(
                            'Report an issue',
                            style: context.text.titleMedium?.copyWith(color: c.brandText),
                          ),
                        ),
                        Icon(SolarIconsOutline.altArrowRight, color: c.brandText),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: Motion.medium).slideY(begin: 0.05);
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.total,
    required this.submitted,
    required this.active,
    required this.resolved,
    required this.onTap,
  });

  final int total;
  final int submitted;
  final int active;
  final int resolved;
  final void Function(ReportStatus?) onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tiles = [
      StatTile(
        icon: SolarIconsBold.documents,
        value: total,
        label: 'All reports',
        tone: c.azure,
        onTap: () => onTap(null),
      ),
      StatTile(
        icon: SolarIconsBold.letter,
        value: submitted,
        label: 'Submitted',
        tone: c.amber,
        onTap: () => onTap(ReportStatus.submitted),
      ),
      StatTile(
        icon: SolarIconsBold.hourglass,
        value: active,
        label: 'In progress',
        tone: c.sky,
        onTap: () => onTap(ReportStatus.inProgress),
      ),
      StatTile(
        icon: SolarIconsBold.checkCircle,
        value: resolved,
        label: 'Resolved',
        tone: c.emerald,
        onTap: () => onTap(ReportStatus.resolved),
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Space.sm,
      crossAxisSpacing: Space.sm,
      childAspectRatio: 1.45,
      children: [
        for (final (i, t) in tiles.indexed)
          t.animate().fadeIn(delay: Motion.stagger * i).scaleXY(begin: 0.94, curve: Curves.easeOutBack),
      ],
    );
  }
}

class _TrendingCard extends StatelessWidget {
  const _TrendingCard({required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: 220,
      child: SemaCard(
        onTap: () => context.push('/report/${report.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CategoryBadge(report.category, size: 32),
                const Spacer(),
                Icon(SolarIconsBold.usersGroupRounded, size: 16, color: c.brandText),
                const SizedBox(width: 4),
                Text('${report.upvotes}', style: context.text.titleSmall?.copyWith(color: c.brandText)),
              ],
            ),
            const Spacer(),
            Text(report.title, style: context.text.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
            Text(
              report.location,
              style: context.text.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
