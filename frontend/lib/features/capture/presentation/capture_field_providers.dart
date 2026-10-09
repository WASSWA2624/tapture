import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/features/projects/projects.dart'
    show projectSettingsStoreProvider;
import 'package:tapture/features/settings/settings.dart'
    show SettingKey, SettingKeys, SettingsStore;

/// Capture previews follow only successfully committed date-fill preferences.
final captureDateFillProvider = NotifierProvider.autoDispose<_DateFill, bool>(
  _DateFill.new,
);

final class _DateFill extends Notifier<bool> {
  @override
  bool build() {
    final SettingsStore store = ref.watch(projectSettingsStoreProvider);
    final StreamSubscription<SettingKey<Object?>> changes = store
        .changes()
        .listen((SettingKey<Object?> key) {
          if (key == SettingKeys.autoFillDates) {
            state = store.read(SettingKeys.autoFillDates);
          }
        });
    ref.onDispose(changes.cancel);
    return store.read(SettingKeys.autoFillDates);
  }
}
