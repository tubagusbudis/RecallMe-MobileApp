import 'package:flutter_test/flutter_test.dart';
import 'package:recallme/core/utils/uuid_generator.dart';

void main() {
  group('UuidGenerator tests', () {
    test('generates valid RFC 4122 v4 UUID format', () {
      final uuid = UuidGenerator.v4();

      final regex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );

      expect(regex.hasMatch(uuid), isTrue);
    });

    test('generates unique UUIDs on each call', () {
      final set = <String>{};
      for (int i = 0; i < 100; i++) {
        set.add(UuidGenerator.v4());
      }
      expect(set.length, 100);
    });
  });
}
