import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../domain/auth_validators.dart';
import '../domain/user_model.dart';

/// Contract for Authentication repository in RecallMe.
abstract class AuthRepository {
  /// Stream of user auth state changes.
  Stream<UserModel?> get authStateChanges;

  /// Currently authenticated user, or null if unauthenticated.
  UserModel? get currentUser;

  /// Registers a new user with real email, password, and username.
  /// Metadata `username` and `display_name` are sent to trigger DB `handle_new_user()`.
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String username,
    String? displayName,
  });

  /// Signs in using real email and password.
  Future<UserModel> signInWithPassword({
    required String email,
    required String password,
  });

  /// Sends an 8-digit OTP code to the user's email for password reset.
  Future<void> sendPasswordResetOtp(String email);

  /// Verifies the 8-digit OTP code using recovery type.
  Future<void> verifyPasswordResetOtp({
    required String email,
    required String token,
  });

  /// Updates the user's password once verified/authenticated.
  Future<void> updatePassword(String newPassword);

  /// Signs out the current user session.
  Future<void> signOut();

  /// Maps errors/exceptions into user-friendly localized messages.
  String mapError(Object error);
}

/// Supabase Auth implementation of [AuthRepository].
class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;
  final _authStateController = StreamController<UserModel?>.broadcast();
  StreamSubscription<AuthState>? _sub;

  SupabaseAuthRepository(this._client) {
    _sub = _client.auth.onAuthStateChange.listen((data) async {
      if (data.event == AuthChangeEvent.signedOut ||
          data.session == null ||
          data.session?.user == null ||
          _client.auth.currentSession == null ||
          _client.auth.currentUser == null) {
        _authStateController.add(null);
        return;
      }
      final user = data.session?.user;
      if (user == null) {
        _authStateController.add(null);
      } else {
        final userModel = await _buildUserModel(user);
        _authStateController.add(userModel);
      }
    });
  }

  void dispose() {
    _sub?.cancel();
    _authStateController.close();
  }

  @override
  Stream<UserModel?> get authStateChanges => _authStateController.stream;

  @override
  UserModel? get currentUser {
    if (_client.auth.currentSession == null ||
        _client.auth.currentUser == null) {
      return null;
    }
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _userModelFromSupabase(user);
  }

  Future<Map<String, dynamic>?> _fetchProfile(String userId) async {
    if (_client.auth.currentSession == null ||
        _client.auth.currentUser == null) {
      return null;
    }
    try {
      final profile = await _client
          .from('profiles')
          .select('id, username, display_name, created_at')
          .eq('id', userId)
          .maybeSingle();

      return profile;
    } catch (e) {
      debugPrint('[SupabaseAuthRepository] Error fetching profile: $e');
      return null;
    }
  }

  Future<UserModel> _buildUserModel(User user) async {
    final profile = await _fetchProfile(user.id);
    if (profile != null) {
      return UserModel.fromProfileMap(profile, email: user.email);
    }
    return _userModelFromSupabase(user);
  }

  UserModel _userModelFromSupabase(User user) {
    final meta = user.userMetadata ?? {};
    final username =
        (meta['username'] as String?) ??
        (user.email != null
            ? AuthValidators.extractUsernameFromEmail(user.email!)
            : 'user');
    final displayName = (meta['display_name'] as String?)?.isNotEmpty == true
        ? meta['display_name'] as String
        : username;

    return UserModel(
      id: user.id,
      username: username,
      displayName: displayName,
      email: user.email,
      createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
    );
  }

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String username,
    String? displayName,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final normalizedUsername = username.trim().toLowerCase();
    final cleanDisplayName = displayName?.trim().isNotEmpty == true
        ? displayName!.trim()
        : normalizedUsername;

    final response = await _client.auth.signUp(
      email: cleanEmail,
      password: password,
      data: {'username': normalizedUsername, 'display_name': cleanDisplayName},
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('Gagal membuat akun.');
    }

    // When "Confirm email" is disabled, Supabase returns a session immediately.
    // If session is null, attempt signInWithPassword to establish session.
    if (response.session == null) {
      try {
        final signinRes = await _client.auth.signInWithPassword(
          email: cleanEmail,
          password: password,
        );
        if (signinRes.user != null) {
          return await _buildUserModel(signinRes.user!);
        }
      } catch (_) {
        // Fallback to returned user
      }
    }

    return await _buildUserModel(user);
  }

  @override
  Future<UserModel> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    final response = await _client.auth.signInWithPassword(
      email: cleanEmail,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('Gagal masuk ke akun.');
    }

    return await _buildUserModel(user);
  }

  @override
  Future<void> sendPasswordResetOtp(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    await _client.auth.resetPasswordForEmail(cleanEmail);
  }

  @override
  Future<void> verifyPasswordResetOtp({
    required String email,
    required String token,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanToken = token.trim();
    await _client.auth.verifyOTP(
      email: cleanEmail,
      token: cleanToken,
      type: OtpType.recovery,
    );
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  String mapError(Object error) => mapAuthError(error);

  /// Converts exceptions and errors into user-friendly Indonesian messages.
  static String mapAuthError(Object error) {
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('already registered') ||
          msg.contains('user already exists') ||
          msg.contains('unique constraint')) {
        return 'Email atau username sudah terdaftar. Silakan pilih yang lain atau login.';
      }
      if (msg.contains('invalid login credentials') ||
          msg.contains('invalid grant')) {
        return 'Email atau password salah.';
      }
      if (msg.contains('password') &&
          (msg.contains('short') || msg.contains('least'))) {
        return 'Password minimal 8 karakter.';
      }
      if (msg.contains('rate limit') ||
          msg.contains('too many requests') ||
          msg.contains('over_email_send_rate_limit')) {
        return 'Terlalu banyak permintaan (rate limit). Silakan tunggu beberapa saat sebelum mencoba lagi.';
      }
      if (msg.contains('token has expired') ||
          msg.contains('invalid token') ||
          msg.contains('token is invalid') ||
          msg.contains('otp expired') ||
          msg.contains('otp invalid')) {
        return 'Kode OTP tidak valid atau sudah kedaluwarsa.';
      }
      if (msg.contains('network') ||
          msg.contains('connection') ||
          msg.contains('timeout')) {
        return 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
      }
      return error.message;
    }

    final errStr = error.toString().toLowerCase();
    if (errStr.contains('socketexception') ||
        errStr.contains('failed host lookup') ||
        errStr.contains('clientexception') ||
        errStr.contains('connection refused') ||
        errStr.contains('handshakeexception')) {
      return 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
    }

    if (errStr.contains('23505') ||
        errStr.contains('profiles_username_key') ||
        errStr.contains('duplicate key')) {
      return 'Username sudah terdaftar. Silakan gunakan username lain.';
    }

    return 'Terjadi kesalahan: ${error.toString()}';
  }
}

