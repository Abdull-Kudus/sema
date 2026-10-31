import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solar_icons/solar_icons.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/feedback.dart';
import '../application/auth_providers.dart';
import 'auth_widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    // Start each form without the previous screen's error.
    Future.microtask(() => ref.read(authControllerProvider.notifier).reset());
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final ok = await ref.read(authControllerProvider.notifier).sendPasswordReset(_email.text);
    if (ok && mounted) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    return AuthScaffold(
      title: _sent ? 'Check your inbox' : 'Reset password',
      subtitle: _sent
          ? 'If an account exists for ${_email.text.trim()}, a reset link is on its way.'
          : 'Enter your ALU email and we will send you a link to choose a new password.',
      children: [
        if (state.hasError) ErrorBanner(state.error.toString()),
        if (!_sent)
          Form(
            key: _form,
            child: TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.aluEmail,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'ALU email',
                prefixIcon: Icon(SolarIconsOutline.letter),
              ),
            ),
          ),
        const SizedBox(height: Space.lg),
        if (_sent)
          OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Back to sign in'))
        else
          LoadingButton(label: 'Send reset link', loading: state.isLoading, onPressed: _submit),
      ],
    );
  }
}
