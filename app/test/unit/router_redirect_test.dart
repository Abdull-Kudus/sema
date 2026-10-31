import 'package:flutter_test/flutter_test.dart';
import 'package:sema/core/router/app_router.dart';

void main() {
  String? go(String location, {bool loading = false, bool signedIn = false, bool verified = false}) =>
      authRedirect(location: location, loading: loading, signedIn: signedIn, verified: verified);

  test('waits on the splash while the session restores', () {
    expect(go('/home', loading: true), Routes.splash);
    expect(go(Routes.splash, loading: true), isNull);
  });

  test('signed-out users only reach public screens', () {
    expect(go('/home'), Routes.welcome);
    expect(go('/report/abc'), Routes.welcome);
    expect(go(Routes.signIn), isNull);
  });

  test('unverified users are held on verify-email', () {
    expect(go('/home', signedIn: true), Routes.verifyEmail);
    expect(go(Routes.verifyEmail, signedIn: true), isNull);
  });

  test('verified users skip the auth flow', () {
    expect(go(Routes.signIn, signedIn: true, verified: true), Routes.home);
    expect(go(Routes.verifyEmail, signedIn: true, verified: true), Routes.home);
    expect(go('/reports', signedIn: true, verified: true), isNull);
  });
}
