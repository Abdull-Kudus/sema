import 'package:flutter_test/flutter_test.dart';
import 'package:sema/core/utils/validators.dart';
import 'package:sema/features/auth/domain/app_user.dart';

void main() {
  group('ALU email', () {
    test('accepts student and staff domains, any case', () {
      expect(Validators.aluEmail('a.zakariam@alustudent.com'), isNull);
      expect(Validators.aluEmail('J.Doe@ALUEDUCATION.com'), isNull);
    });

    test('rejects other domains and malformed input', () {
      expect(Validators.aluEmail('someone@gmail.com'), isNotNull);
      expect(Validators.aluEmail('a.name@alustudent.com.evil.io'), isNotNull);
      expect(Validators.aluEmail('not-an-email'), isNotNull);
      expect(Validators.aluEmail(''), isNotNull);
    });

    test('role follows the domain', () {
      expect(UserRole.fromEmail('x@alueducation.com'), UserRole.staff);
      expect(UserRole.fromEmail('x@alustudent.com'), UserRole.student);
    });
  });

  group('password', () {
    test('needs 8+ characters mixing letters and digits', () {
      expect(Validators.password('short1'), isNotNull);
      expect(Validators.password('onlyletters'), isNotNull);
      expect(Validators.password('campus2026'), isNull);
    });

    test('strength grows with length and variety', () {
      expect(Validators.passwordStrength('abc'), 0);
      expect(Validators.passwordStrength('Campus2026!xyz'), 4);
    });

    test('confirm compares against the original', () {
      final check = Validators.confirm(() => 'campus2026');
      expect(check('campus2026'), isNull);
      expect(check('campus2025'), isNotNull);
    });
  });

  group('report fields', () {
    test('title length bounds', () {
      expect(Validators.title('Leak'), isNotNull);
      expect(Validators.title('Leaking roof'), isNull);
      expect(Validators.title('x' * 81), isNotNull);
    });

    test('description needs real detail', () {
      expect(Validators.description('broken'), isNotNull);
      expect(Validators.description('The projector in room 204 does not turn on.'), isNull);
    });
  });
}
