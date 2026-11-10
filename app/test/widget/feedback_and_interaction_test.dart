import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sema/core/theme/app_theme.dart';
import 'package:sema/core/widgets/feedback.dart';
import 'package:sema/core/widgets/pressable.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('SectionHeader widget', () {
    testWidgets('renders title and triggers optional action button', (tester) async {
      var actionTriggered = false;
      await tester.pumpWidget(
        _wrap(
          SectionHeader(
            'Recent Reports',
            action: 'See all',
            onAction: () => actionTriggered = true,
          ),
        ),
      );

      expect(find.text('Recent Reports'), findsOneWidget);
      expect(find.text('See all'), findsOneWidget);

      await tester.tap(find.text('See all'));
      expect(actionTriggered, isTrue);
    });
  });

  group('Pressable widget', () {
    testWidgets('triggers onTap callback when pressed', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        _wrap(
          Pressable(
            onTap: () => pressed = true,
            child: const Text('Press Me'),
          ),
        ),
      );

      await tester.tap(find.text('Press Me'));
      await tester.pumpAndSettle();

      expect(pressed, isTrue);
    });
  });

  group('confirmDialog function', () {
    testWidgets('returns false when Cancel is pressed and true when confirm is pressed', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await confirmDialog(
                    context,
                    title: 'Delete Report',
                    message: 'Are you sure you want to delete this report?',
                    confirmLabel: 'Delete',
                    destructive: true,
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Report'), findsOneWidget);
      expect(find.text('Are you sure you want to delete this report?'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isFalse);

      // Open dialog again
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Tap Delete
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });
}

