import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../theme/sema_colors.dart';

/// The Sema mark: a speech bubble (speak up) holding an exclamation point
/// (an incident) with two signal waves (it gets heard).
class SemaMark extends StatelessWidget {
  const SemaMark({super.key, this.size = 56, this.colors, this.glyph});

  final double size;

  /// Overrides the theme colours, e.g. when rendering the launcher icon.
  final SemaColors? colors;
  final Color? glyph;

  @override
  Widget build(BuildContext context) {
    final c = colors ?? context.colors;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _MarkPainter(start: c.heroStart, end: c.brandDeep, glyph: glyph ?? c.onBrand),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter({required this.start, required this.end, required this.glyph});

  final Color start;
  final Color end;
  final Color glyph;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final bubble = Rect.fromLTWH(0, 0, s, s * 0.86);
    final r = s * 0.30;

    final body = Path()..addRRect(RRect.fromRectAndRadius(bubble, Radius.circular(r)));
    // Tail, bottom left. Unioned so the overlap with the body never cuts a hole.
    final tail = Path()
      ..moveTo(s * 0.16, s * 0.66)
      ..quadraticBezierTo(s * 0.17, s * 0.94, s * 0.06, s * 1.0)
      ..quadraticBezierTo(s * 0.32, s * 0.99, s * 0.46, s * 0.78)
      ..close();
    final path = Path.combine(PathOperation.union, body, tail);

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [start, end],
        ).createShader(Offset.zero & size),
    );

    final ink = Paint()..color = glyph;
    final cx = s * 0.40;

    // Exclamation bar and dot.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, s * 0.36), width: s * 0.11, height: s * 0.32),
        Radius.circular(s * 0.06),
      ),
      ink,
    );
    canvas.drawCircle(Offset(cx, s * 0.635), s * 0.062, ink);

    // Signal waves.
    final wave = Paint()
      ..color = glyph
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * 0.065;
    final center = Offset(cx + s * 0.02, s * 0.44);
    for (final (radius, alpha) in [(s * 0.20, 1.0), (s * 0.32, 0.55)]) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 4.2,
        math.pi / 2.1,
        false,
        wave..color = glyph.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.start != start || old.end != end || old.glyph != glyph;
}

/// Mark + wordmark lockup.
class SemaLogo extends StatelessWidget {
  const SemaLogo({super.key, this.size = 40, this.showTagline = false});

  final double size;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SemaMark(size: size),
        SizedBox(width: size * 0.3),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppConfig.appName.toLowerCase(),
              style: context.text.headlineMedium?.copyWith(
                fontSize: size * 0.72,
                height: 1,
                letterSpacing: -size * 0.03,
              ),
            ),
            if (showTagline) Text('Campus Incident Reporting', style: context.text.labelSmall),
          ],
        ),
      ],
    );
  }
}
