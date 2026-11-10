import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sema/core/theme/app_theme.dart';
import 'package:sema/features/reports/domain/report_enums.dart';
import 'package:sema/features/reports/presentation/widgets/status_update_sheet.dart';

import '../helpers.dart';

void main() {
  testWidgets('showStatusUpdateSheet displays nextOptions chips and enforces note validation', (tester) async {
    final report = makeReport(
      id: 'rep-status-1',
      title: 'Water pipe leaking',
      status: ReportStatus.inProgress,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showStatusUpdateSheet(context, report),
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      ),
    );

    // Tap button to open the bottom sheet
    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    // Verify title and chips for inProgress nextOptions (Resolved, Closed)
    expect(find.text('Update status'), findsOneWidget);
    expect(find.text('Resolved'), findsOneWidget);
    expect(find.text('Closed'), findsOneWidget);

    // Try saving without entering a note (both Resolved and Closed require a note)
    await tester.tap(find.text('Update and notify reporter'));
    await tester.pumpAndSettle();

    // Verify the validation error is displayed
    expect(find.text('Tell the reporter what was done (5+ characters)'), findsOneWidget);

    // Type a valid note
    await tester.enterText(find.byType(TextField), 'Plumber replaced leaking valve.');
    await tester.pumpAndSettle();

    // The text was entered
    expect(find.text('Plumber replaced leaking valve.'), findsOneWidget);
  });
}

