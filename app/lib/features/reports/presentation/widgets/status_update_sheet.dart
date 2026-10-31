import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/sema_colors.dart';
import '../../../../core/widgets/chips.dart';
import '../../../../core/widgets/feedback.dart';
import '../../application/report_providers.dart';
import '../../domain/report.dart';
import '../../domain/report_enums.dart';

/// Staff-only sheet to move a report to its next status with a note.
Future<void> showStatusUpdateSheet(BuildContext context, Report report) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _StatusUpdateSheet(report: report),
  );
}

class _StatusUpdateSheet extends ConsumerStatefulWidget {
  const _StatusUpdateSheet({required this.report});

  final Report report;

  @override
  ConsumerState<_StatusUpdateSheet> createState() => _StatusUpdateSheetState();
}

class _StatusUpdateSheetState extends ConsumerState<_StatusUpdateSheet> {
  final _note = TextEditingController();
  late ReportStatus _status = widget.report.status.nextOptions.first;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_status.requiresNote && _note.text.trim().length < 5) {
      setState(() => _error = 'Tell the reporter what was done (5+ characters)');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(reportEditorProvider.notifier).changeStatus(widget.report, _status, _note.text);
      if (!mounted) return;
      Navigator.pop(context);
      Toast.show(context, 'Marked as ${_status.label.toLowerCase()} · reporter notified');
    } catch (e) {
      setState(() {
        _saving = false;
        _error = 'Could not update: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.gutter,
        0,
        Space.gutter,
        MediaQuery.viewInsetsOf(context).bottom + Space.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Update status', style: context.text.titleLarge),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('Currently ', style: context.text.bodySmall),
              StatusPill(widget.report.status, dense: true),
            ],
          ),
          const SizedBox(height: Space.md),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (final s in widget.report.status.nextOptions)
                ChoiceChip(
                  avatar: Icon(s.icon, size: 16, color: _status == s ? c.onBrand : s.tone(c).fg),
                  label: Text(s.label),
                  selected: _status == s,
                  onSelected: (_) => setState(() => _status = s),
                ),
            ],
          ),
          const SizedBox(height: Space.md),
          TextField(
            controller: _note,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: _status.requiresNote
                  ? 'Required: what was done, or why it is closed'
                  : 'Optional note for the reporter',
              errorText: _error,
            ),
          ),
          const SizedBox(height: Space.md),
          LoadingButton(label: 'Update and notify reporter', loading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}
