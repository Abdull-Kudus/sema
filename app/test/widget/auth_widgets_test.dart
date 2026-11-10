import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:sema/core/theme/app_theme.dart';
import 'package:sema/core/widgets/feedback.dart';
import 'package:sema/features/auth/presentation/auth_widgets.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('PasswordField widget', () {
    testWidgets('toggles obscure text when clicking suffix icon', (tester) async {
      final controller = TextEditingController(text: 'secret123');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _wrap(
          PasswordField(
            controller: controller,
            validator: (v) => null,
          ),
        ),
      );

      // Initially obscureText is true
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);
      TextField textField = tester.widget(textFieldFinder);
      expect(textField.obscureText, isTrue);

      // Tap suffix icon to reveal password
      final toggleFinder = find.byIcon(SolarIconsOutline.eye);
      expect(toggleFinder, findsOneWidget);
      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();

      textField = tester.widget(textFieldFinder);
      expect(textField.obscureText, isFalse);

      // Tap again to hide
      final hideFinder = find.byIcon(SolarIconsOutline.eyeClosed);
      expect(hideFinder, findsOneWidget);
      await tester.tap(hideFinder);
      await tester.pumpAndSettle();

      textField = tester.widget(textFieldFinder);
      expect(textField.obscureText, isTrue);
    });
  });

  group('PasswordStrength widget', () {
    testWidgets('renders score 0 as Weak with 4 bars', (tester) async {
      await tester.pumpWidget(_wrap(const PasswordStrength(score: 0)));
      expect(find.text('Weak'), findsOneWidget);
    });

    testWidgets('renders score 2 as Fair', (tester) async {
      await tester.pumpWidget(_wrap(const PasswordStrength(score: 2)));
      expect(find.text('Fair'), findsOneWidget);
    });

    testWidgets('renders score 3 as Good', (tester) async {
      await tester.pumpWidget(_wrap(const PasswordStrength(score: 3)));
      expect(find.text('Good'), findsOneWidget);
    });

    testWidgets('renders score 4 as Strong', (tester) async {
      await tester.pumpWidget(_wrap(const PasswordStrength(score: 4)));
      expect(find.text('Strong'), findsOneWidget);
    });
  });

  group('ErrorBanner widget', () {
    testWidgets('shows message and warning icon', (tester) async {
      await tester.pumpWidget(_wrap(const ErrorBanner('Invalid credentials provided')));
      await tester.pumpAndSettle();
      expect(find.text('Invalid credentials provided'), findsOneWidget);
      expect(find.byIcon(SolarIconsBold.dangerCircle), findsOneWidget);
    });
  });

  group('LoadingButton widget', () {
    testWidgets('shows label when not loading, triggers onPressed', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        _wrap(
          LoadingButton(
            label: 'Submit',
            loading: false,
            onPressed: () => pressed = true,
          ),
        ),
      );

      expect(find.text('Submit'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.text('Submit'));
      expect(pressed, isTrue);
    });

    testWidgets('shows spinner when loading and does not trigger onPressed', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        _wrap(
          LoadingButton(
            label: 'Submit',
            loading: true,
            onPressed: () => pressed = true,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit'), findsNothing);

      await tester.tap(find.byType(CircularProgressIndicator));
      expect(pressed, isFalse);
    });
  });

  group('EmptyState widget', () {
    testWidgets('renders icon, title, message, and responds to action button', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        _wrap(
          EmptyState(
            icon: SolarIconsBold.cloudCross,
            title: 'No Data Found',
            message: 'Please check your connection and retry.',
            actionLabel: 'Try again',
            onAction: () => retried = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Data Found'), findsOneWidget);
      expect(find.text('Please check your connection and retry.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      expect(retried, isTrue);
    });
  });
}
