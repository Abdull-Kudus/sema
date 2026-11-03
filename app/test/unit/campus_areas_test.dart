import 'package:flutter_test/flutter_test.dart';
import 'package:sema/core/config/app_config.dart';
import 'package:sema/features/reports/domain/report.dart';
import 'package:sema/features/reports/domain/report_enums.dart';

void main() {
  test('every building area has washrooms, the grounds do not', () {
    for (final area in AppConfig.campusAreas) {
      expect(area.spots.contains('Washrooms'), area.name != 'Campus Grounds', reason: area.name);
    }
  });

  test('area names are unique and resolvable', () {
    final names = AppConfig.campusAreas.map((a) => a.name).toList();
    expect(names.toSet().length, names.length);
    expect(AppConfig.areaNamed('Social Commons')!.spots, contains('Food Court & Vendors'));
    expect(AppConfig.areaNamed('Library'), isNull);
  });

  test('full location joins area, spot and detail, skipping blanks', () {
    Report at({String spot = '', String detail = ''}) => Report(
      id: 'r',
      title: 't',
      description: 'd',
      category: ReportCategory.sanitation,
      priority: ReportPriority.low,
      status: ReportStatus.submitted,
      location: 'Social Commons',
      spot: spot,
      locationDetail: detail,
      reporterId: 'u',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    expect(at().fullLocation, 'Social Commons');
    expect(at(spot: 'Washrooms').fullLocation, 'Social Commons · Washrooms');
    expect(at(spot: 'Washrooms', detail: '2nd floor').fullLocation, 'Social Commons · Washrooms · 2nd floor');
  });
}
