import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:solar_icons/solar_icons.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/sema_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../auth/application/auth_providers.dart';
import '../application/report_providers.dart';
import '../domain/report.dart';
import 'widgets/status_tracker.dart';
import 'widgets/status_update_sheet.dart';

class ReportDetailScreen extends ConsumerWidget {
  const ReportDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(reportProvider(id));
    return report.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: EmptyState.error(e)),
      data: (r) => r == null
          ? Scaffold(
              appBar: AppBar(),
              body: const EmptyState(
                icon: SolarIconsBold.trashBinMinimalistic,
                title: 'Report removed',
                message: 'This report was withdrawn or deleted.',
              ),
            )
          : _DetailView(report: r),
    );
  }
}

class _DetailView extends ConsumerWidget {
  const _DetailView({required this.report});

  final Report report;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await confirmDialog(
      context,
      title: 'Delete this report?',
      message: 'It will be removed for everyone, together with its photos. This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await ref.read(reportEditorProvider.notifier).delete(report);
      if (!context.mounted) return;
      context.pop();
      Toast.show(context, 'Report deleted');
    } catch (e) {
      if (context.mounted) Toast.show(context, 'Could not delete: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final me = ref.watch(currentUserProvider).value;
    final isStaff = me?.isStaff ?? false;
    final canEdit = report.canEditBy(me?.uid);
    final updates = ref.watch(reportUpdatesProvider(report.id));
    final hasPhotos = report.photoUrls.isNotEmpty;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: hasPhotos ? 300 : null,
            leading: _CircleButton(icon: SolarIconsOutline.altArrowLeft, onTap: () => context.pop()),
            actions: [
              if (canEdit || isStaff)
                PopupMenuButton<String>(
                  icon: const Icon(SolarIconsOutline.menuDots),
                  onSelected: (v) => v == 'edit'
                      ? context.push('/report/${report.id}/edit', extra: report)
                      : _delete(context, ref),
                  itemBuilder: (_) => [
                    if (canEdit) const PopupMenuItem(value: 'edit', child: Text('Edit report')),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete report', style: TextStyle(color: c.crimson.fg)),
                    ),
                  ],
                ),
            ],
            title: hasPhotos ? null : const Text('Incident details'),
            flexibleSpace: hasPhotos ? FlexibleSpaceBar(background: _Gallery(report: report)) : null,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(Space.gutter, Space.md, Space.gutter, 120),
            sliver: SliverList.list(
              children: [
                Row(
                  children: [
                    CategoryBadge(report.category, size: 36),
                    const SizedBox(width: Space.xs),
                    Text(report.category.label, style: context.text.labelLarge?.copyWith(color: c.muted)),
                    const Spacer(),
                    StatusPill(report.status),
                  ],
                ),
                const SizedBox(height: Space.sm),
                Text(report.title, style: context.text.headlineMedium),
                const SizedBox(height: Space.sm),
                Wrap(
                  spacing: Space.md,
                  runSpacing: Space.xs,
                  children: [
                    _Meta(icon: SolarIconsOutline.mapPoint, text: report.fullLocation),
                    _Meta(icon: SolarIconsOutline.calendar, text: Formatters.dayTime(report.createdAt)),
                  ],
                ),
                const SizedBox(height: Space.sm),
                Align(alignment: Alignment.centerLeft, child: PriorityPill(report.priority)),
                const SizedBox(height: Space.md),
                _Reporter(report: report, isStaff: isStaff),
                const SizedBox(height: Space.lg),
                SemaCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Progress', style: context.text.titleMedium),
                      const SizedBox(height: Space.md),
                      StatusTracker(status: report.status),
                    ],
                  ),
                ),
                const SizedBox(height: Space.lg),
                Text('Description', style: context.text.titleMedium),
                const SizedBox(height: Space.xs),
                Text(report.description, style: context.text.bodyLarge),
                const SizedBox(height: Space.lg),
                Text('Updates', style: context.text.titleMedium),
                const SizedBox(height: Space.sm),
                updates.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('$e', style: context.text.bodySmall),
                  data: (list) => StatusHistory(updates: list),
                ),
              ].animate(interval: 40.ms).fadeIn(duration: Motion.medium).slideY(begin: 0.04),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xs, Space.gutter, Space.sm),
          child: Row(
            children: [
              if (!report.isOwnedBy(me?.uid)) ...[
                Expanded(
                  child: _MeTooButton(report: report, uid: me?.uid),
                ),
                if (isStaff) const SizedBox(width: Space.sm),
              ],
              if (isStaff)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => showStatusUpdateSheet(context, report),
                    icon: const Icon(SolarIconsBold.refreshCircle, size: 20),
                    label: const Text('Update status'),
                  ),
                ),
              if (!isStaff && report.isOwnedBy(me?.uid))
                Expanded(
                  child: SemaCard(
                    color: c.panel,
                    padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: 14),
                    child: Row(
                      children: [
                        Icon(SolarIconsBold.usersGroupRounded, color: c.brand, size: 20),
                        const SizedBox(width: Space.xs),
                        Expanded(
                          child: Text(
                            report.upvotes == 0
                                ? 'You will be notified of every update'
                                : '${report.upvotes} ${report.upvotes == 1 ? 'student has' : 'students have'} the same issue',
                            style: context.text.labelLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeTooButton extends ConsumerWidget {
  const _MeTooButton({required this.report, required this.uid});

  final Report report;
  final String? uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final on = report.upvotedBy(uid);
    return Pressable(
      onTap: () async {
        HapticFeedback.lightImpact();
        try {
          await ref.read(reportEditorProvider.notifier).toggleUpvote(report);
        } catch (e) {
          if (context.mounted) Toast.show(context, 'Could not update: $e', error: true);
        }
      },
      child: AnimatedContainer(
        duration: Motion.fast,
        height: 54,
        decoration: BoxDecoration(
          color: on ? c.brandSoft : c.card,
          borderRadius: Radii.card,
          border: Border.all(color: on ? c.brand : c.line),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              on ? SolarIconsBold.like : SolarIconsOutline.like,
              color: on ? c.brand : c.text,
              size: 20,
            ).animate(target: on ? 1 : 0).scaleXY(end: 1.25, duration: 120.ms).then().scaleXY(end: 0.8),
            const SizedBox(width: Space.xs),
            Text(
              on ? 'You too · ${report.upvotes}' : 'Me too · ${report.upvotes}',
              style: context.text.titleSmall?.copyWith(color: on ? c.brand : c.text),
            ),
          ],
        ),
      ),
    );
  }
}

class _Reporter extends StatelessWidget {
  const _Reporter({required this.report, required this.isStaff});

  final Report report;
  final bool isStaff;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        UserAvatar(
          name: report.reporterName ?? '',
          photoUrl: report.reporterPhotoUrl,
          anonymous: report.isAnonymous,
          size: 36,
        ),
        const SizedBox(width: Space.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reported by ${report.displayReporter}', style: context.text.labelLarge),
              if (report.handledBy != null)
                Text('Handled by ${report.handledBy}', style: context.text.bodySmall),
            ],
          ),
        ),
        if (report.isAnonymous && isStaff)
          Tooltip(
            message: 'Identity hidden from students; available to staff for follow-up',
            child: Icon(SolarIconsOutline.infoCircle, color: c.muted, size: 18),
          ),
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: context.colors.muted),
      const SizedBox(width: 4),
      Text(text, style: context.text.bodySmall),
    ],
  );
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(8),
    child: Material(
      color: context.colors.card.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Icon(icon, color: context.colors.text, size: 22),
      ),
    ),
  );
}

