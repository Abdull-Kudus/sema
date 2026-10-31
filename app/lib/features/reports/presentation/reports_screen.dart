import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solar_icons/solar_icons.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/sema_colors.dart';
import '../../../core/widgets/feedback.dart';
import '../../auth/application/auth_providers.dart';
import '../application/report_filter.dart';
import '../application/report_providers.dart';
import '../domain/report_enums.dart';
import 'widgets/report_card.dart';

/// Browse, search and filter reports: campus-wide or just your own.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late final _search = TextEditingController(text: ref.read(reportFilterProvider).query);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clear() {
    _search.clear();
    ref.read(reportFilterProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(reportFilterProvider);
    final notifier = ref.read(reportFilterProvider.notifier);
    final scoped = ref.watch(scopedReportsProvider).value ?? const [];
    final results = ref.watch(filteredReportsProvider);
    final isStaff = ref.watch(isStaffProvider);

    int countFor(ReportStatus? s) => scoped
        .where(
          (r) =>
              (s == null || r.status == s) &&
              ReportFilter(query: filter.query, categories: filter.categories).matches(r),
        )
        .length;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(isStaff ? 'Incident queue' : 'Reports', style: context.text.headlineSmall),
        actions: [
          PopupMenuButton<ReportSort>(
            tooltip: 'Sort',
            icon: const Icon(SolarIconsOutline.sortVertical),
            initialValue: filter.sort,
            onSelected: notifier.sort,
            itemBuilder: (_) => [
              for (final s in ReportSort.values) PopupMenuItem(value: s, child: Text(s.label)),
            ],
          ),
          const SizedBox(width: Space.xs),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
            child: Column(
              children: [
                if (!isStaff) ...[
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ReportScope>(
                      segments: const [
                        ButtonSegment(
                          value: ReportScope.campus,
                          label: Text('Campus'),
                          icon: Icon(SolarIconsOutline.buildings_2),
                        ),
                        ButtonSegment(
                          value: ReportScope.mine,
                          label: Text('My reports'),
                          icon: Icon(SolarIconsOutline.user),
                        ),
                      ],
                      selected: {filter.scope},
                      onSelectionChanged: (s) => notifier.scope(s.first),
                      showSelectedIcon: false,
                    ),
                  ),
                  const SizedBox(height: Space.sm),
                ],
                TextField(
                  controller: _search,
                  onChanged: notifier.search,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search title, place or category',
                    prefixIcon: const Icon(SolarIconsOutline.magnifier),
                    suffixIcon: filter.query.isEmpty
                        ? IconButton(
                            tooltip: 'Filter by category',
                            icon: Badge(
                              isLabelVisible: filter.categories.isNotEmpty,
                              label: Text('${filter.categories.length}'),
                              child: const Icon(SolarIconsOutline.tuning_2),
                            ),
                            onPressed: () => _showCategorySheet(context),
                          )
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(SolarIconsOutline.closeCircle),
                            onPressed: () {
                              _search.clear();
                              notifier.search('');
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.sm),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
              children: [
                for (final s in <ReportStatus?>[null, ...ReportStatus.values])
                  Padding(
                    padding: const EdgeInsets.only(right: Space.xs),
                    child: ChoiceChip(
                      label: Text('${s?.label ?? 'All'}  ${countFor(s)}'),
                      selected: filter.status == s,
                      onSelected: (_) => notifier.status(s),
                    ),
                  ),
              ],
            ),
          ),
          if (filter.categories.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xs, Space.gutter, 0),
                children: [
                  for (final cat in filter.categories)
                    Padding(
                      padding: const EdgeInsets.only(right: Space.xs),
                      child: InputChip(
                        avatar: Icon(cat.icon, size: 16, color: cat.tone(context.colors).fg),
                        label: Text(cat.label),
                        onDeleted: () => notifier.toggleCategory(cat),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: Space.sm),
          Expanded(
            child: results.when(
              loading: () => const SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: Space.gutter),
                child: ReportListSkeleton(count: 6),
              ),
              error: (e, _) => EmptyState.error(e, onRetry: () => ref.invalidate(campusReportsProvider)),
              data: (reports) {
                if (reports.isEmpty) {
                  return filter.hasRefinements
                      ? EmptyState(
                          icon: SolarIconsBold.magnifier,
                          title: 'No matching reports',
                          message: 'Try a different search or clear the filters.',
                          actionLabel: 'Clear filters',
                          onAction: _clear,
                        )
                      : EmptyState(
                          icon: SolarIconsBold.clipboardCheck,
                          title: filter.scope == ReportScope.mine ? 'Nothing reported yet' : 'A quiet campus',
                          message: filter.scope == ReportScope.mine
                              ? 'Your reports and their progress will show up here.'
                              : 'No incidents have been reported yet.',
                        );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.xxl),
                  itemCount: reports.length,
                  separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
                  itemBuilder: (_, i) => ReportCard(
                    key: ValueKey(reports[i].id),
                    report: reports[i],
                  ).animate().fadeIn(delay: Motion.stagger * (i.clamp(0, 8))).slideY(begin: 0.06),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCategorySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final selected = ref.watch(reportFilterProvider).categories;
          final notifier = ref.read(reportFilterProvider.notifier);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filter by category', style: context.text.titleLarge),
                  const SizedBox(height: Space.md),
                  Wrap(
                    spacing: Space.xs,
                    runSpacing: Space.xs,
                    children: [
                      for (final cat in ReportCategory.values)
                        FilterChip(
                          avatar: Icon(
                            cat.icon,
                            size: 16,
                            color: selected.contains(cat)
                                ? context.colors.onBrand
                                : cat.tone(context.colors).fg,
                          ),
                          label: Text(cat.label),
                          selected: selected.contains(cat),
                          labelStyle: context.text.labelMedium?.copyWith(
                            color: selected.contains(cat) ? context.colors.onBrand : context.colors.text,
                          ),
                          onSelected: (_) => notifier.toggleCategory(cat),
                        ),
                    ],
                  ),
                  const SizedBox(height: Space.lg),
                  FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Show results')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
