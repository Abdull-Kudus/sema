import '../config/app_config.dart';

/// Form validators. Each returns an error message, or null when valid.
abstract final class Validators {
  static final _email = RegExp(r'^[\w.+-]+@([\w-]+\.)+[a-zA-Z]{2,}$');

  static bool isAluEmail(String email) {
    final value = email.trim().toLowerCase();
    return AppConfig.allowedDomains.any((d) => value.endsWith('@$d'));
  }

  static String? name(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Enter your full name';
    if (value.length < 3) return 'Name must be at least 3 characters';
    return null;
  }

  static String? aluEmail(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Enter your ALU email';
    if (!_email.hasMatch(value)) return 'Enter a valid email address';
    if (!isAluEmail(value)) {
      return 'Use your @${AppConfig.studentDomain} or @${AppConfig.staffDomain} email';
    }
    return null;
  }

  static String? password(String? v) {
    final value = v ?? '';
    if (value.isEmpty) return 'Enter a password';
    if (value.length < AppConfig.passwordMin) {
      return 'Use at least ${AppConfig.passwordMin} characters';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(value) || !RegExp(r'\d').hasMatch(value)) {
      return 'Mix letters and numbers';
    }
    return null;
  }

  /// Supervisor accounts are created with the ALU staff domain only.
  static String? staffEmail(String? v) {
    final error = aluEmail(v);
    if (error != null) return error;
    if (!v!.trim().toLowerCase().endsWith('@${AppConfig.staffDomain}')) {
      return 'Supervisor accounts use an @${AppConfig.staffDomain} email';
    }
    return null;
  }

  static String? signInPassword(String? v) => (v == null || v.isEmpty) ? 'Enter your password' : null;

  static String? Function(String?) confirm(String Function() original) =>
      (v) => v != original() ? 'Passwords do not match' : null;

  static String? title(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Give the issue a short title';
    if (value.length < AppConfig.titleMin) {
      return 'Title needs at least ${AppConfig.titleMin} characters';
    }
    if (value.length > AppConfig.titleMax) return 'Keep the title under ${AppConfig.titleMax} characters';
    return null;
  }

  static String? description(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Describe what happened';
    if (value.length < AppConfig.descriptionMin) {
      return 'Add a little more detail (${AppConfig.descriptionMin}+ characters)';
    }
    return null;
  }

  static String? required(String? v, String message) => (v == null || v.trim().isEmpty) ? message : null;

  /// 0–4 password strength used by the strength meter.
  static int passwordStrength(String v) {
    var score = 0;
    if (v.length >= AppConfig.passwordMin) score++;
    if (v.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(v) && RegExp(r'[a-z]').hasMatch(v)) score++;
    if (RegExp(r'\d').hasMatch(v) && RegExp(r'[^A-Za-z0-9]').hasMatch(v)) score++;
    return score;
  }
}
