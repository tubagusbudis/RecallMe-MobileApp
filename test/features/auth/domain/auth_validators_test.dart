import 'package:flutter_test/flutter_test.dart';
import 'package:recallme/features/auth/domain/auth_validators.dart';

void main() {
  group('AuthValidators', () {
    group('validateEmail', () {
      test('rejects empty or whitespace email', () {
        expect(AuthValidators.validateEmail(''), 'Email tidak boleh kosong');
        expect(AuthValidators.validateEmail('   '), 'Email tidak boleh kosong');
      });

      test('rejects invalid email formats', () {
        expect(
          AuthValidators.validateEmail('plainaddress'),
          'Format email tidak valid',
        );
        expect(
          AuthValidators.validateEmail(r'#@%^%#$@#$@#.com'),
          'Format email tidak valid',
        );
        expect(
          AuthValidators.validateEmail('@example.com'),
          'Format email tidak valid',
        );
        expect(
          AuthValidators.validateEmail('user@'),
          'Format email tidak valid',
        );
        expect(
          AuthValidators.validateEmail('user@example'),
          'Format email tidak valid',
        );
        expect(
          AuthValidators.validateEmail('user with spaces@example.com'),
          'Format email tidak valid',
        );
      });

      test('accepts valid email formats', () {
        expect(AuthValidators.validateEmail('user@example.com'), isNull);
        expect(
          AuthValidators.validateEmail('raka.belajar@gmail.co.id'),
          isNull,
        );
        expect(
          AuthValidators.validateEmail('siswa_123+tag@sekolah.sch.id'),
          isNull,
        );
      });
    });

    group('validateOtp', () {
      test('rejects empty or whitespace OTP', () {
        expect(AuthValidators.validateOtp(''), 'Kode OTP tidak boleh kosong');
        expect(
          AuthValidators.validateOtp('   '),
          'Kode OTP tidak boleh kosong',
        );
      });

      test('rejects OTP with non-digits or not 8 digits', () {
        expect(
          AuthValidators.validateOtp('1234567'),
          'Kode OTP harus berupa 8 digit angka',
        );
        expect(
          AuthValidators.validateOtp('123456789'),
          'Kode OTP harus berupa 8 digit angka',
        );
        expect(
          AuthValidators.validateOtp('1234567a'),
          'Kode OTP harus berupa 8 digit angka',
        );
        expect(
          AuthValidators.validateOtp('abcdefgh'),
          'Kode OTP harus berupa 8 digit angka',
        );
      });

      test('accepts valid 8-digit OTP', () {
        expect(AuthValidators.validateOtp('12345678'), isNull);
        expect(AuthValidators.validateOtp('00000000'), isNull);
        expect(AuthValidators.validateOtp('98765432'), isNull);
      });
    });

    group('toInternalAuthEmail', () {
      test('maps username to lowercase internal email', () {
        expect(
          AuthValidators.toInternalAuthEmail('Raka_Belajar'),
          'raka_belajar@recallme.internal',
        );
        expect(
          AuthValidators.toInternalAuthEmail('  User123  '),
          'user123@recallme.internal',
        );
      });
    });

    group('extractUsernameFromEmail', () {
      test('extracts clean username from internal or normal email', () {
        expect(
          AuthValidators.extractUsernameFromEmail(
            'raka_belajar@recallme.internal',
          ),
          'raka_belajar',
        );
        expect(
          AuthValidators.extractUsernameFromEmail('budi.santoso@gmail.com'),
          'budi.santoso',
        );
      });
    });

    group('validateUsername', () {
      test('rejects empty or whitespace', () {
        expect(AuthValidators.validateUsername(''), isNotNull);
        expect(AuthValidators.validateUsername('   '), isNotNull);
      });

      test('rejects username shorter than 3 or longer than 30 chars', () {
        expect(AuthValidators.validateUsername('ab'), isNotNull);
        expect(
          AuthValidators.validateUsername('a' * 31),
          'Username harus 3–30 karakter',
        );
      });

      test('rejects invalid characters (spaces, symbols, punctuation)', () {
        expect(AuthValidators.validateUsername('raka belajar'), isNotNull);
        expect(AuthValidators.validateUsername('raka@123'), isNotNull);
        expect(AuthValidators.validateUsername('user!name'), isNotNull);
      });

      test('accepts valid usernames (letters, digits, underscore)', () {
        expect(AuthValidators.validateUsername('raka_belajar'), isNull);
        expect(AuthValidators.validateUsername('user123'), isNull);
        expect(AuthValidators.validateUsername('ABC_123'), isNull);
      });
    });

    group('validatePassword', () {
      test('rejects password shorter than 8 characters', () {
        expect(
          AuthValidators.validatePassword('Pass1!'),
          'Password minimal 8 karakter',
        );
      });

      test('rejects password missing letters', () {
        expect(
          AuthValidators.validatePassword('12345678!'),
          'Kombinasi huruf, angka, dan simbol (!@#\$%^&*) diperlukan',
        );
      });

      test('rejects password missing numbers', () {
        expect(
          AuthValidators.validatePassword('Password!'),
          'Kombinasi huruf, angka, dan simbol (!@#\$%^&*) diperlukan',
        );
      });

      test('rejects password missing symbols', () {
        expect(
          AuthValidators.validatePassword('Password123'),
          'Kombinasi huruf, angka, dan simbol (!@#\$%^&*) diperlukan',
        );
      });

      test('accepts valid password meeting all criteria', () {
        expect(AuthValidators.validatePassword('RecallMe123!'), isNull);
        expect(AuthValidators.validatePassword('Belajar#2026'), isNull);
        expect(AuthValidators.validatePassword('Super\$ecure9'), isNull);
      });
    });
  });
}