/// In-memory Mock implementation of [AuthRepository] used for tests
/// or preview mode when Supabase is not configured.
class MockAuthRepository implements AuthRepository {
  UserModel? _user;
  final _controller = StreamController<UserModel?>.broadcast();

  MockAuthRepository({UserModel? initialUser, bool isUnauthenticated = false}) {
    _user = isUnauthenticated
        ? null
        : (initialUser ??
              UserModel(
                id: 'user-1',
                username: 'raka_belajar',
                displayName: 'Raka Pratama',
                email: 'raka@example.com',
                createdAt: DateTime.now().subtract(const Duration(days: 30)),
              ));
  }

  @override
  Stream<UserModel?> get authStateChanges => _controller.stream;

  @override
  UserModel? get currentUser => _user;

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String username,
    String? displayName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final cleanEmail = email.trim().toLowerCase();
    final normalized = username.trim().toLowerCase();
    _user = UserModel(
      id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      username: normalized,
      displayName: displayName?.trim().isNotEmpty == true
          ? displayName!.trim()
          : normalized,
      email: cleanEmail,
      createdAt: DateTime.now(),
    );
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<UserModel> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final cleanEmail = email.trim().toLowerCase();
    final username = cleanEmail.split('@').first;
    _user = UserModel(
      id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      username: username,
      displayName: username,
      email: cleanEmail,
      createdAt: DateTime.now(),
    );
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<void> sendPasswordResetOtp(String email) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Simulated successful OTP send
  }

  @override
  Future<void> verifyPasswordResetOtp({
    required String email,
    required String token,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final cleanToken = token.trim();
    if (cleanToken != '12345678' && cleanToken.length != 8) {
      throw const AuthException('Kode OTP tidak valid atau sudah kedaluwarsa.');
    }
    // Supabase sets an active recovery session
    final cleanEmail = email.trim().toLowerCase();
    _user = UserModel(
      id: 'mock-recovery-user',
      username: cleanEmail.split('@').first,
      displayName: 'Recovery User',
      email: cleanEmail,
      createdAt: DateTime.now(),
    );
    _controller.add(_user);
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Simulated successful password update
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _user = null;
    _controller.add(null);
  }

  @override
  String mapError(Object error) {
    if (error is AuthException) return error.message;
    return error.toString();
  }
}

/// Provider for [AuthRepository]. Automatically uses [SupabaseAuthRepository]
/// when Supabase is configured via `--dart-define`, or [MockAuthRepository] in fallback mode.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (SupabaseConfig.isConfigured) {
    return SupabaseAuthRepository(SupabaseConfig.client);
  }
  return MockAuthRepository();
});
