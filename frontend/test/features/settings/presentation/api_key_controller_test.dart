import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/security/secure_storage.dart';
import 'package:tapture/features/settings/presentation/api_key_controller.dart';
import 'package:tapture/features/settings/presentation/provider_test_action.dart';
import 'package:tapture/features/settings/settings.dart';

void main() {
  late ProviderContainer container;
  late Map<SecretKey, String> vault;

  setUp(() {
    container = ProviderContainer();
    vault = <SecretKey, String>{};
  });

  tearDown(() => container.dispose());

  /// The controller for [stores], kept alive for the test.
  ApiKeyController controller(ApiKeyStores stores) {
    container.listen<ApiKeyView>(apiKeyControllerProvider(stores), (_, _) {});
    return container.read(apiKeyControllerProvider(stores).notifier);
  }

  ApiKeyView view(ApiKeyStores stores) {
    return container.read(apiKeyControllerProvider(stores));
  }

  test('a key already held reads as saved, never as its value', () async {
    vault[SecretKey.providerCredential] = 'sk-held';
    final ApiKeyStores stores = (
      storage: SecureStorage.fake(backing: vault),
      settings: null,
    );

    await controller(stores).load();

    expect(view(stores).saved, isTrue);
    expect(view(stores).toString(), isNot(contains('sk-held')));
  });

  test('saving stores the key and selects the device provider', () async {
    final SettingsStore settings = SettingsStore.fake();
    final ApiKeyStores stores = (
      storage: SecureStorage.fake(backing: vault),
      settings: settings,
    );

    expect(await controller(stores).save('  sk-new  '), isTrue);

    expect(vault[SecretKey.providerCredential], 'sk-new');
    expect(settings.read(SettingKeys.aiProvider), 'device');
    expect(view(stores).saved, isTrue);
    expect(await controller(stores).save('   '), isFalse);
  });

  test('a selection that cannot be written takes the key back out', () async {
    final ApiKeyStores stores = (
      storage: SecureStorage.fake(backing: vault),
      settings: SettingsStore.fake(failWrites: true),
    );

    expect(await controller(stores).save('sk-new'), isFalse);

    expect(vault, isEmpty);
    expect(view(stores).saved, isFalse);
    expect(view(stores).failure, isA<Failure>());
  });

  test('removal clears the key and the selection in one action', () async {
    vault[SecretKey.providerCredential] = 'sk-held';
    final SettingsStore settings = SettingsStore.fake(
      stored: <String, Object?>{SettingKeys.aiProvider.name: 'device'},
    );
    final ApiKeyStores stores = (
      storage: SecureStorage.fake(backing: vault),
      settings: settings,
    );
    await controller(stores).load();

    await controller(stores).remove();

    expect(vault, isEmpty);
    expect(settings.read(SettingKeys.aiProvider), 'backend');
    expect(view(stores).saved, isFalse);
  });

  test('a connection test shows its outcome', () async {
    final ApiKeyStores stores = (
      storage: SecureStorage.fake(backing: vault),
      settings: null,
    );

    await controller(
      stores,
    ).runTest(() async => ProviderTestView.authentication);

    expect(view(stores).test, ProviderTestView.authentication);
  });
}
