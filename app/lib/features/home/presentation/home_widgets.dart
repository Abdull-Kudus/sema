import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:solar_icons/solar_icons.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/sema_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/animated_count.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../auth/domain/app_user.dart';
import '../../notifications/application/notification_providers.dart';

/// Greeting row with the user's photo and the notifications bell.
class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key, required this.user, required this.subtitle});

  final AppUser user;
  final String subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final unread = ref.watch(unreadCountProvider);
    return Row(
      children: [
        Pressable(
          onTap: () => context.go('/profile'),
          child: Hero(
            tag: 'me-avatar',
            child: UserAvatar(name: user.name, photoUrl: user.photoUrl, size: 48, ring: true),
          ),
        ),
        const SizedBox(width: Space.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${Formatters.greeting()},', style: context.text.bodyMedium?.copyWith(color: c.muted)),
              Text(
                user.firstName,
                style: context.text.headlineSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: c.line),
          ),
          child: IconButton(
            tooltip: 'Notifications',
            onPressed: () => context.go('/alerts'),
            icon: Badge(
              isLabelVisible: unread > 0,
              smallSize: 9,
              backgroundColor: c.crimson.fg,
              child: Icon(SolarIconsOutline.bell, color: c.text),
            ),
          ),
        ),
      ],
    );
  }
}

/// A KPI tile with an icon, an animated number and a label.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.tone,
    this.onTap,
  });

  final IconData icon;
  final int value;
  final String label;
  final Tone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SemaCard(
      onTap: onTap,
      padding: const EdgeInsets.all(Space.sm),
      color: tone.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: context.colors.card, borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, size: 19, color: tone.fg),
          ),
          const SizedBox(height: Space.sm),
          AnimatedCount(value: value, style: context.text.headlineLarge),
          Text(label, style: context.text.labelMedium?.copyWith(color: context.colors.muted), maxLines: 2),
        ],
      ),
    );
  }
}

/// Horizontal bar that grows to [fraction] when it first appears.
class GrowBar extends StatelessWidget {
  const GrowBar({super.key, required this.fraction, required this.color, this.track});

  final double fraction;
  final Color color;
  final Color? track;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.pill),
      child: SizedBox(
        height: 8,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: track ?? context.colors.panel)),
            // Positioned.fill gives the fill the bar's full height; a bare Stack child would be 0px tall.
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fraction.clamp(0, 1)),
                duration: Motion.counter,
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: v,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(Radii.pill)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
