import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../domain/auth_validators.dart';
import '../domain/user_model.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? errorMessage;
  final bool isPasswordRecovery;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.isPasswordRecovery = false,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? errorMessage,
    bool? isPasswordRecovery,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isPasswordRecovery: isPasswordRecovery ?? this.isPasswordRecovery,
    );
  }
}

class AuthController extends Notifier<AuthState> {
  late final AuthRepository _repository;
  StreamSubscription<UserModel?>? _authSubscription;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);

    _authSubscription?.cancel();
    _authSubscription = _repository.authStateChanges.listen((user) {
      state = state.copyWith(
        user: user,
        clearUser: user == null,
        isLoading: false,
      );
    });

    ref.onDispose(() {
      _authSubscription?.cancel();
    });

    return AuthState(user: _repository.currentUser);
  }

  /// Validates password complexity: min 8 chars, combination of letters, numbers, and symbols
  static String? validatePassword(String password) =>
      AuthValidators.validatePassword(password);

  /// Validates username: 3-30 chars, alphanumeric + underscore
  static String? validateUsername(String username) =>
      AuthValidators.validateUsername(username);

  /// Validates email address format
  static String? validateEmail(String email) =>
      AuthValidators.validateEmail(email);

  /// Validates 8-digit OTP code
  static String? validateOtp(String otp) => AuthValidators.validateOtp(otp);

  /// Clears any currently displayed error message.
  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }

  Future<bool> login(String email, String password) async {
    final emailErr = validateEmail(email);
    if (emailErr != null) {
      state = state.copyWith(errorMessage: emailErr);
      return false;
    }
    if (password.isEmpty) {
      state = state.copyWith(errorMessage: 'Password tidak boleh kosong');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _repository.signInWithPassword(
        email: email,
        password: password,
      );
      state = state.copyWith(isLoading: false, user: user, errorMessage: null);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _repository.mapError(e),
      );
      return false;
    }
  }

  Future<bool> register(
    String username,
    String email,
    String password, {
    String? displayName,
  }) async {
    final userErr = validateUsername(username);
    if (userErr != null) {
      state = state.copyWith(errorMessage: userErr);
      return false;
    }
    final emailErr = validateEmail(email);
    if (emailErr != null) {
      state = state.copyWith(errorMessage: emailErr);
      return false;
    }
    final passErr = validatePassword(password);
    if (passErr != null) {
      state = state.copyWith(errorMessage: passErr);
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _repository.signUp(
        email: email,
        password: password,
        username: username,
        displayName: displayName,
      );
      state = state.copyWith(isLoading: false, user: user, errorMessage: null);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _repository.mapError(e),
      );
      return false;
    }
  }

  /// Sends an 8-digit OTP to the user's email for password reset.
  Future<bool> sendPasswordResetOtp(String email) async {
    final emailErr = validateEmail(email);
    if (emailErr != null) {
      state = state.copyWith(errorMessage: emailErr);
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.sendPasswordResetOtp(email);
      state = state.copyWith(isLoading: false, errorMessage: null);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _repository.mapError(e),
      );
      return false;
    }
  }

  /// Verifies the 8-digit OTP code using recovery type.
  Future<bool> verifyPasswordResetOtp({
    required String email,
    required String token,
  }) async {
    final emailErr = validateEmail(email);
    if (emailErr != null) {
      state = state.copyWith(errorMessage: emailErr);
      return false;
    }
    final otpErr = validateOtp(token);
    if (otpErr != null) {
      state = state.copyWith(errorMessage: otpErr);
      return false;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      isPasswordRecovery: true,
    );
    try {
      await _repository.verifyPasswordResetOtp(email: email, token: token);
      state = state.copyWith(
        isLoading: false,
        errorMessage: null,
        isPasswordRecovery: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _repository.mapError(e),
      );
      return false;
    }
  }

  /// Updates the password for the current recovery session.
  Future<bool> updatePassword(String newPassword) async {
    final passErr = validatePassword(newPassword);
    if (passErr != null) {
      state = state.copyWith(errorMessage: passErr);
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.updatePassword(newPassword);
      state = state.copyWith(isLoading: false, errorMessage: null);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _repository.mapError(e),
      );
      return false;
    }
  }

  /// Atomically completes the password recovery sequence:
  /// 1) Maintains recovery flag so GoRouter never redirects to /app/home.
  /// 2) Updates password via Supabase Auth.
  /// 3) Awaits signOut completely.
  /// 4) Resets auth state cleanly (downstream providers reactively clear via ref.watch).
  Future<bool> completePasswordRecovery(String newPassword) async {
    final passErr = validatePassword(newPassword);
    if (passErr != null) {
      state = state.copyWith(errorMessage: passErr);
      return false;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      isPasswordRecovery: true,
    );
    try {
      // 1. Update password
      await _repository.updatePassword(newPassword);

      // 2. Ensure signOut is fully completed
      await _repository.signOut();

      // 3. Reset auth state cleanly
      state = const AuthState(
        user: null,
        isLoading: false,
        isPasswordRecovery: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _repository.mapError(e),
      );
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.signOut();
    } catch (_) {
      // Continue resetting local state
    } finally {
      // Clean up local auth state; downstream providers reactively reset via ref.watch
      state = const AuthState();
    }
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
