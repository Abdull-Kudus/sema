import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:solar_icons/solar_icons.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/sema_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/feedback.dart';
import '../application/auth_providers.dart';
import 'auth_widgets.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Start each form without the previous screen's error.
    Future.microtask(() => ref.read(authControllerProvider.notifier).reset());
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    await ref.read(authControllerProvider.notifier).signIn(_email.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in with your ALU email to report and track campus issues.',
      children: [
        if (state.hasError) ErrorBanner(state.error.toString()),
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              children: [
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.aluEmail,
                  decoration: const InputDecoration(
                    labelText: 'ALU email',
                    hintText: 'a.name@alustudent.com',
                    prefixIcon: Icon(SolarIconsOutline.letter),
                  ),
                ),
                const SizedBox(height: Space.md),
                PasswordField(
                  controller: _password,
                  validator: Validators.signInPassword,
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.push('/forgot-password'),
            child: const Text('Forgot password?'),
          ),
        ),
        const SizedBox(height: Space.xs),
        LoadingButton(label: 'Sign in', loading: state.isLoading, onPressed: _submit),
        const OrDivider(),
        GoogleButton(
          loading: state.isLoading,
          onPressed: () => ref.read(authControllerProvider.notifier).signInWithGoogle(),
        ),
        const SizedBox(height: Space.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('New to Sema?', style: context.text.bodyMedium?.copyWith(color: context.colors.muted)),
            TextButton(
              onPressed: () => context.pushReplacement('/sign-up'),
              child: const Text('Create an account'),
            ),
          ],
        ),
      ],
    );
  }
}
