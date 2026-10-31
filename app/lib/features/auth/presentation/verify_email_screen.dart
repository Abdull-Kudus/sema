import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solar_icons/solar_icons.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/sema_colors.dart';
import '../../../core/widgets/feedback.dart';
import '../application/auth_providers.dart';

/// Blocks the app until the ALU email is verified. Polls in the background so
/// the user is let in as soon as they tap the link in their inbox.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  Timer? _poll;
  Timer? _cooldown;
  int _secondsLeft = AppConfig.resendCooldown.inSeconds;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(AppConfig.verifyPollInterval, (_) => _check());
    _startCooldown();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _cooldown?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldown?.cancel();
    setState(() => _secondsLeft = AppConfig.resendCooldown.inSeconds);
    _cooldown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) t.cancel();
      setState(() => _secondsLeft--);
    });
  }

  Future<void> _check() async {
    try {
      // The router redirects into the app once userChanges() reports verification.
      await ref.read(authRepositoryProvider).refreshVerification();
    } catch (_) {
      // Network blips are retried on the next tick.
    }
  }

  Future<void> _resend() async {
    final ok = await ref.read(authControllerProvider.notifier).resendVerification();
    if (!mounted) return;
    Toast.show(context, ok ? 'Verification email sent' : 'Could not send. Try again shortly.', error: !ok);
    if (ok) _startCooldown();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final email = ref.watch(authUserProvider).value?.email ?? '';
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Space.gutter),
          child: Column(
            children: [
              const Spacer(),
              Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(shape: BoxShape.circle, gradient: c.hero),
                    child: Icon(SolarIconsBold.letterUnread, size: 52, color: c.onBrand),
                  )
                  .animate(onPlay: (a) => a.repeat(reverse: true))
                  .moveY(begin: -4, end: 4, duration: 1600.ms, curve: Curves.easeInOut),
              const SizedBox(height: Space.lg),
              Text('Verify your ALU email', style: context.text.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: Space.xs),
              Text.rich(
                TextSpan(
                  text: 'We sent a link to ',
                  children: [
                    TextSpan(
                      text: email,
                      style: TextStyle(color: c.text, fontWeight: FontWeight.w600),
                    ),
                    const TextSpan(text: '. Open it on any device and this screen continues on its own.'),
                  ],
                ),
                textAlign: TextAlign.center,
                style: context.text.bodyLarge?.copyWith(color: c.muted),
              ),
              const SizedBox(height: Space.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox.square(
                    dimension: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: c.brand),
                  ),
                  const SizedBox(width: Space.xs),
                  Text('Waiting for verification…', style: context.text.bodySmall),
                ],
              ),
              const Spacer(),
              FilledButton(onPressed: _check, child: const Text('I have verified')),
              const SizedBox(height: Space.sm),
              OutlinedButton(
                onPressed: _secondsLeft > 0 ? null : _resend,
                child: Text(_secondsLeft > 0 ? 'Resend in ${_secondsLeft}s' : 'Resend email'),
              ),
              TextButton(
                onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                child: const Text('Use a different account'),
              ),
              Text('Tip: check your spam or “Other” folder.', style: context.text.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
