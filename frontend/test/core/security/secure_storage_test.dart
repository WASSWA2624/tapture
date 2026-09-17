import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/security/secure_storage.dart';

void main() {
  test(
    'secrets survive a restart and stay off preferences and the database',
    () async {
      final Map<SecretKey, String> backing = <SecretKey, String>{};
      final Map<String, String> preferences = <String, String>{'theme': 'dark'};
      final Map<String, String> database = <String, String>{'record': '1'};
      const String value = 'hash-one';

      final SecureStorage first = SecureStorage.fake(
        backing: backing,
        preferences: preferences,
        database: database,
      );
      final Result<void> written = await first.putSecret(
        SecretKey.pinHash,
        value,
      );

      expect(written, isA<Success<void>>());
      expect(preferences, <String, String>{'theme': 'dark'});
      expect(database, <String, String>{'record': '1'});
      expect(preferences.values, isNot(contains(value)));
      expect(database.values, isNot(contains(value)));

      final SecureStorage restarted = SecureStorage.fake(
        backing: backing,
        preferences: preferences,
        database: database,
      );
      final Result<String?> read = await restarted.readSecret(
        SecretKey.pinHash,
      );

      expect(read.fold((_) => null, (String? stored) => stored), value);
      expect(preferences.values, isNot(contains(value)));
      expect(database.values, isNot(contains(value)));
    },
  );

  test('deleteAll leaves no readable residue for any SecretKey', () async {
    final Map<SecretKey, String> backing = <SecretKey, String>{
      for (final SecretKey key in SecretKey.values) key: 'held-$key',
    };
    final SecureStorage storage = SecureStorage.fake(backing: backing);

    await storage.deleteAll();

    expect(backing, isEmpty);
    for (final SecretKey key in SecretKey.values) {
      final Result<String?> read = await storage.readSecret(key);
      expect(read.fold((_) => 'failed', (String? stored) => stored), isNull);
    }
  });

  test(
    'a secret is never written to the preferences store or the database',
    () async {
      final Map<SecretKey, String> backing = <SecretKey, String>{};
      final Map<String, String> preferences = <String, String>{};
      final Map<String, String> database = <String, String>{};
      const String value = 'token-two';
      final SecureStorage storage = SecureStorage.fake(
        backing: backing,
        preferences: preferences,
        database: database,
      );

      for (final SecretKey key in SecretKey.values) {
        await storage.putSecret(key, value);
      }

      expect(backing.length, SecretKey.values.length);
      expect(backing.values.every((String stored) => stored == value), isTrue);
      expect(preferences, isEmpty);
      expect(database, isEmpty);
    },
  );
}
