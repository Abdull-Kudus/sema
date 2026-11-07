// Renders the Sema mark to the PNGs used for the launcher icon and native
// splash. Regenerate with:
//   flutter test --update-goldens test/tool
@Tags(['brand'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sema/core/theme/sema_colors.dart';
import 'package:sema/core/widgets/sema_logo.dart';

Future<void> _render(
  WidgetTester tester,
  String file, {
  required double canvas,
  required double mark,
  Color? background,
}) async {
  tester.view
    ..physicalSize = Size.square(canvas)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    RepaintBoundary(
      child: ColoredBox(
        color: background ?? const Color(0x00000000),
        child: Center(
          child: SemaMark(size: mark, colors: SemaColors.light),
        ),
      ),
    ),
  );
  await expectLater(find.byType(RepaintBoundary).first, matchesGoldenFile('../../assets/brand/$file'));
}

void main() {
  testWidgets(
    'launcher icon',
    (t) => _render(t, 'icon.png', canvas: 1024, mark: 680, background: SemaColors.light.page),
  );
  // Adaptive icons crop to the inner 66%, so the foreground mark is smaller.
  testWidgets('adaptive foreground', (t) => _render(t, 'icon_foreground.png', canvas: 1024, mark: 440));
  testWidgets('splash', (t) => _render(t, 'splash.png', canvas: 768, mark: 288));
}
