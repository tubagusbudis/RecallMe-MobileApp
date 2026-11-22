import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recallme/features/auth/application/auth_controller.dart';
import 'package:recallme/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('AuthController', () {
    test('initializes with mock user when Supabase is not configured', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(authControllerProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.user?.username, 'raka_belajar');
    });

    test('login fails when username is invalid', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      final result = await controller.login('ab', 'RecallMe123!');

      expect(result, isFalse);
      expect(container.read(authControllerProvider).errorMessage, isNotNull);
    });

    test('login fails when password is empty', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      final result = await controller.login('raka_belajar', '');

      expect(result, isFalse);
      expect(
        container.read(authControllerProvider).errorMessage,
        'Password tidak boleh kosong',
      );
    });

    test('login succeeds with valid username and password', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      final result = await controller.login('budi_santoso', 'RecallMe123!');

      expect(result, isTrue);
      final state = container.read(authControllerProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.user?.username, 'budi_santoso');
    });

    test('register fails when password does not meet criteria', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      final result = await controller.register('budi_santoso', 'weakpass');

      expect(result, isFalse);
      expect(container.read(authControllerProvider).errorMessage, isNotNull);
    });

    test('register succeeds with valid credentials', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      final result = await controller.register(
        'budi_santoso',
        'RecallMe123!',
        displayName: 'Budi Santoso',
      );

      expect(result, isTrue);
      final state = container.read(authControllerProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.user?.username, 'budi_santoso');
      expect(state.user?.displayName, 'Budi Santoso');
    });

    test('logout resets auth state to unauthenticated', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      await controller.logout();

      final state = container.read(authControllerProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.user, isNull);
    });

    test('clearError resets errorMessage', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      await controller.login('ab', 'pass');
      expect(container.read(authControllerProvider).errorMessage, isNotNull);

      controller.clearError();
      expect(container.read(authControllerProvider).errorMessage, isNull);
    });
  });

  group('SupabaseAuthRepository error mapping', () {
    test('maps common auth errors to clear user-facing messages', () {
      expect(
        SupabaseAuthRepository.mapAuthError(
          const AuthException('User already registered'),
        ),
        contains('Username sudah terdaftar'),
      );
      expect(
        SupabaseAuthRepository.mapAuthError(
          const AuthException('Invalid login credentials'),
        ),
        'Username atau password salah.',
      );
      expect(
        SupabaseAuthRepository.mapAuthError(
          const AuthException('Password should be at least 8 characters'),
        ),
        'Password minimal 8 karakter.',
      );
      expect(
        SupabaseAuthRepository.mapAuthError(
          Exception('Failed host lookup: network is down'),
        ),
        contains('Gagal terhubung ke server'),
      );
    });
  });
}
