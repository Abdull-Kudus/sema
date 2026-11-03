import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/sema_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/report.dart';
import '../../domain/report_enums.dart';

/// Horizontal four-step progress track: Submitted → Acknowledged → In progress → Resolved.
class StatusTracker extends StatelessWidget {
  const StatusTracker({super.key, required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final steps = [...ReportStatus.track];
    if (status == ReportStatus.rejected) steps[3] = ReportStatus.rejected;
    final current = status.step;
    final tone = status.tone(c);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _line(c, i > 0 && i <= current, tone, visible: i > 0)),
                    _Dot(done: i <= current, active: i == current, icon: steps[i].icon, tone: tone),
                    Expanded(child: _line(c, i < current, tone, visible: i < steps.length - 1)),
                  ],
                ),
                const SizedBox(height: Space.xs),
                Text(
                  steps[i].label,
                  textAlign: TextAlign.center,
                  style: context.text.labelMedium?.copyWith(
                    color: i <= current ? c.text : c.muted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _line(SemaColors c, bool filled, Tone tone, {required bool visible}) => AnimatedContainer(
    duration: Motion.slow,
    height: 3,
    decoration: BoxDecoration(
      color: !visible ? Colors.transparent : (filled ? tone.fg : c.line),
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

class _Dot extends StatelessWidget {
  const _Dot({required this.done, required this.active, required this.icon, required this.tone});

  final bool done;
  final bool active;
  final IconData icon;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // The current step is marked with a page-coloured inner ring rather than a glow.
    return AnimatedContainer(
      duration: Motion.medium,
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? tone.fg : c.panel,
        border: Border.all(color: done ? tone.fg : c.line, width: 2),
      ),
      child: Container(
        decoration: active
            ? BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: c.page, width: 2),
              )
            : null,
        child: Icon(icon, size: 16, color: done ? c.page : c.muted),
      ),
    );
  }
}

/// Vertical history of every status change with staff notes.
class StatusHistory extends StatelessWidget {
  const StatusHistory({super.key, required this.updates});

  final List<ReportUpdate> updates;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final items = updates.reversed.toList();
    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: items[i].status.tone(c).fg),
                    ),
                    if (i < items.length - 1) Expanded(child: Container(width: 2, color: c.line)),
                  ],
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: Space.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(items[i].status.label, style: context.text.titleSmall),
                        if (items[i].note.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(items[i].note, style: context.text.bodyMedium),
                        ],
                        const SizedBox(height: 2),
                        Text(
                          '${items[i].authorName}${items[i].authorRole == 'staff' ? ' · Staff' : ''} · ${Formatters.short(items[i].createdAt)}',
                          style: context.text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: Motion.stagger * i).slideX(begin: 0.04),
      ],
    );
  }
}
