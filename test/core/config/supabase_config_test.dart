import 'package:flutter_test/flutter_test.dart';
import 'package:recallme/core/config/supabase_config.dart';

void main() {
  group('SupabaseConfig', () {
    test('defaults to empty when dart-define is not provided', () {
      expect(SupabaseConfig.supabaseUrl, isEmpty);
      expect(SupabaseConfig.supabaseAnonKey, isEmpty);
      expect(SupabaseConfig.isConfigured, isFalse);
    });

    test(
      'initialize runs safely without crashing when not configured',
      () async {
        await expectLater(SupabaseConfig.initialize(), completes);
      },
    );

    test('client throws StateError when not configured', () {
      expect(() => SupabaseConfig.client, throwsStateError);
    });
  });
}
