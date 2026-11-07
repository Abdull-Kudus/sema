import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:solar_icons/solar_icons.dart';

import '../../../core/config/app_config.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/sema_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/feedback.dart';
import '../application/auth_providers.dart';
import 'auth_widgets.dart';

/// Student sign-in, or the supervisor portal when [supervisor] is true.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key, this.supervisor = false});

  final bool supervisor;

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
    final auth = ref.read(authControllerProvider.notifier);
    widget.supervisor
        ? await auth.signInAsSupervisor(_email.text, _password.text)
        : await auth.signIn(_email.text, _password.text);
    // Lets Android offer to save the login, so it can be picked next time.
    if (mounted && !ref.read(authControllerProvider).hasError) TextInput.finishAutofillContext();
  }

  void _google() {
    final auth = ref.read(authControllerProvider.notifier);
    widget.supervisor ? auth.signInWithGoogleAsSupervisor() : auth.signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final c = context.colors;
    final supervisor = widget.supervisor;
    return AuthScaffold(
      title: supervisor ? 'Supervisor sign in' : 'Welcome back',
      subtitle: supervisor
          ? 'Review campus reports, update their status and keep students informed.'
          : 'Sign in with your ALU email to report and track campus issues.',
      children: [
        if (supervisor) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: TonePill(label: 'Supervisor portal', tone: c.azure, icon: SolarIconsBold.shieldUser),
          ),
          const SizedBox(height: Space.md),
        ],
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
                  decoration: InputDecoration(
                    labelText: supervisor ? 'Staff email' : 'ALU email',
                    hintText: 'a.name@${supervisor ? AppConfig.staffDomain : AppConfig.studentDomain}',
                    prefixIcon: const Icon(SolarIconsOutline.letter),
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
        LoadingButton(
          label: supervisor ? 'Open supervisor portal' : 'Sign in',
          loading: state.isLoading,
          onPressed: _submit,
        ),
        const OrDivider(),
        GoogleButton(loading: state.isLoading, onPressed: _google),
        const SizedBox(height: Space.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              supervisor ? 'New supervisor?' : 'New to Sema?',
              style: context.text.bodyMedium?.copyWith(color: c.muted),
            ),
            TextButton(
              onPressed: () => context.pushReplacement(supervisor ? Routes.supervisorSignUp : Routes.signUp),
              child: Text(supervisor ? 'Request staff account' : 'Create an account'),
            ),
          ],
        ),
        if (supervisor)
          Center(
            child: TextButton(
              onPressed: () => context.pushReplacement(Routes.signIn),
              style: TextButton.styleFrom(foregroundColor: c.muted),
              child: const Text('Student? Sign in here'),
            ),
          ),
      ],
    );
  }
}
