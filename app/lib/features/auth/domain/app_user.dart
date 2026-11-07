import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/config/app_config.dart';

enum UserRole {
  student('Student'),
  staff('Supervisor');

  const UserRole(this.label);

  final String label;

  /// Staff accounts are recognised by the ALU staff email domain.
  static UserRole fromEmail(String email) =>
      email.toLowerCase().endsWith('@${AppConfig.staffDomain}') ? staff : student;

  static UserRole parse(String? v) => v == 'staff' ? staff : student;
}

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.photoUrl,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? photoUrl;

  bool get isStaff => role == UserRole.staff;

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    final email = d['email'] as String? ?? '';
    return AppUser(
      uid: doc.id,
      name: d['name'] as String? ?? '',
      email: email,
      // Domain wins for staff so a staff account works before its profile syncs.
      role: UserRole.fromEmail(email) == UserRole.staff
          ? UserRole.staff
          : UserRole.parse(d['role'] as String?),
      photoUrl: d['photoUrl'] as String?,
    );
  }
}
