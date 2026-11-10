import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sema/features/reports/application/report_filter.dart';
import 'package:sema/features/reports/application/report_providers.dart';
import 'package:sema/features/reports/domain/report_enums.dart';

import '../helpers.dart';

void main() {
  group('ReportFilterController', () {
    test('updates query and toggles categories', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(reportFilterProvider.notifier);

      expect(container.read(reportFilterProvider).query, '');
      controller.search('Wi-Fi   ');
      expect(container.read(reportFilterProvider).query, 'Wi-Fi');

      controller.toggleCategory(ReportCategory.internet);
      expect(container.read(reportFilterProvider).categories, {ReportCategory.internet});

      controller.toggleCategory(ReportCategory.water);
      expect(container.read(reportFilterProvider).categories, {
        ReportCategory.internet,
        ReportCategory.water,
      });

      // Toggling again removes it
      controller.toggleCategory(ReportCategory.internet);
      expect(container.read(reportFilterProvider).categories, {ReportCategory.water});

      // Clear resets query and categories but preserves scope
      controller.scope(ReportScope.mine);
      controller.clear();
      expect(container.read(reportFilterProvider).query, '');
      expect(container.read(reportFilterProvider).categories, isEmpty);
      expect(container.read(reportFilterProvider).scope, ReportScope.mine);
    });
  });

  group('trending and attentionQueue providers', () {
    final rLow = makeReport(id: '1', title: 'Low', priority: ReportPriority.low, status: ReportStatus.submitted);
    final rHigh = makeReport(
      id: '2',
      title: 'High Urgent',
      priority: ReportPriority.high,
      status: ReportStatus.inProgress,
      upvoterIds: ['u1', 'u2'],
    );
    final rResolved = makeReport(
      id: '3',
      title: 'Resolved Issue',
      priority: ReportPriority.high,
      status: ReportStatus.resolved,
      upvoterIds: ['u1', 'u2', 'u3', 'u4'],
    );

    test('trendingProvider filters only open reports with upvotes', () async {
      final container = ProviderContainer(
        overrides: [
          campusReportsProvider.overrideWith((ref) => Stream.value([rLow, rHigh, rResolved])),
        ],
      );
      addTearDown(container.dispose);

      container.listen(trendingProvider, (_, _) {});
      await pumpEventQueue();

      final trending = container.read(trendingProvider).value;
      expect(trending, isNotNull);
      // Resolved report rResolved should NOT appear even with high upvotes
      expect(trending!.map((r) => r.id), [rHigh.id]);
    });

    test('attentionQueueProvider sorts open reports by priority', () async {
      final container = ProviderContainer(
        overrides: [
          campusReportsProvider.overrideWith((ref) => Stream.value([rLow, rHigh, rResolved])),
        ],
      );
      addTearDown(container.dispose);

      container.listen(attentionQueueProvider, (_, _) {});
      await pumpEventQueue();

      final attention = container.read(attentionQueueProvider).value;
      expect(attention, isNotNull);
      expect(attention!.length, 2);
      expect(attention.first.id, rHigh.id);
      expect(attention.last.id, rLow.id);
    });
  });
}
