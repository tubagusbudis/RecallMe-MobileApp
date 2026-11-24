/// Pure Dart helpers and validators for RecallMe Authentication.
class AuthValidators {
  AuthValidators._();

  /// Maps username to internal email format for Supabase Auth (legacy helper):
  /// `<username_lowercase>@recallme.internal`
  static String toInternalAuthEmail(String username) {
    final normalized = username.trim().toLowerCase();
    return '$normalized@recallme.internal';
  }

  /// Extracts the username from an email address.
  static String extractUsernameFromEmail(String email) {
    final trimmed = email.trim();
    if (!trimmed.contains('@')) return trimmed.toLowerCase();
    return trimmed.split('@').first.toLowerCase();
  }

  /// Validates email format:
  /// - Required (not empty after trim)
  /// - Standard email regex format
  static String? validateEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&'
      r"'"
      r'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)+$',
    );
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  /// Validates 8-digit OTP code for password recovery:
  /// - Required (not empty after trim)
  /// - Exactly 8 digits
  static String? validateOtp(String otp) {
    final trimmed = otp.trim();
    if (trimmed.isEmpty) {
      return 'Kode OTP tidak boleh kosong';
    }
    if (!RegExp(r'^\d{8}$').hasMatch(trimmed)) {
      return 'Kode OTP harus berupa 8 digit angka';
    }
    return null;
  }

  /// Validates username:
  /// - Required (not empty after trim)
  /// - 3 to 30 characters
  /// - Only letters, numbers, and underscores (`^[a-zA-Z0-9_]{3,30}$`)
  static String? validateUsername(String username) {
    final trimmed = username.trim();
    if (trimmed.isEmpty) {
      return 'Username tidak boleh kosong';
    }
    if (trimmed.length < 3 || trimmed.length > 30) {
      return 'Username harus 3–30 karakter';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(trimmed)) {
      return 'Hanya huruf, angka, dan garis bawah (_) tanpa spasi';
    }
    return null;
  }

  /// Validates password complexity per PRD v1.1:
  /// - Minimum 8 characters
  /// - Combination of letters, numbers, and symbols
  static String? validatePassword(String password) {
    if (password.length < 8) {
      return 'Password minimal 8 karakter';
    }
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    final hasSymbol = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

    if (!hasLetter || !hasNumber || !hasSymbol) {
      return 'Kombinasi huruf, angka, dan simbol (!@#\$%^&*) diperlukan';
    }
    return null;
  }
}
