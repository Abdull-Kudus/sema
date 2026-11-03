import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/app_user.dart';

/// The Firebase user, re-emitted on verification and profile changes.
final authUserProvider = StreamProvider<User?>((ref) => ref.watch(authRepositoryProvider).userChanges());

/// The signed-in user's Firestore profile (role, name, photo).
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final user = ref.watch(authUserProvider).value;
  if (user == null || !user.emailVerified) return Stream.value(null);
  final repo = ref.watch(authRepositoryProvider);
  // First arrival after verification: create the profile, the stream then re-emits it.
  return repo.watchProfile(user.uid).asyncMap((profile) async {
    if (profile == null) await repo.ensureProfile();
    return profile;
  });
});

final isStaffProvider = Provider<bool>((ref) => ref.watch(currentUserProvider).value?.isStaff ?? false);

/// Runs auth actions and exposes their loading / error state to the forms.
class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }

  /// Clears a stale error when a new form opens.
  void reset() => state = const AsyncData(null);

  Future<bool> signIn(String email, String password) =>
      _run(() => ref.read(authRepositoryProvider).signIn(email: email, password: password));

  Future<bool> register(String name, String email, String password) =>
      _run(() => ref.read(authRepositoryProvider).register(name: name, email: email, password: password));

  Future<bool> signInWithGoogle() => _run(() => ref.read(authRepositoryProvider).signInWithGoogle());

  /// Supervisor portal sign-in: authenticates, then refuses non-staff accounts.
  Future<bool> signInAsSupervisor(String email, String password) =>
      _supervisor(() => ref.read(authRepositoryProvider).signIn(email: email, password: password));

  Future<bool> signInWithGoogleAsSupervisor() =>
      _supervisor(() => ref.read(authRepositoryProvider).signInWithGoogle());

  /// Holds routing on the portal until the role check is done, so a refused
  /// account never flashes the home screen.
  Future<bool> _supervisor(Future<void> Function() signIn) async {
    final hold = ref.read(authHoldProvider.notifier)..set(true);
    try {
      return await _run(() async {
        await signIn();
        await ref.read(authRepositoryProvider).requireStaff();
      });
    } finally {
      hold.set(false);
    }
  }

  Future<bool> sendPasswordReset(String email) =>
      _run(() => ref.read(authRepositoryProvider).sendPasswordReset(email));

  Future<bool> resendVerification() => _run(() => ref.read(authRepositoryProvider).sendVerificationEmail());

  Future<void> signOut() => _run(() => ref.read(authRepositoryProvider).signOut());
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(AuthController.new);

/// True while a sign-in is still being checked; the router stays put meanwhile.
class AuthHold extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final authHoldProvider = NotifierProvider<AuthHold, bool>(AuthHold.new);
