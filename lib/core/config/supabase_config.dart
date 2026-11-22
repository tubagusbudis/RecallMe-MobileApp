import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuration and initialization helper for Supabase.
///
/// Uses compile-time environment definitions via `--dart-define`:
/// - `SUPABASE_URL`
/// - `SUPABASE_ANON_KEY`
///
/// SECURITY RULES:
/// - NEVER hardcode the Supabase URL or Anon Key.
/// - NEVER use or expose the Supabase service role key in client code.
class SupabaseConfig {
  SupabaseConfig._();

  /// The Supabase Project URL provided via `--dart-define=SUPABASE_URL=...`.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  /// The Supabase Anon/Publishable Key provided via
  /// `--dart-define=SUPABASE_ANON_KEY=...` or `--dart-define=SUPABASE_PUBLISHABLE_KEY=...`.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
      defaultValue: '',
    ),
  );

  /// Returns true if both URL and Anon/Publishable Key are supplied.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Initializes the Supabase client when configuration is present.
  ///
  /// If [isConfigured] is false, logs a warning and does not crash,
  /// allowing local mock/preview runs.
  static Future<void> initialize() async {
    if (!isConfigured) {
      debugPrint(
        '⚠️ [SupabaseConfig] Supabase is not configured.\n'
        'To connect to Supabase, run with:\n'
        '  --dart-define=SUPABASE_URL="https://your-project.supabase.co" \\\n'
        '  --dart-define=SUPABASE_ANON_KEY="your-anon-key"',
      );
      return;
    }

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseAnonKey,
      );
      debugPrint('✅ [SupabaseConfig] Supabase initialized successfully.');
    } catch (e, st) {
      debugPrint('❌ [SupabaseConfig] Failed to initialize Supabase: $e\n$st');
    }
  }

  /// Convenience getter for the initialized [SupabaseClient].
  ///
  /// Throws a [StateError] if called before Supabase has been initialized.
  static SupabaseClient get client {
    if (!isConfigured) {
      throw StateError(
        'Supabase is not configured. Provide SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define.',
      );
    }
    return Supabase.instance.client;
  }
}
