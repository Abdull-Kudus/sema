import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sema/core/theme/app_theme.dart';
import 'package:sema/features/home/presentation/home_widgets.dart';

void main() {
  testWidgets('GrowBar fills its share of the width at full height', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: Center(
            child: SizedBox(width: 200, child: GrowBar(fraction: 0.5, color: Color(0xFF000000))),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final fill = tester.getSize(find.byType(DecoratedBox).last);
    expect(fill.width, closeTo(100, 0.5));
    expect(fill.height, 8);
  });
}
