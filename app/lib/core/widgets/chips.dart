import 'package:flutter/material.dart';

import '../../features/reports/domain/report_enums.dart';
import '../theme/app_tokens.dart';
import '../theme/sema_colors.dart';

/// A small pill in a tone, optionally with an icon.
class TonePill extends StatelessWidget {
  const TonePill({super.key, required this.label, required this.tone, this.icon, this.dense = false});

  final String label;
  final Tone tone;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 3 : 5),
      decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(Radii.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: dense ? 12 : 14, color: tone.fg), const SizedBox(width: 4)],
          Text(
            label,
            style: context.text.labelMedium?.copyWith(color: tone.fg, fontSize: dense ? 11 : 12),
          ),
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key, this.dense = false});

  final ReportStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: Motion.medium,
    child: TonePill(
      key: ValueKey(status),
      label: status.label,
      tone: status.tone(context.colors),
      icon: status.icon,
      dense: dense,
    ),
  );
}

class PriorityPill extends StatelessWidget {
  const PriorityPill(this.priority, {super.key});

  final ReportPriority priority;

  @override
  Widget build(BuildContext context) =>
      TonePill(label: '${priority.label} priority', tone: priority.tone(context.colors), dense: true);
}

/// The category icon in a tinted rounded square.
class CategoryBadge extends StatelessWidget {
  const CategoryBadge(this.category, {super.key, this.size = 44});

  final ReportCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tone = category.tone(context.colors);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(size * 0.32)),
      child: Icon(category.icon, color: tone.fg, size: size * 0.5),
    );
  }
}
