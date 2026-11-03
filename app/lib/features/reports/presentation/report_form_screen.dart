import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:solar_icons/solar_icons.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/sema_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/pressable.dart';
import '../application/report_providers.dart';
import '../domain/report.dart';
import '../domain/report_enums.dart';
import 'widgets/photo_picker.dart';

/// Create a report, or edit one when [existing] is given.
class ReportFormScreen extends ConsumerStatefulWidget {
  const ReportFormScreen({super.key, this.existing});

  final Report? existing;

  @override
  ConsumerState<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends ConsumerState<ReportFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _description = TextEditingController(text: widget.existing?.description);
  late final _detail = TextEditingController(text: widget.existing?.locationDetail);
  late ReportCategory? _category = widget.existing?.category;
  late ReportPriority _priority = widget.existing?.priority ?? ReportPriority.medium;
  // Reports from before the area list changed may name an area that no longer exists.
  late String? _area = AppConfig.areaNamed(widget.existing?.location ?? '')?.name;
  late String? _spot = AppConfig.areaNamed(_area ?? '')?.spots
      .where((s) => s == widget.existing?.spot)
      .firstOrNull;
  late bool _anonymous = widget.existing?.isAnonymous ?? false;
  late final List<int> _kept = [for (var i = 0; i < (widget.existing?.photoUrls.length ?? 0); i++) i];
  final List<XFile> _files = [];
  bool _submitted = false;
  bool _dirty = false;

