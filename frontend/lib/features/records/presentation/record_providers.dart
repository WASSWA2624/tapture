import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/projects/projects.dart'
    show projectSettingsStoreProvider;
import 'package:tapture/features/settings/settings.dart'
    show SettingKey, SettingKeys, SettingsStore;

import '../domain/purge_job.dart';
import '../domain/record_entry.dart';
import '../records.dart' show recordRepositoryProvider;

// Providers two or more records screens share (task 014). Screen-only state
// stays in that screen's own controller.

/// Record [id] read whole, and again after every change to it. Null when no
/// record [id] is on this device. Deleted records are included; their status
/// says so, so the detail page can offer a restore. Auto-dispose: only an
/// open page or pane reads it (FE-STATE-09).
final recordEntryProvider = StreamProvider.autoDispose
    .family<RecordEntry?, String>((Ref ref, String id) {
      return ref.watch(recordRepositoryProvider).watchEntry(id);
    }, retry: (int _, Object _) => null);

/// The retention purge that runs once after launch (D13). Null means no
/// purge: suites and previews never remove anything. `main` overrides it,
/// outside tests, with a job over the Drift purge store, the system clock and
/// [recordRetentionDaysProvider]'s window. Kept alive: `main` reads it once.
final Provider<PurgeJob?> recordPurgeJobProvider = Provider<PurgeJob?>((Ref _) {
  return null;
});

/// Whole days a deleted record stays in the recycle bin before the purge may
/// take it: the operator's setting, read through the settings store, and
/// read again whenever that setting changes. The delete confirm names it and
/// the bin counts down from it. Auto-dispose: read by open screens only.
final Provider<int> recordRetentionDaysProvider = Provider.autoDispose<int>((
  Ref ref,
) {
  final SettingsStore store = ref.watch(projectSettingsStoreProvider);
  final StreamSubscription<SettingKey<Object?>> changes = store
      .changes()
      .listen((SettingKey<Object?> key) {
        if (key == SettingKeys.retentionDays) {
          ref.invalidateSelf();
        }
      });
  ref.onDispose(changes.cancel);
  return store.read(SettingKeys.retentionDays);
});

/// The clock records screens measure time on, such as the days a deleted
/// record has left. Tests replace it with a [FixedClock].
final Provider<Clock> recordClockProvider = Provider<Clock>((Ref _) {
  return const SystemClock();
});
