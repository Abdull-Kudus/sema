import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:solar_icons/solar_icons.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/sema_colors.dart';
import '../notifications/application/notification_providers.dart';

/// Bottom navigation around the four tab branches, with the "Report" action
/// raised in the centre because it is the app's primary job.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _tabs = [
    (SolarIconsOutline.home2, SolarIconsBold.home2, 'Home'),
    (SolarIconsOutline.documentText, SolarIconsBold.documentText, 'Reports'),
    (SolarIconsOutline.bell, SolarIconsBold.bell, 'Alerts'),
    (SolarIconsOutline.userCircle, SolarIconsBold.userCircle, 'Profile'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final unread = ref.watch(unreadCountProvider);

    Widget tab(int i) {
      final (icon, active, label) = _tabs[i];
      final selected = shell.currentIndex == i;
      return Expanded(
        child: InkResponse(
          onTap: () {
            HapticFeedback.selectionClick();
            shell.goBranch(i, initialLocation: i == shell.currentIndex);
          },
          radius: 36,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Badge(
                isLabelVisible: i == 2 && unread > 0,
                label: Text('$unread'),
                backgroundColor: c.crimson.fg,
                child: AnimatedSwitcher(
                  duration: Motion.fast,
                  child: Icon(
                    selected ? active : icon,
                    key: ValueKey(selected),
                    color: selected ? c.brand : c.muted,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: context.text.labelMedium?.copyWith(
                  color: selected ? c.brand : c.muted,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: shell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: c.card,
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 68,
            child: Row(
              children: [
                tab(0),
                tab(1),
                Expanded(
                  child: Center(child: _ReportButton(onTap: () => context.push('/report/new'))),
                ),
                tab(2),
                tab(3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportButton extends StatelessWidget {
  const _ReportButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: 'Report an issue',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: c.hero,
            boxShadow: [
              BoxShadow(color: c.brand.withValues(alpha: 0.4), blurRadius: 18, offset: const Offset(0, 6)),
            ],
          ),
          child: Icon(SolarIconsOutline.addCircle, color: c.onBrand, size: 28),
        ),
      ).animate().scale(delay: 200.ms, duration: Motion.medium, curve: Curves.easeOutBack),
    );
  }
}
