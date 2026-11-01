import 'package:flutter/widgets.dart';
import 'package:solar_icons/solar_icons.dart';

import '../../../core/theme/sema_colors.dart';

enum ReportCategory {
  facilities('Facilities', SolarIconsBold.buildings_2),
  water('Water', SolarIconsBold.waterdrop),
  electricity('Electricity', SolarIconsBold.bolt),
  furniture('Furniture', SolarIconsBold.chair),
  sanitation('Sanitation', SolarIconsBold.trashBinMinimalistic),
  safety('Safety', SolarIconsBold.shieldWarning),
  internet('Wi-Fi', SolarIconsBold.wifiRouterRound),
  other('Other', SolarIconsBold.widget_2);

  const ReportCategory(this.label, this.icon);

  final String label;
  final IconData icon;

  Tone tone(SemaColors c) => switch (this) {
    facilities => c.azure,
    water => c.sky,
    electricity => c.amber,
    furniture => c.orange,
    sanitation => c.lime,
    safety => c.crimson,
    internet => c.pink,
    other => c.emerald,
  };

  static ReportCategory parse(String? v) => values.firstWhere((e) => e.name == v, orElse: () => other);
}

enum ReportPriority {
  low('Low'),
  medium('Medium'),
  high('High');

  const ReportPriority(this.label);

  final String label;

  Tone tone(SemaColors c) => switch (this) {
    low => c.emerald,
    medium => c.amber,
    high => c.crimson,
  };

  static ReportPriority parse(String? v) => values.firstWhere((e) => e.name == v, orElse: () => medium);
}

/// Workflow: submitted → acknowledged → inProgress → resolved.
/// Staff can reject at any open step (duplicate, out of scope, misuse).
enum ReportStatus {
  submitted('Submitted', SolarIconsBold.letter),
  acknowledged('Acknowledged', SolarIconsBold.eye),
  inProgress('In progress', SolarIconsBold.hourglass),
  resolved('Resolved', SolarIconsBold.checkCircle),
  rejected('Closed', SolarIconsBold.closeCircle);

  const ReportStatus(this.label, this.icon);

  final String label;
  final IconData icon;

  bool get isOpen => this != resolved && this != rejected;

  /// Position on the progress track (rejected shares the final slot).
  int get step => switch (this) {
    submitted => 0,
    acknowledged => 1,
    inProgress => 2,
    resolved || rejected => 3,
  };

  static const track = [submitted, acknowledged, inProgress, resolved];

  /// Statuses a staff member may move this report to.
  List<ReportStatus> get nextOptions => switch (this) {
    submitted => [acknowledged, inProgress, resolved, rejected],
    acknowledged => [inProgress, resolved, rejected],
    inProgress => [resolved, rejected],
    resolved || rejected => [inProgress],
  };

  /// Closing a report must explain why to the reporter.
  bool get requiresNote => this == resolved || this == rejected;

  Tone tone(SemaColors c) => switch (this) {
    submitted => c.amber,
    acknowledged => c.sky,
    inProgress => c.azure,
    resolved => c.emerald,
    rejected => c.crimson,
  };

  static ReportStatus parse(String? v) => values.firstWhere((e) => e.name == v, orElse: () => submitted);
}
