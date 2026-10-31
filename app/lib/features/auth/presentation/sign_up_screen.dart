import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:solar_icons/solar_icons.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/sema_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/feedback.dart';
import '../application/auth_providers.dart';
import '../domain/app_user.dart';
import 'auth_widgets.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  int _strength = 0;

  @override
  void initState() {
    super.initState();
    // Start each form without the previous screen's error.
    Future.microtask(() => ref.read(authControllerProvider.notifier).reset());
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    await ref.read(authControllerProvider.notifier).register(_name.text, _email.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final c = context.colors;
    return AuthScaffold(
      title: 'Join Sema',
      subtitle: 'Use your ALU email. We will send a link to confirm it is really you.',
      children: [
        if (state.hasError) ErrorBanner(state.error.toString()),
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  validator: Validators.name,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(SolarIconsOutline.user),
                  ),
                ),
                const SizedBox(height: Space.md),
                ValueListenableBuilder(
                  valueListenable: _email,
                  builder: (context, value, _) {
                    final valid = Validators.aluEmail(value.text) == null;
                    final role = UserRole.fromEmail(value.text);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          validator: Validators.aluEmail,
                          decoration: InputDecoration(
                            labelText: 'ALU email',
                            hintText: 'a.name@${AppConfig.studentDomain}',
                            prefixIcon: const Icon(SolarIconsOutline.letter),
                            suffixIcon: valid
                                ? Icon(SolarIconsBold.verifiedCheck, color: c.emerald.fg)
                                : null,
                          ),
                        ),
                        if (valid) ...[
                          const SizedBox(height: Space.xs),
                          TonePill(
                            label: 'Joining as ${role.label.toLowerCase()}',
                            tone: role == UserRole.staff ? c.violet : c.sky,
                            icon: role == UserRole.staff
                                ? SolarIconsBold.shieldUser
                                : SolarIconsBold.squareAcademicCap,
                            dense: true,
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: Space.md),
                PasswordField(
                  controller: _password,
                  validator: Validators.password,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  onChanged: (v) => setState(() => _strength = Validators.passwordStrength(v)),
                ),
                const SizedBox(height: Space.xs),
                PasswordStrength(score: _strength),
                const SizedBox(height: Space.md),
                PasswordField(
                  controller: _confirm,
                  label: 'Confirm password',
                  validator: Validators.confirm(() => _password.text),
                  autofillHints: const [AutofillHints.newPassword],
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Space.lg),
        LoadingButton(label: 'Create account', loading: state.isLoading, onPressed: _submit),
        const SizedBox(height: Space.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Already joined?', style: context.text.bodyMedium?.copyWith(color: c.muted)),
            TextButton(onPressed: () => context.pushReplacement('/sign-in'), child: const Text('Sign in')),
          ],
        ),
      ],
    );
  }
}
