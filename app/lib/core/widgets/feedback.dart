import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:solar_icons/solar_icons.dart';

import '../theme/app_tokens.dart';
import '../theme/sema_colors.dart';

/// Friendly empty / error state with an optional action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  factory EmptyState.error(Object error, {VoidCallback? onRetry}) => EmptyState(
    icon: SolarIconsBold.cloudCross,
    title: 'Could not load this',
    message: error.toString().replaceFirst('Exception: ', ''),
    actionLabel: onRetry == null ? null : 'Try again',
    onAction: onRetry,
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(color: c.brandSoft, shape: BoxShape.circle),
              child: Icon(icon, size: 38, color: c.brand),
            ).animate().scale(duration: Motion.medium, curve: Curves.easeOutBack),
            const SizedBox(height: Space.md),
            Text(title, style: context.text.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: Space.xs),
            Text(
              message,
              style: context.text.bodyMedium?.copyWith(color: c.muted),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: Space.md),
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(minimumSize: const Size(160, 46)),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ).animate().fadeIn(duration: Motion.medium).slideY(begin: 0.05),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Row(
        children: [
          Expanded(child: Text(title, style: context.text.titleLarge)),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              child: Text(action!),
            ),
        ],
      ),
    );
  }
}

/// Floating snackbars with a status icon.
abstract final class Toast {
  static void show(BuildContext context, String message, {bool error = false}) {
    final c = context.colors;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                error ? SolarIconsBold.dangerCircle : SolarIconsBold.checkCircle,
                color: error ? c.crimson.fg : c.emerald.fg,
                size: 20,
              ),
              const SizedBox(width: Space.sm),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }
}

/// A full-width filled button that shows a spinner while [loading].
class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        disabledBackgroundColor: loading ? c.brand.withValues(alpha: 0.75) : null,
      ),
      child: AnimatedSwitcher(
        duration: Motion.fast,
        child: loading
            ? SizedBox.square(
                key: const ValueKey('spin'),
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: c.onBrand),
              )
            : Row(
                key: const ValueKey('label'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: Space.xs)],
                  Text(label),
                ],
              ),
      ),
    );
  }
}

/// Asks the user to confirm a destructive or important action.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final c = context.colors;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actionsPadding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(foregroundColor: c.muted),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            minimumSize: const Size(110, 44),
            backgroundColor: destructive ? c.crimson.fg : c.brand,
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
}
