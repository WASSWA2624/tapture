import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/security/secure_storage.dart';

void main() {
  test('a provider key never appears in preferences or the database', () async {
    const String secret = 'sk-live-should-not-leak';
    final Map<SecretKey, String> backing = <SecretKey, String>{};
    final Map<String, String> preferences = <String, String>{};
    final Map<String, String> database = <String, String>{'export': '{}'};
    final SecureStorage storage = SecureStorage.fake(
      backing: backing,
      preferences: preferences,
      database: database,
    );
    await storage.putSecret(SecretKey.providerCredential, secret);
    expect(backing[SecretKey.providerCredential], secret);
    expect(preferences.values.join(), isNot(contains(secret)));
    expect(database.values.join(), isNot(contains(secret)));
    await storage.deleteSecret(SecretKey.providerCredential);
    expect(backing.containsKey(SecretKey.providerCredential), isFalse);
  });
}
