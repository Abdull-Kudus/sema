import 'package:flutter_test/flutter_test.dart';
import 'package:sema/features/reports/application/report_filter.dart';
import 'package:sema/features/reports/domain/report_enums.dart';

import '../helpers.dart';

void main() {
  final reports = [
    makeReport(id: 'a', title: 'No water in Block B', createdAt: DateTime(2026, 10, 3), upvoterIds: ['x']),
    makeReport(
      id: 'b',
      title: 'Projector broken',
      category: ReportCategory.facilities,
      status: ReportStatus.inProgress,
      priority: ReportPriority.high,
      location: 'Lecture Rooms',
      createdAt: DateTime(2026, 10, 1),
    ),
    makeReport(
      id: 'c',
      title: 'Library Wi-Fi down',
      category: ReportCategory.internet,
      status: ReportStatus.resolved,
      createdAt: DateTime(2026, 10, 2),
      resolvedAt: DateTime(2026, 10, 2, 6),
      upvoterIds: ['x', 'y', 'z'],
    ),
  ];

  group('ReportFilter', () {
    test('search matches title, location and category', () {
      expect(const ReportFilter(query: 'wi-fi').apply(reports).map((r) => r.id), ['c']);
      expect(const ReportFilter(query: 'lecture').apply(reports).map((r) => r.id), ['b']);
      expect(const ReportFilter(query: 'block b').apply(reports).map((r) => r.id), ['a']);
    });

    test('status and category filters combine', () {
      expect(const ReportFilter(status: ReportStatus.inProgress).apply(reports).map((r) => r.id), ['b']);
      expect(
        const ReportFilter(categories: {ReportCategory.water, ReportCategory.internet})
            .apply(reports)
            .map((r) => r.id),
        ['a', 'c'],
      );
    });

    test('sorts by newest, support and priority', () {
      expect(const ReportFilter().apply(reports).map((r) => r.id), ['a', 'c', 'b']);
      expect(const ReportFilter(sort: ReportSort.mostSupported).apply(reports).first.id, 'c');
      expect(const ReportFilter(sort: ReportSort.priority).apply(reports).first.id, 'b');
    });

    test('copyWith can clear the status', () {
      const f = ReportFilter(status: ReportStatus.resolved);
      expect(f.copyWith(status: () => null).status, isNull);
      expect(f.copyWith(query: 'x').status, ReportStatus.resolved);
    });
  });

  group('ReportStats', () {
    test('counts by bucket and averages resolution time', () {
      final s = ReportStats.of(reports);
      expect(s.total, 3);
      expect(s.submitted, 1);
      expect(s.active, 1);
      expect(s.resolved, 1);
      expect(s.open, 2);
      expect(s.averageResolution, const Duration(hours: 6));
      expect(s.byCategory[ReportCategory.water], 1);
    });

    test('handles an empty list', () {
      final s = ReportStats.of(const []);
      expect(s.resolutionRate, 0);
      expect(s.averageResolution, isNull);
    });
  });

  group('ReportStatus workflow', () {
    test('closed reports can only be reopened', () {
      expect(ReportStatus.resolved.nextOptions, [ReportStatus.inProgress]);
      expect(ReportStatus.resolved.isOpen, isFalse);
    });

    test('closing requires a note', () {
      expect(ReportStatus.resolved.requiresNote, isTrue);
      expect(ReportStatus.acknowledged.requiresNote, isFalse);
    });

    test('owners edit only while submitted', () {
      expect(makeReport().canEditBy('u1'), isTrue);
      expect(makeReport().canEditBy('u2'), isFalse);
      expect(makeReport(status: ReportStatus.inProgress).canEditBy('u1'), isFalse);
    });
  });
}