class _Gallery extends StatefulWidget {
  const _Gallery({required this.report});

  final Report report;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final urls = widget.report.photoUrls;
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: urls.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (context, i) => GestureDetector(
            onTap: () => _openViewer(context, urls, i),
            child: Hero(
              tag: 'photo-${widget.report.id}-$i',
              child: CachedNetworkImage(
                imageUrl: urls[i],
                fit: BoxFit.cover,
                placeholder: (_, _) => ColoredBox(color: c.skeleton),
              ),
            ),
          ),
        ),
        if (urls.length > 1)
          Positioned(
            bottom: Space.md,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < urls.length; i++)
                  AnimatedContainer(
                    duration: Motion.fast,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: c.onBrand.withValues(alpha: i == _page ? 1 : 0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  void _openViewer(BuildContext context, List<String> urls, int initial) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: AppPalette.black,
        pageBuilder: (context, _, _) => Scaffold(
          backgroundColor: AppPalette.black,
          appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: AppPalette.white),
          body: PageView.builder(
            controller: PageController(initialPage: initial),
            itemCount: urls.length,
            itemBuilder: (_, i) => InteractiveViewer(
              child: Center(
                child: Hero(
                  tag: 'photo-${widget.report.id}-$i',
                  child: CachedNetworkImage(imageUrl: urls[i], fit: BoxFit.contain),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
