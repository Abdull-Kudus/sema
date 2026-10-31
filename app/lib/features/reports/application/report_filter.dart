import '../domain/report.dart';
import '../domain/report_enums.dart';

enum ReportScope { campus, mine }

enum ReportSort {
  newest('Newest'),
  mostSupported('Most supported'),
  priority('Priority');

  const ReportSort(this.label);

  final String label;
}

/// The search / filter / sort state of the reports list. Pure Dart so the
/// filtering logic is unit-tested without Firebase.
class ReportFilter {
  const ReportFilter({
    this.query = '',
    this.status,
    this.categories = const {},
    this.scope = ReportScope.campus,
    this.sort = ReportSort.newest,
  });

  final String query;
  final ReportStatus? status;
  final Set<ReportCategory> categories;
  final ReportScope scope;
  final ReportSort sort;

  bool get hasRefinements => query.isNotEmpty || status != null || categories.isNotEmpty;

  ReportFilter copyWith({
    String? query,
    ReportStatus? Function()? status,
    Set<ReportCategory>? categories,
    ReportScope? scope,
    ReportSort? sort,
  }) => ReportFilter(
    query: query ?? this.query,
    status: status != null ? status() : this.status,
    categories: categories ?? this.categories,
    scope: scope ?? this.scope,
    sort: sort ?? this.sort,
  );

  bool matches(Report r) {
    if (status != null && r.status != status) return false;
    if (categories.isNotEmpty && !categories.contains(r.category)) return false;
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return r.title.toLowerCase().contains(q) ||
        r.description.toLowerCase().contains(q) ||
        r.fullLocation.toLowerCase().contains(q) ||
        r.category.label.toLowerCase().contains(q);
  }

  List<Report> apply(Iterable<Report> reports) {
    final list = reports.where(matches).toList();
    switch (sort) {
      case ReportSort.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case ReportSort.mostSupported:
        list.sort((a, b) => b.upvotes.compareTo(a.upvotes));
      case ReportSort.priority:
        list.sort((a, b) {
          final p = b.priority.index.compareTo(a.priority.index);
          return p != 0 ? p : b.createdAt.compareTo(a.createdAt);
        });
    }
    return list;
  }
}

/// Counts shown on dashboards.
class ReportStats {
  const ReportStats({
    required this.total,
    required this.submitted,
    required this.active,
    required this.resolved,
    required this.closed,
    required this.byCategory,
    this.averageResolution,
  });

  final int total;
  final int submitted;
  final int active;
  final int resolved;
  final int closed;
  final Map<ReportCategory, int> byCategory;
  final Duration? averageResolution;

  int get open => submitted + active;

  double get resolutionRate => total == 0 ? 0 : resolved / total;

  factory ReportStats.of(Iterable<Report> reports) {
    var submitted = 0, active = 0, resolved = 0, closed = 0;
    final byCategory = <ReportCategory, int>{};
    final durations = <Duration>[];
    for (final r in reports) {
      byCategory.update(r.category, (v) => v + 1, ifAbsent: () => 1);
      switch (r.status) {
        case ReportStatus.submitted:
          submitted++;
        case ReportStatus.acknowledged || ReportStatus.inProgress:
          active++;
        case ReportStatus.resolved:
          resolved++;
          if (r.resolutionTime case final d?) durations.add(d);
        case ReportStatus.rejected:
          closed++;
      }
    }
    return ReportStats(
      total: reports.length,
      submitted: submitted,
      active: active,
      resolved: resolved,
      closed: closed,
      byCategory: byCategory,
      averageResolution: durations.isEmpty ? null : durations.reduce((a, b) => a + b) ~/ durations.length,
    );
  }
}
