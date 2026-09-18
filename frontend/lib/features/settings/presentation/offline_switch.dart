import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';

import '../domain/setting_key.dart';
import '../domain/setting_keys.dart';
import '../settings.dart' show SettingsStore;

// The notifier is private so this file holds one public class (FE-STR-06).
// ignore_for_file: library_private_types_in_public_api

/// The only writer of [SettingKeys.offlineByChoice].
///
/// Readers ask connectivity for `NetworkState`. This switch persists
/// the flag; it does not send and it does not keep a second stored
/// copy of the value (FE-STATE-06, FE-SEC-04).
class OfflineSwitch extends ConsumerWidget {
  /// Creates the settings switch.
  const OfflineSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool on = ref.watch(offlineByChoiceProvider);
    return AppSwitchTile(
      title: Copy.settingsOfflineTitle,
      description: Copy.settingsOfflineEffect,
      value: on,
      onChanged: (bool next) {
        unawaited(ref.read(offlineByChoiceProvider.notifier).setEnabled(next));
      },
    );
  }
}

/// Process-wide store for the offline flag. Tests and [main] replace
/// the empty fake so suites never open a database (FE-TEST-03).
/// Kept alive: the status line and the connectivity fold read it
/// (FE-STATE-09).
final Provider<SettingsStore> offlineStoreProvider = Provider<SettingsStore>((
  Ref _,
) {
  return SettingsStore.fake();
});

/// Whether the operator forced offline. Derived from [offlineStoreProvider]
/// on every read; not a second stored copy (FE-STATE-06).
/// Kept alive: the status line reads it on every frame (FE-STATE-09).
final NotifierProvider<_OfflineByChoice, bool> offlineByChoiceProvider =
    NotifierProvider<_OfflineByChoice, bool>(_OfflineByChoice.new);

/// Injects [store] so the switch and the connectivity fold share one map.
Override offlineStoreOverride(SettingsStore store) {
  return offlineStoreProvider.overrideWith((Ref _) => store);
}

/// Injects a fixed label for suites that are not about the store.
Override offlineByChoiceOverride(bool value) {
  return offlineByChoiceProvider.overrideWith(
    () => _OfflineByChoice.fixed(value),
  );
}

class _OfflineByChoice extends Notifier<bool> {
  _OfflineByChoice() : _fixed = null;

  _OfflineByChoice.fixed(this._fixed);

  final bool? _fixed;
  StreamSubscription<SettingKey<Object?>>? _changes;

  @override
  bool build() {
    ref.onDispose(() {
      unawaited(_changes?.cancel());
    });
    final bool? fixed = _fixed;
    if (fixed != null) {
      return fixed;
    }
    final SettingsStore store = ref.watch(offlineStoreProvider);
    unawaited(_changes?.cancel());
    _changes = store.changes().listen((SettingKey<Object?> _) {
      state = store.read(SettingKeys.offlineByChoice);
    });
    return store.read(SettingKeys.offlineByChoice);
  }

  /// Persists [value]. The only sanctioned write of this flag.
  Future<void> setEnabled(bool value) async {
    if (_fixed != null) {
      state = value;
      return;
    }
    final SettingsStore store = ref.read(offlineStoreProvider);
    await store.write(SettingKeys.offlineByChoice, value);
    state = store.read(SettingKeys.offlineByChoice);
  }
}