  bool get _editing => widget.existing != null;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _detail.dispose();
    super.dispose();
  }

  void _touch(VoidCallback change) => setState(() {
    change();
    _dirty = true;
  });

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _submitted = true);
    final valid = _form.currentState!.validate();
    if (!valid || _category == null) {
      HapticFeedback.heavyImpact();
      return;
    }
    final draft = ReportDraft(
      title: _title.text,
      description: _description.text,
      category: _category!,
      priority: _priority,
      location: _area!,
      spot: _spot ?? '',
      locationDetail: _detail.text,
      isAnonymous: _anonymous,
    );
    try {
      final id = await ref
          .read(reportEditorProvider.notifier)
          .save(draft: draft, newPhotos: _files, existing: widget.existing, keptPhotos: _kept);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Toast.show(context, _editing ? 'Report updated' : 'Report sent to campus staff');
      _dirty = false;
      if (_editing) {
        context.pop();
      } else {
        context.pushReplacement('/report/$id');
      }
    } catch (e) {
      if (mounted) Toast.show(context, 'Could not save: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final submit = ref.watch(reportEditorProvider);
    final existingUrls = [for (final i in _kept) widget.existing!.photoUrls[i]];

    return PopScope(
      canPop: !_dirty && !submit.busy,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || submit.busy) return;
        final leave = await confirmDialog(
          context,
          title: 'Discard this report?',
          message: 'What you have entered will be lost.',
          confirmLabel: 'Discard',
          destructive: true,
        );
        if (leave && context.mounted) {
          setState(() => _dirty = false);
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(SolarIconsOutline.altArrowLeft),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text(_editing ? 'Edit report' : 'Report an issue'),
        ),
        body: Form(
          key: _form,
          autovalidateMode: _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xs, Space.gutter, Space.xxl),
            children: [
              _Label(
                'What kind of issue?',
                error: _submitted && _category == null ? 'Choose a category' : null,
              ),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: Space.xs,
                crossAxisSpacing: Space.xs,
                childAspectRatio: 0.92,
                children: [
                  for (final (i, cat) in ReportCategory.values.indexed)
                    _CategoryTile(
                      category: cat,
                      selected: _category == cat,
                      onTap: () => _touch(() => _category = cat),
                    ).animate().fadeIn(delay: Motion.stagger * i).scaleXY(begin: 0.9),
                ],
              ),
              const SizedBox(height: Space.lg),
              const _Label('Title'),
              TextFormField(
                controller: _title,
                maxLength: AppConfig.titleMax,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                validator: Validators.title,
                onChanged: (_) => _dirty = true,
                decoration: const InputDecoration(hintText: 'e.g. Water leaking in Block B washroom'),
              ),
              const SizedBox(height: Space.xs),
              const _Label('Description'),
              TextFormField(
                controller: _description,
                minLines: 4,
                maxLines: 8,
                maxLength: AppConfig.descriptionMax,
                textCapitalization: TextCapitalization.sentences,
                validator: Validators.description,
                onChanged: (_) => _dirty = true,
                decoration: const InputDecoration(
                  hintText: 'What happened, since when, and who is affected?',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: Space.xs),
              const _Label('Where is it?'),
              DropdownButtonFormField<String>(
                initialValue: _area,
                isExpanded: true,
                style: context.text.bodyLarge,
                icon: const Icon(SolarIconsOutline.altArrowDown),
                borderRadius: Radii.card,
                dropdownColor: c.card,
                validator: (v) => Validators.required(v, 'Choose a campus area'),
                decoration: const InputDecoration(
                  prefixIcon: Icon(SolarIconsOutline.buildings_2),
                  hintText: 'Commons or area',
                ),
                items: [
                  for (final a in AppConfig.campusAreas) DropdownMenuItem(value: a.name, child: Text(a.name)),
                ],
                onChanged: (v) => _touch(() {
                  _area = v;
                  _spot = null;
                }),
              ),
              AnimatedSize(
                duration: Motion.fast,
                alignment: Alignment.topCenter,
                child: _area == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: Space.sm),
                        child: DropdownButtonFormField<String>(
                          // Rebuilt per area so the spot list and selection reset together.
                          key: ValueKey(_area),
                          initialValue: _spot,
                          isExpanded: true,
                          style: context.text.bodyLarge,
                          icon: const Icon(SolarIconsOutline.altArrowDown),
                          borderRadius: Radii.card,
                          dropdownColor: c.card,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(SolarIconsOutline.mapPoint),
                            hintText: 'Lab, room or spot (optional)',
                          ),
                          items: [
                            for (final s in AppConfig.areaNamed(_area!)!.spots)
                              DropdownMenuItem(
                                value: s,
                                child: Text(s, overflow: TextOverflow.ellipsis),
                              ),
                          ],
                          onChanged: (v) => _touch(() => _spot = v),
                        ),
                      ),
              ),
              const SizedBox(height: Space.sm),
              TextFormField(
                controller: _detail,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => _dirty = true,
                decoration: const InputDecoration(
                  hintText: 'Floor or landmark, e.g. near the stairs (optional)',
                  prefixIcon: Icon(SolarIconsOutline.pin),
                ),
              ),
              const SizedBox(height: Space.lg),
              const _Label('How urgent is it?'),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<ReportPriority>(
                  showSelectedIcon: false,
                  segments: [
                    for (final p in ReportPriority.values) ButtonSegment(value: p, label: Text(p.label)),
                  ],
                  selected: {_priority},
                  onSelectionChanged: (s) => _touch(() => _priority = s.first),
                ),
              ),
              const SizedBox(height: Space.lg),
              _Label('Photos', trailing: '${existingUrls.length + _files.length}/${AppConfig.maxPhotos}'),
              PhotoPicker(
                existingUrls: existingUrls,
                files: _files,
                onAdd: (f) => _touch(() => _files.addAll(f)),
                onRemoveExisting: (i) => _touch(() => _kept.removeAt(i)),
                onRemoveFile: (i) => _touch(() => _files.removeAt(i)),
              ),
              const SizedBox(height: Space.lg),
              Container(
                decoration: BoxDecoration(
                  color: c.panel,
                  borderRadius: Radii.card,
                  border: Border.all(color: c.line),
                ),
                child: SwitchListTile(
                  value: _anonymous,
                  onChanged: (v) => _touch(() => _anonymous = v),
                  secondary: Icon(SolarIconsBold.incognito, color: c.brand),
                  title: Text('Report anonymously', style: context.text.titleSmall),
                  subtitle: Text(
                    'Other students will not see your name. Campus staff can still follow up to prevent misuse.',
                    style: context.text.bodySmall,
                  ),
                  shape: const RoundedRectangleBorder(borderRadius: Radii.card),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xs, Space.gutter, Space.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSize(
                  duration: Motion.fast,
                  child: submit.busy
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: Space.xs),
                          child: Column(
                            children: [
                              LinearProgressIndicator(
                                value: submit.progress,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              const SizedBox(height: 4),
                              Text(submit.stage, style: context.text.bodySmall),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                LoadingButton(
                  label: _editing ? 'Save changes' : 'Submit report',
                  icon: SolarIconsBold.plain,
                  loading: submit.busy,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {this.error, this.trailing});

  final String text;
  final String? error;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: Row(
        children: [
          Text(text, style: context.text.titleSmall),
          const Spacer(),
          if (error != null)
            Text(
              error!,
              style: context.text.labelMedium?.copyWith(color: c.crimson.fg),
            ).animate().shakeX(hz: 4, amount: 2)
          else if (trailing != null)
            Text(trailing!, style: context.text.labelSmall),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.selected, required this.onTap});

  final ReportCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tone = category.tone(c);
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.fast,
        decoration: BoxDecoration(
          gradient: selected ? c.hero : null,
          color: selected ? null : c.panel,
          borderRadius: Radii.card,
          border: Border.all(color: selected ? Colors.transparent : c.line),
          boxShadow: selected
              ? [BoxShadow(color: c.brand.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(category.icon, color: selected ? c.onBrand : tone.fg, size: 26),
            const SizedBox(height: 6),
            Text(
              category.label,
              style: context.text.labelMedium?.copyWith(color: selected ? c.onBrand : c.text),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
