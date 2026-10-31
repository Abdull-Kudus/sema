import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:solar_icons/solar_icons.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/reports/application/report_providers.dart';
import '../../features/reports/domain/report.dart';
import '../../features/reports/presentation/report_detail_screen.dart';
import '../../features/reports/presentation/report_form_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/shell/app_shell.dart';
import '../widgets/feedback.dart';
import 'splash_screen.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const forgotPassword = '/forgot-password';
  static const verifyEmail = '/verify-email';
  static const home = '/home';

  static const public = {welcome, signIn, signUp, forgotPassword};
}

final _rootKey = GlobalKey<NavigatorState>();

/// Decides where the user may be, from their auth and verification state.
/// Kept pure so it is unit-tested without a widget tree.
String? authRedirect({
  required String location,
  required bool loading,
  required bool signedIn,
  required bool verified,
}) {
  if (loading) return location == Routes.splash ? null : Routes.splash;
  if (!signedIn) return Routes.public.contains(location) ? null : Routes.welcome;
  if (!verified) return location == Routes.verifyEmail ? null : Routes.verifyEmail;
  final inAuthFlow =
      Routes.public.contains(location) || location == Routes.verifyEmail || location == Routes.splash;
  return inAuthFlow ? Routes.home : null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(authUserProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authUserProvider);
      final user = auth.value;
      return authRedirect(
        location: state.matchedLocation,
        loading: !auth.hasValue,
        signedIn: user != null,
        verified: user?.emailVerified ?? false,
      );
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.welcome, builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: Routes.signIn, builder: (_, _) => const SignInScreen()),
      GoRoute(path: Routes.signUp, builder: (_, _) => const SignUpScreen()),
      GoRoute(path: Routes.forgotPassword, builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(path: Routes.verifyEmail, builder: (_, _) => const VerifyEmailScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/reports', builder: (_, _) => const ReportsScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/alerts', builder: (_, _) => const NotificationsScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen())],
          ),
        ],
      ),
      GoRoute(
        path: '/report/new',
        parentNavigatorKey: _rootKey,
        pageBuilder: (_, _) => const MaterialPage(fullscreenDialog: true, child: ReportFormScreen()),
      ),
      GoRoute(
        path: '/report/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => ReportDetailScreen(id: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'edit',
            parentNavigatorKey: _rootKey,
            builder: (_, state) => _EditGuard(
              id: state.pathParameters['id']!,
              initial: state.extra is Report ? state.extra! as Report : null,
            ),
          ),
        ],
      ),
    ],
  );
});

/// Only the owner may edit, and only while the report is still "submitted".
class _EditGuard extends ConsumerWidget {
  const _EditGuard({required this.id, this.initial});

  final String id;
  final Report? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = initial ?? ref.watch(reportProvider(id)).value;
    final uid = ref.watch(currentUserProvider).value?.uid;
    if (report == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!report.canEditBy(uid)) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: SolarIconsBold.lockKeyhole,
          title: 'Editing is closed',
          message: 'Reports can only be edited by their author until staff start working on them.',
        ),
      );
    }
    return ReportFormScreen(existing: report);
  }
}
