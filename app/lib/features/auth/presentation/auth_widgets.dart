import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:solar_icons/solar_icons.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/sema_colors.dart';
import '../../../core/widgets/sema_logo.dart';

/// Shared layout for the auth forms: back button, logo, title, form.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.showBack = true,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: showBack && context.canPop()
            ? IconButton(icon: const Icon(SolarIconsOutline.altArrowLeft), onPressed: () => context.pop())
            : null,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.xl),
          children: [
            const Align(alignment: Alignment.centerLeft, child: SemaMark(size: 52)).animate().scale(
              duration: Motion.medium,
              curve: Curves.easeOutBack,
              alignment: Alignment.centerLeft,
            ),
            const SizedBox(height: Space.lg),
            Text(title, style: context.text.headlineLarge),
            const SizedBox(height: Space.xs),
            Text(subtitle, style: context.text.bodyLarge?.copyWith(color: context.colors.muted)),
            const SizedBox(height: Space.lg),
            ...children,
          ].animate(interval: Motion.stagger).fadeIn(duration: Motion.medium).slideY(begin: 0.06),
        ),
      ),
    );
  }
}

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.validator,
    this.label = 'Password',
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    this.onChanged,
    this.autofillHints = const [AutofillHints.password],
  });

  final TextEditingController controller;
  final String? Function(String?) validator;
  final String label;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final Iterable<String> autofillHints;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _hidden,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      autofillHints: widget.autofillHints,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(SolarIconsOutline.lockKeyhole),
        suffixIcon: IconButton(
          tooltip: _hidden ? 'Show password' : 'Hide password',
          icon: Icon(_hidden ? SolarIconsOutline.eye : SolarIconsOutline.eyeClosed),
          onPressed: () => setState(() => _hidden = !_hidden),
        ),
      ),
    );
  }
}

/// Four bars that fill as the password gets stronger.
class PasswordStrength extends StatelessWidget {
  const PasswordStrength({super.key, required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (label, tone) = switch (score) {
      0 || 1 => ('Weak', c.crimson),
      2 => ('Fair', c.amber),
      3 => ('Good', c.sky),
      _ => ('Strong', c.emerald),
    };
    return Row(
      children: [
        for (var i = 0; i < 4; i++)
          Expanded(
            child: AnimatedContainer(
              duration: Motion.medium,
              height: 4,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: i < score ? tone.fg : c.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        const SizedBox(width: Space.xs),
        SizedBox(
          width: 48,
          child: Text(label, style: context.text.labelMedium?.copyWith(color: tone.fg)),
        ),
      ],
    );
  }
}

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Space.md),
    child: Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.sm),
          child: Text('or', style: context.text.bodySmall),
        ),
        const Expanded(child: Divider()),
      ],
    ),
  );
}

class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key, required this.onPressed, this.loading = false});

  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: loading ? null : onPressed,
    icon: const Icon(SolarIconsBold.squareAcademicCap),
    label: const Text('Continue with ALU Google account'),
  );
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final tone = context.colors.crimson;
    return Container(
      margin: const EdgeInsets.only(bottom: Space.md),
      padding: const EdgeInsets.all(Space.sm),
      decoration: BoxDecoration(color: tone.bg, borderRadius: Radii.card),
      child: Row(
        children: [
          Icon(SolarIconsBold.dangerCircle, color: tone.fg, size: 20),
          const SizedBox(width: Space.xs),
          Expanded(
            child: Text(message, style: context.text.bodyMedium?.copyWith(color: tone.fg)),
          ),
        ],
      ),
    ).animate().shakeX(hz: 4, amount: 3, duration: Motion.medium);
  }
}
