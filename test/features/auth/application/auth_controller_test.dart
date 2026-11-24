import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recallme/features/auth/application/auth_controller.dart';
import 'package:recallme/features/auth/data/auth_repository.dart';
import 'package:recallme/features/decks/application/deck_controller.dart';
import 'package:recallme/features/decks/domain/deck_model.dart';
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

    test('login fails when email is invalid', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      final result = await controller.login('not-an-email', 'RecallMe123!');

      expect(result, isFalse);
      expect(
        container.read(authControllerProvider).errorMessage,
        'Format email tidak valid',
      );
    });

    test('login fails when password is empty', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      final result = await controller.login('raka@example.com', '');

      expect(result, isFalse);
      expect(
        container.read(authControllerProvider).errorMessage,
        'Password tidak boleh kosong',
      );
    });

    test('login succeeds with valid email and password', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      final result = await controller.login(
        'budi.santoso@example.com',
        'RecallMe123!',
      );

      expect(result, isTrue);
      final state = container.read(authControllerProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.user?.username, 'budi.santoso');
    });

    test('register fails when username is invalid', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      final result = await controller.register(
        'ab',
        'budi@example.com',
        'RecallMe123!',
      );

      expect(result, isFalse);
      expect(
        container.read(authControllerProvider).errorMessage,
        'Username harus 3–30 karakter',
      );
    });

    test('register fails when email is invalid', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      final result = await controller.register(
        'budi_santoso',
        'invalid-email',
        'RecallMe123!',
      );

      expect(result, isFalse);
      expect(
        container.read(authControllerProvider).errorMessage,
        'Format email tidak valid',
      );
    });

    test('register fails when password does not meet criteria', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      final result = await controller.register(
        'budi_santoso',
        'budi@example.com',
        'weakpass',
      );

      expect(result, isFalse);
      expect(container.read(authControllerProvider).errorMessage, isNotNull);
    });

    test('register succeeds with valid credentials', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      final result = await controller.register(
        'budi_santoso',
        'budi@example.com',
        'RecallMe123!',
        displayName: 'Budi Santoso',
      );

      expect(result, isTrue);
      final state = container.read(authControllerProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.user?.username, 'budi_santoso');
      expect(state.user?.displayName, 'Budi Santoso');
      expect(state.user?.email, 'budi@example.com');
    });

    test('sendPasswordResetOtp fails with invalid email', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      final result = await controller.sendPasswordResetOtp('invalid');

      expect(result, isFalse);
      expect(
        container.read(authControllerProvider).errorMessage,
        'Format email tidak valid',
      );
    });

    test('sendPasswordResetOtp succeeds with valid email', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      final result = await controller.sendPasswordResetOtp('user@example.com');

      expect(result, isTrue);
      expect(container.read(authControllerProvider).errorMessage, isNull);
    });

    test('verifyPasswordResetOtp fails with invalid OTP', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      final result = await controller.verifyPasswordResetOtp(
        email: 'user@example.com',
        token: '123',
      );

      expect(result, isFalse);
      expect(
        container.read(authControllerProvider).errorMessage,
        'Kode OTP harus berupa 8 digit angka',
      );
    });

    test('verifyPasswordResetOtp succeeds with valid 8-digit OTP', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      final result = await controller.verifyPasswordResetOtp(
        email: 'user@example.com',
        token: '12345678',
      );

      expect(result, isTrue);
      expect(container.read(authControllerProvider).errorMessage, isNull);
      expect(container.read(authControllerProvider).isAuthenticated, isTrue);
    });

    test('updatePassword fails with weak password', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      final result = await controller.updatePassword('weak');

      expect(result, isFalse);
      expect(container.read(authControllerProvider).errorMessage, isNotNull);
    });

    test('updatePassword succeeds with valid complex password', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      final result = await controller.updatePassword('NewSecret#2026');

      expect(result, isTrue);
      expect(container.read(authControllerProvider).errorMessage, isNull);
    });

    test('completePasswordRecovery updates password, signs out session, and clears recovery state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      // Put into recovery state
      await controller.verifyPasswordResetOtp(
        email: 'user@example.com',
        token: '12345678',
      );
      expect(container.read(authControllerProvider).isPasswordRecovery, isTrue);
      expect(container.read(authControllerProvider).isAuthenticated, isTrue);

      // Complete recovery
      final success = await controller.completePasswordRecovery(
        'NewSecret#2026',
      );
      expect(success, isTrue);

      final state = container.read(authControllerProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.user, isNull);
      expect(state.isPasswordRecovery, isFalse);

      final repo = container.read(authRepositoryProvider);
      expect(repo.currentUser, isNull);
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

    test('completePasswordRecovery does not throw CircularDependencyError when DeckController is active', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Keep DeckController actively listened to as a mounted UI screen would
      final sub = container.listen(deckControllerProvider, (_, _) {});
      addTearDown(sub.close);

      final initialDecks = await container.read(deckControllerProvider.future);
      expect(initialDecks, isA<List<DeckModel>>());
      expect(initialDecks, isNotEmpty);

      final controller = container.read(authControllerProvider.notifier);
      // Put into recovery state
      await controller.verifyPasswordResetOtp(
        email: 'user@example.com',
        token: '12345678',
      );
      expect(container.read(authControllerProvider).isPasswordRecovery, isTrue);

      // Complete recovery - must not throw CircularDependencyError
      final success = await controller.completePasswordRecovery(
        'NewSecret#2026',
      );
      expect(success, isTrue);

      final state = container.read(authControllerProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.user, isNull);
      expect(state.isPasswordRecovery, isFalse);

      // DeckController should reactively return empty list without circular dependency
      final updatedDecks = await container.read(deckControllerProvider.future);
      expect(updatedDecks, isEmpty);
    });

    test('logout does not throw CircularDependencyError when DeckController is active', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Keep DeckController actively listened to as a mounted UI screen would
      final sub = container.listen(deckControllerProvider, (_, _) {});
      addTearDown(sub.close);

      final initialDecks = await container.read(deckControllerProvider.future);
      expect(initialDecks, isNotEmpty);

      final controller = container.read(authControllerProvider.notifier);
      await expectLater(controller.logout(), completes);

      final state = container.read(authControllerProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.user, isNull);

      // DeckController should reactively return empty list without circular dependency
      final updatedDecks = await container.read(deckControllerProvider.future);
      expect(updatedDecks, isEmpty);
    });

    test('clearError resets errorMessage', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      await controller.login('invalid', 'pass');
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
        contains('Email atau username sudah terdaftar'),
      );
      expect(
        SupabaseAuthRepository.mapAuthError(
          const AuthException('Invalid login credentials'),
        ),
        'Email atau password salah.',
      );
      expect(
        SupabaseAuthRepository.mapAuthError(
          const AuthException('Password should be at least 8 characters'),
        ),
        'Password minimal 8 karakter.',
      );
      expect(
        SupabaseAuthRepository.mapAuthError(
          const AuthException(
            'For security purposes, you can only request this once every 60 seconds (rate limit)',
          ),
        ),
        contains('Terlalu banyak permintaan'),
      );
      expect(
        SupabaseAuthRepository.mapAuthError(
          const AuthException('Token has expired or is invalid'),
        ),
        'Kode OTP tidak valid atau sudah kedaluwarsa.',
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
