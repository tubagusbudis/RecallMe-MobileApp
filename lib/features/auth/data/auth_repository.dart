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

  /// Registers a new user with username and password, mapped to `<username>@recallme.internal`.
  Future<UserModel> signUp({
    required String username,
    required String password,
    String? displayName,
  });

  /// Signs in using username and password, mapped to `<username>@recallme.internal`.
  Future<UserModel> signInWithPassword({
    required String username,
    required String password,
  });

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
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _userModelFromSupabase(user);
  }

  Future<UserModel> _buildUserModel(User user) async {
    try {
      final profile = await _client
          .from('profiles')
          .select('id, username, display_name, created_at')
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null) {
        return UserModel.fromProfileMap(profile);
      }
    } catch (e) {
      debugPrint('[SupabaseAuthRepository] Error fetching profile: $e');
    }
    return _userModelFromSupabase(user);
  }

  UserModel _userModelFromSupabase(User user) {
    final meta = user.userMetadata ?? {};
    final username =
        (meta['username'] as String?) ??
        AuthValidators.extractUsernameFromEmail(user.email ?? 'user');
    final displayName = (meta['display_name'] as String?)?.isNotEmpty == true
        ? meta['display_name'] as String
        : username;

    return UserModel(
      id: user.id,
      username: username,
      displayName: displayName,
      createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
    );
  }

  @override
  Future<UserModel> signUp({
    required String username,
    required String password,
    String? displayName,
  }) async {
    final normalizedUsername = username.trim().toLowerCase();
    final internalEmail = AuthValidators.toInternalAuthEmail(
      normalizedUsername,
    );

    final cleanDisplayName = displayName?.trim().isNotEmpty == true
        ? displayName!.trim()
        : normalizedUsername;

    final response = await _client.auth.signUp(
      email: internalEmail,
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
          email: internalEmail,
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
    required String username,
    required String password,
  }) async {
    final normalizedUsername = username.trim().toLowerCase();
    final internalEmail = AuthValidators.toInternalAuthEmail(
      normalizedUsername,
    );

    final response = await _client.auth.signInWithPassword(
      email: internalEmail,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('Gagal masuk ke akun.');
    }

    return await _buildUserModel(user);
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
        return 'Username sudah terdaftar. Silakan pilih username lain atau login.';
      }
      if (msg.contains('invalid login credentials') ||
          msg.contains('invalid grant')) {
        return 'Username atau password salah.';
      }
      if (msg.contains('password') &&
          (msg.contains('short') || msg.contains('least'))) {
        return 'Password minimal 8 karakter.';
      }
      if (msg.contains('rate limit') || msg.contains('too many requests')) {
        return 'Terlalu banyak percobaan. Silakan coba lagi beberapa saat.';
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
                createdAt: DateTime.now().subtract(const Duration(days: 30)),
              ));
  }

  @override
  Stream<UserModel?> get authStateChanges => _controller.stream;

  @override
  UserModel? get currentUser => _user;

  @override
  Future<UserModel> signUp({
    required String username,
    required String password,
    String? displayName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final normalized = username.trim().toLowerCase();
    _user = UserModel(
      id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      username: normalized,
      displayName: displayName?.trim().isNotEmpty == true
          ? displayName!.trim()
          : normalized,
      createdAt: DateTime.now(),
    );
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<UserModel> signInWithPassword({
    required String username,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final normalized = username.trim().toLowerCase();
    _user = UserModel(
      id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      username: normalized,
      displayName: normalized,
      createdAt: DateTime.now(),
    );
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _user = null;
    _controller.add(null);
  }

  @override
  String mapError(Object error) => error.toString();
}

/// Provider for [AuthRepository]. Automatically uses [SupabaseAuthRepository]
/// when Supabase is configured via `--dart-define`, or [MockAuthRepository] in fallback mode.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (SupabaseConfig.isConfigured) {
    return SupabaseAuthRepository(SupabaseConfig.client);
  }
  return MockAuthRepository();
});
