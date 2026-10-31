import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:solar_icons/solar_icons.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/sema_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/pressable.dart';
import '../../reports/presentation/widgets/report_card.dart';
import '../application/notification_providers.dart';
import '../domain/app_notification.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadCountProvider);
    final actions = ref.read(notificationActionsProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text('Alerts', style: context.text.headlineSmall),
        actions: [
          if (unread > 0) TextButton(onPressed: actions.markAllRead, child: const Text('Mark all read')),
          const SizedBox(width: Space.xs),
        ],
      ),
      body: items.when(
        loading: () => const SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: Space.gutter),
          child: ReportListSkeleton(count: 5),
        ),
        error: (e, _) => EmptyState.error(e),
        data: (list) => list.isEmpty
            ? const EmptyState(
                icon: SolarIconsBold.bellOff,
                title: 'No alerts yet',
                message: 'When campus staff update one of your reports, you will hear about it here.',
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xs, Space.gutter, Space.xxl),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
                itemBuilder: (context, i) => Dismissible(
                  key: ValueKey(list[i].id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => actions.remove(list[i]),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: Space.lg),
                    decoration: BoxDecoration(color: context.colors.crimson.bg, borderRadius: Radii.card),
                    child: Icon(SolarIconsOutline.trashBinMinimalistic, color: context.colors.crimson.fg),
                  ),
                  child: _NotificationTile(
                    item: list[i],
                    onTap: () {
                      actions.markRead(list[i]);
                      context.push('/report/${list[i].reportId}');
                    },
                  ),
                ).animate().fadeIn(delay: Motion.stagger * i.clamp(0, 8)).slideX(begin: 0.05),
              ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tone = item.status.tone(c);
    return SemaCard(
      onTap: onTap,
      color: item.read ? c.card : c.brandSoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: tone.bg, shape: BoxShape.circle),
            child: Icon(item.status.icon, color: tone.fg, size: 20),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: context.text.titleSmall),
                const SizedBox(height: 2),
                Text(item.body, style: context.text.bodyMedium?.copyWith(color: c.muted)),
                const SizedBox(height: 4),
                Text(Formatters.relative(item.createdAt), style: context.text.labelSmall),
              ],
            ),
          ),
          if (!item.read)
            Container(
              width: 9,
              height: 9,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(color: c.brand, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}
