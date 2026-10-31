import 'package:sema/features/reports/domain/report.dart';
import 'package:sema/features/reports/domain/report_enums.dart';

Report makeReport({
  String id = 'r1',
  String title = 'Broken tap in washroom',
  ReportCategory category = ReportCategory.water,
  ReportStatus status = ReportStatus.submitted,
  ReportPriority priority = ReportPriority.medium,
  String location = 'Student Residence',
  String reporterId = 'u1',
  List<String> upvoterIds = const [],
  DateTime? createdAt,
  DateTime? resolvedAt,
}) {
  final created = createdAt ?? DateTime(2026, 10, 1);
  return Report(
    id: id,
    title: title,
    description: 'Water has been running all night on the second floor.',
    category: category,
    priority: priority,
    status: status,
    location: location,
    reporterId: reporterId,
    upvoterIds: upvoterIds,
    createdAt: created,
    updatedAt: created,
    resolvedAt: resolvedAt,
  );
}
