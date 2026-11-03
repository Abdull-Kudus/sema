import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sema/features/auth/data/auth_repository.dart';

/// The supervisor portal's role check, run against mock Auth and Firestore.
void main() {
  late FakeFirebaseFirestore db;

  Future<(AuthRepository, MockFirebaseAuth)> signedInAs(
    String email, {
    bool verified = true,
    String? role,
  }) async {
    final auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'u1', email: email, isEmailVerified: verified),
    );
    if (role != null) await db.collection('users').doc('u1').set({'email': email, 'role': role});
    return (AuthRepository(auth, db), auth);
  }

  setUp(() => db = FakeFirebaseFirestore());

  test('staff-domain accounts are let in', () async {
    final (repo, auth) = await signedInAs('desk@alueducation.com');
    await repo.requireStaff();
    expect(auth.currentUser, isNotNull);
  });

  test('a student promoted to staff in the console is let in', () async {
    final (repo, auth) = await signedInAs('a.student@alustudent.com', role: 'staff');
    await repo.requireStaff();
    expect(auth.currentUser, isNotNull);
  });

  test('a regular student is refused and signed out', () async {
    final (repo, auth) = await signedInAs('a.student@alustudent.com', role: 'student');
    await expectLater(repo.requireStaff(), throwsA(isA<AuthFailure>()));
    expect(auth.currentUser, isNull);
  });

  test('an unverified non-staff account is refused even if its profile says staff', () async {
    final (repo, auth) = await signedInAs('a.student@alustudent.com', verified: false, role: 'staff');
    await expectLater(repo.requireStaff(), throwsA(isA<AuthFailure>()));
    expect(auth.currentUser, isNull);
  });
}
