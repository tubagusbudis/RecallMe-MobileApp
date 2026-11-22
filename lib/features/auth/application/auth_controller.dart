import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../domain/auth_validators.dart';
import '../domain/user_model.dart';
import '../../decks/application/deck_controller.dart';
import '../../flashcards/application/flashcard_controller.dart';
import '../../study/application/study_controller.dart';
import '../../stats/application/stats_controller.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({this.user, this.isLoading = false, this.errorMessage});

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? errorMessage,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
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

  /// Clears any currently displayed error message.
  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }

  Future<bool> login(String username, String password) async {
    final userErr = validateUsername(username);
    if (userErr != null) {
      state = state.copyWith(errorMessage: userErr);
      return false;
    }
    if (password.isEmpty) {
      state = state.copyWith(errorMessage: 'Password tidak boleh kosong');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _repository.signInWithPassword(
        username: username,
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
    String password, {
    String? displayName,
  }) async {
    final userErr = validateUsername(username);
    if (userErr != null) {
      state = state.copyWith(errorMessage: userErr);
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
        username: username,
        password: password,
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

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.signOut();
    } catch (_) {
      // Continue resetting local state
    } finally {
      // Clean up all user-scoped data providers
      _invalidateUserData();
      state = const AuthState();
    }
  }

  void _invalidateUserData() {
    ref.invalidate(deckControllerProvider);
    ref.invalidate(flashcardControllerProvider);
    ref.invalidate(studyControllerProvider);
    ref.invalidate(statsControllerProvider);
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
