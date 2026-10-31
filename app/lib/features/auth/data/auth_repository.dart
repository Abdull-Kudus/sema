import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/app_config.dart';
import '../../../core/utils/validators.dart';
import '../domain/app_user.dart';

/// A readable error for the UI.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;

  factory AuthFailure.from(FirebaseAuthException e) => AuthFailure(switch (e.code) {
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'That email and password do not match an account.',
    'email-already-in-use' => 'An account already exists for this email. Try signing in.',
    'weak-password' => 'Choose a stronger password.',
    'invalid-email' => 'That email address is not valid.',
    'too-many-requests' => 'Too many attempts. Wait a moment and try again.',
    'network-request-failed' => 'No connection. Check your internet and try again.',
    'user-disabled' => 'This account has been disabled. Contact campus IT.',
    _ => e.message ?? 'Something went wrong. Please try again.',
  });
}

class AuthRepository {
  AuthRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  bool _googleReady = false;

  /// Emits on sign-in, sign-out and profile changes such as email verification.
  Stream<User?> userChanges() => _auth.userChanges();

  User? get currentUser => _auth.currentUser;

  DocumentReference<Map<String, dynamic>> _profile(String uid) => _db.collection(Collections.users).doc(uid);

  Stream<AppUser?> watchProfile(String uid) =>
      _profile(uid).snapshots().map((doc) => doc.exists ? AppUser.fromDoc(doc) : null);

  Future<void> signIn({required String email, required String password}) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      await _ensureProfile(cred.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.from(e);
    }
  }

  Future<void> register({required String name, required String email, required String password}) async {
    if (!Validators.isAluEmail(email)) {
      throw const AuthFailure('Only ALU email addresses can join Sema.');
    }
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      final user = cred.user!;
      await user.updateDisplayName(name.trim());
      await user.sendEmailVerification();
      await user.reload();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.from(e);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final google = GoogleSignIn.instance;
      if (!_googleReady) {
        await google.initialize();
        _googleReady = true;
      }
      final account = await google.authenticate();
      if (!Validators.isAluEmail(account.email)) {
        await google.signOut();
        throw const AuthFailure('Use your ALU Google account (@alustudent.com or @alueducation.com).');
      }
      final idToken = account.authentication.idToken;
      final cred = await _auth.signInWithCredential(GoogleAuthProvider.credential(idToken: idToken));
      await _ensureProfile(cred.user!);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthFailure('Google sign-in was cancelled.');
      }
      throw AuthFailure(e.description ?? 'Google sign-in failed.');
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.from(e);
    }
  }

  Future<void> sendVerificationEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.from(e);
    }
  }

  /// Reloads the user; returns true once the email is verified.
  Future<bool> refreshVerification() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    final fresh = _auth.currentUser!;
    if (fresh.emailVerified) {
      // The ID token must carry email_verified=true for the security rules.
      await fresh.getIdToken(true);
      await _ensureProfile(fresh);
    }
    return fresh.emailVerified;
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.from(e);
    }
  }

  Future<void> signOut() async {
    if (_googleReady) await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }

  /// Creates the Firestore profile the first time a verified user arrives.
  Future<void> _ensureProfile(User user) async {
    if (!user.emailVerified || !Validators.isAluEmail(user.email ?? '')) return;
    final ref = _profile(user.uid);
    final snap = await ref.get();
    if (snap.exists) return;
    final email = user.email!.toLowerCase();
    await ref.set({
      'name': user.displayName ?? email.split('@').first,
      'email': email,
      'role': UserRole.fromEmail(email).name,
      'photoUrl': user.photoURL,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> ensureProfile() async {
    final user = _auth.currentUser;
    if (user != null) await _ensureProfile(user);
  }

  Future<void> updateProfile(String uid, {String? name, String? photoUrl}) async {
    await _profile(uid)
        .update({'name': ?name, 'photoUrl': ?photoUrl, 'updatedAt': FieldValue.serverTimestamp()});
    if (name != null) await _auth.currentUser?.updateDisplayName(name);
    if (photoUrl != null) await _auth.currentUser?.updatePhotoURL(photoUrl);
  }
}
