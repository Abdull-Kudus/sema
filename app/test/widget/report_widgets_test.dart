import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:sema/core/providers.dart';
import 'package:sema/core/theme/app_theme.dart';
import 'package:sema/core/theme/theme_controller.dart';
import 'package:sema/core/widgets/chips.dart';
import 'package:sema/core/widgets/theme_toggle.dart';
import 'package:sema/core/widgets/user_avatar.dart';
import 'package:sema/features/reports/domain/report_enums.dart';
import 'package:sema/features/reports/presentation/widgets/report_card.dart';

import '../helpers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ReportCard widget', () {
    testWidgets('renders report title, location, status, and fire icon when high priority', (tester) async {
      final report = makeReport(
        id: 'r-card-1',
        title: 'Generator failure in Building 3',
        priority: ReportPriority.high,
        status: ReportStatus.inProgress,
        location: 'Engineering Hub',
        upvoterIds: ['u1', 'u2', 'u3'],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(body: ReportCard(report: report)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Generator failure in Building 3'), findsOneWidget);
      expect(find.text('Engineering Hub'), findsOneWidget);
      expect(find.text('In progress'), findsOneWidget);
      // Fire icon for high priority
      expect(find.byIcon(SolarIconsBold.fire), findsOneWidget);
      // Upvotes count 3
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('does not show fire icon or upvotes when not high priority and 0 upvotes', (tester) async {
      final report = makeReport(
        id: 'r-card-2',
        title: 'Minor paint peeling',
        priority: ReportPriority.low,
        status: ReportStatus.submitted,
        location: 'Hostel A',
        upvoterIds: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(body: ReportCard(report: report)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Minor paint peeling'), findsOneWidget);
      expect(find.byIcon(SolarIconsBold.fire), findsNothing);
      expect(find.byIcon(SolarIconsBold.like), findsNothing);
    });
  });

  group('UserAvatar widget', () {
    testWidgets('shows user initials when no photo is provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: UserAvatar(name: 'Sarah Connor', size: 48),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SC'), findsOneWidget);
      expect(find.byIcon(SolarIconsBold.incognito), findsNothing);
    });

    testWidgets('shows incognito mask when anonymous is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: UserAvatar(name: 'Sarah Connor', anonymous: true, size: 48),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(SolarIconsBold.incognito), findsOneWidget);
      expect(find.text('SC'), findsNothing);
    });
  });

  group('TonePill and CategoryBadge', () {
    testWidgets('renders category badge with correct category icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: CategoryBadge(ReportCategory.electricity, size: 44),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(ReportCategory.electricity.icon), findsOneWidget);
    });

    testWidgets('renders priority pill with text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: PriorityPill(ReportPriority.high),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('High priority'), findsOneWidget);
    });
  });

  group('ThemeToggle widget', () {
    testWidgets('flips theme mode between light and dark when tapped', (tester) async {
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              return MaterialApp(
                theme: AppTheme.light(),
                darkTheme: AppTheme.dark(),
                themeMode: ref.watch(themeModeProvider),
                home: const Scaffold(
                  body: ThemeToggle(),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // In light mode, the icon should be moon to switch to dark
      expect(find.byIcon(SolarIconsOutline.moon), findsOneWidget);

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      // Mode changed to dark, so icon changes to sun
      expect(find.byIcon(SolarIconsOutline.sun), findsOneWidget);
    });
  });
}
