import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/security/secure_storage.dart';
import 'package:tapture/features/settings/settings.dart';

import 'provider_test_action.dart';

/// Saves, removes and tests the device-held key.
///
/// The key goes to secure storage only, and is never read back into state:
/// the view knows only that one is held.
final class ApiKeyController extends Notifier<ApiKeyView> {
  /// Creates the controller over [stores] (the family argument).
  ApiKeyController(this.stores);

  /// The key's store and the selection it switches.
  final ApiKeyStores stores;

  @override
  ApiKeyView build() {
    unawaited(load());
    return (saved: false, failure: null, test: ProviderTestView.empty);
  }

  /// Reads whether a key is held.
  Future<void> load() async {
    final Result<String?> stored = await stores.storage.readSecret(
      SecretKey.providerCredential,
    );
    if (!ref.mounted) {
      return;
    }
    switch (stored) {
      case FailureResult<String?>(:final Failure failure):
        state = (saved: state.saved, failure: failure, test: state.test);
      case Success<String?>(:final String? value):
        state = (
          saved: value != null && value.isNotEmpty,
          failure: null,
          test: state.test,
        );
    }
  }

  /// Stores [key] and selects the device provider. Returns whether it was
  /// saved; a selection that cannot be written takes the key back out.
  Future<bool> save(String key) async {
    final String value = key.trim();
    if (value.isEmpty) {
      return false;
    }
    final Result<void> stored = await stores.storage.putSecret(
      SecretKey.providerCredential,
      value,
    );
    if (stored case FailureResult<void>(:final Failure failure)) {
      _fail(failure);
      return false;
    }
    final SettingsStore? settings = stores.settings;
    if (settings != null) {
      final Result<void> selected = await settings.write(
        SettingKeys.aiProvider,
        'device',
      );
      if (selected case FailureResult<void>(:final Failure failure)) {
        await stores.storage.deleteSecret(SecretKey.providerCredential);
        _fail(failure);
        return false;
      }
    }
    if (ref.mounted) {
      state = (saved: true, failure: null, test: state.test);
    }
    return true;
  }

  /// Returns the selection to the backend and deletes the key, in one
  /// action.
  Future<void> remove() async {
    final SettingsStore? settings = stores.settings;
    if (settings != null) {
      final Result<void> selected = await settings.write(
        SettingKeys.aiProvider,
        'backend',
      );
      if (selected case FailureResult<void>(:final Failure failure)) {
        _fail(failure);
        return;
      }
    }
    final Result<void> removed = await stores.storage.deleteSecret(
      SecretKey.providerCredential,
    );
    if (removed case FailureResult<void>(:final Failure failure)) {
      _fail(failure);
      return;
    }
    if (ref.mounted) {
      state = (saved: false, failure: null, test: state.test);
    }
  }

  /// Runs [test] and shows its outcome.
  Future<void> runTest(Future<ProviderTestView> Function() test) async {
    final ProviderTestView outcome = await test();
    if (ref.mounted) {
      state = (saved: state.saved, failure: state.failure, test: outcome);
    }
  }

  void _fail(Failure failure) {
    if (ref.mounted) {
      state = (saved: state.saved, failure: failure, test: state.test);
    }
  }
}

/// The key screen's state for one pair of stores, forgotten when the screen
/// closes.
final apiKeyControllerProvider = NotifierProvider.autoDispose
    .family<ApiKeyController, ApiKeyView, ApiKeyStores>(ApiKeyController.new);

/// Where the device-held key lives, and the selection it switches. Without
/// [settings] the key is stored and nothing else changes.
typedef ApiKeyStores = ({SecureStorage storage, SettingsStore? settings});

/// What the key screen shows: whether a key is held, the last failure and
/// the last connection test.
typedef ApiKeyView = ({bool saved, Failure? failure, ProviderTestView test});
