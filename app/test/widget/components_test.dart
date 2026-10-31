import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sema/core/theme/app_theme.dart';
import 'package:sema/core/widgets/animated_count.dart';
import 'package:sema/core/widgets/chips.dart';
import 'package:sema/features/reports/domain/report_enums.dart';
import 'package:sema/features/reports/presentation/widgets/status_tracker.dart';

Widget _wrap(Widget child, {bool dark = false}) => MaterialApp(
  theme: dark ? AppTheme.dark() : AppTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('StatusPill shows the status label in both themes', (tester) async {
    for (final dark in [false, true]) {
      await tester.pumpWidget(_wrap(const StatusPill(ReportStatus.inProgress), dark: dark));
      expect(find.text('In progress'), findsOneWidget);
    }
  });

  testWidgets('StatusTracker swaps the last step for a closed report', (tester) async {
    await tester.pumpWidget(_wrap(const StatusTracker(status: ReportStatus.rejected)));
    expect(find.text('Closed'), findsOneWidget);
    expect(find.text('Resolved'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('AnimatedCount counts up to its value', (tester) async {
    await tester.pumpWidget(_wrap(const AnimatedCount(value: 12)));
    expect(find.text('0'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('12'), findsOneWidget);
  });
}
