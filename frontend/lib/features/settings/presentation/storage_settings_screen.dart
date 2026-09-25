import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/cache_cleanup.dart';
import 'package:tapture/core/files/folder_picker.dart';
import 'package:tapture/core/files/storage_guard.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/files/volume_stats.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/setting_keys.dart';
import '../settings.dart' show SettingsStore;
import 'offline_switch.dart';

// The notifier is private so this file holds one public class (FE-STR-06).
// ignore_for_file: library_private_types_in_public_api

/// Space used per project, free headroom, cache clear and retention.
class StorageSettingsScreen extends ConsumerWidget {
  /// Creates the storage screen.
  const StorageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<_StorageView> value = ref.watch(storageSettingsProvider);
    return AppPage(
      title: Copy.settingsStorageTitle,
      body: AsyncValueView<_StorageView>(
        value: value,
        isEmpty: (_StorageView view) => !view.showUsage,
        onRetry: () => ref.invalidate(storageSettingsProvider),
        empty: () {
          return const AppEmptyState(
            icon: AppIcons.folder,
            headline: Copy.settingsStorageEmptyHeadline,
            message: Copy.settingsStorageEmptyMessage,
          );
        },
        data: (_StorageView view) {
          final _StorageSettings notifier = ref.read(
            storageSettingsProvider.notifier,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const AppSectionHeader(title: Copy.settingsHeadroomHeader),
              if (view.volume != null) ...<Widget>[
                AppListTile(
                  title: _headroomLabel(view.headroom!),
                  subtitle: Copy.settingsStorageSubtitle,
                ),
                AppListTile(
                  title: Copy.settingsVolumeTotal,
                  subtitle: Copy.fileSize(view.volume!.totalBytes),
                ),
                AppListTile(
                  title: Copy.settingsVolumeUsed,
                  subtitle: Copy.fileSize(view.volume!.usedBytes),
                ),
                AppListTile(
                  title: Copy.settingsVolumeAvailable,
                  subtitle: Copy.fileSize(view.volume!.freeBytes),
                ),
              ],
              if (view.rootPath.isNotEmpty)
                AppListTile(
                  title: Copy.settingsStorageRoot,
                  subtitle: view.rootPath,
                  onTap: ref.read(folderPickerProvider).canPick
                      ? () {
                          unawaited(notifier.chooseRoot(context));
                        }
                      : null,
                ),
              AppListTile(
                title: Copy.settingsClearCache,
                subtitle: Copy.settingsCacheSize(
                  Copy.fileSize(view.cacheBytes),
                ),
                onTap: () {
                  unawaited(notifier.clearCache(context));
                },
              ),
              const AppSectionHeader(title: Copy.settingsRetentionHeader),
              AppListTile(
                title: Copy.settingsRetention,
                subtitle: Copy.settingsRetentionSubtitle(view.retentionDays),
                onTap: () {
                  unawaited(notifier.cycleRetention());
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Injects storage seams so tests never touch the device documents folder.
Override storageSettingsOverride({
  StorageRoot? storageRoot,
  StorageGuard? storageGuard,
  SettingsStore? store,
  CacheCleanup? cacheCleanup,
  FolderPicker? folderPicker,
  Object? failWith,
  bool pending = false,
  bool empty = false,
  List<
    ({
      String name,
      int photosBytes,
      int documentsBytes,
      int audioBytes,
      int exportsBytes,
    })
  >?
  projects,
  int? cacheBytes,
  HeadroomState? headroom,
  VolumeStats? volume,
  String? rootPath,
}) {
  return storageSettingsProvider.overrideWith(
    () => _StorageSettings.withDeps(
      storageRoot: storageRoot,
      storageGuard: storageGuard,
      store: store,
      cacheCleanup: cacheCleanup,
      folderPicker: folderPicker,
      failWith: failWith,
      pending: pending,
      empty: empty,
      snapshot:
          projects == null &&
              cacheBytes == null &&
              volume == null &&
              rootPath == null
          ? null
          : (
              projects: projects ?? const <_ProjectUse>[],
              headroom: headroom ?? HeadroomState.ample,
              volume:
                  volume ??
                  const VolumeStats(
                    totalBytes: 1 << 30,
                    usedBytes: 0,
                    freeBytes: 1 << 30,
                  ),
              rootPath: rootPath ?? '',
              cacheBytes: cacheBytes ?? 0,
              retentionDays: SettingKeys.retentionDays.defaultValue,
              showUsage: true,
            ),
    ),
  );
}

/// Storage totals on this device. A failed read shows immediately —
/// Riverpod's default backoff would keep the screen in [AsyncLoading]
/// (FE-STATE-11).
final AsyncNotifierProvider<_StorageSettings, _StorageView>
storageSettingsProvider = AsyncNotifierProvider<_StorageSettings, _StorageView>(
  _StorageSettings.new,
  retry: (int _, Object _) => null,
);

typedef _ProjectUse = ({
  String name,
  int photosBytes,
  int documentsBytes,
  int audioBytes,
  int exportsBytes,
});

typedef _StorageView = ({
  List<_ProjectUse> projects,
  HeadroomState? headroom,
  VolumeStats? volume,
  String rootPath,
  int cacheBytes,
  int retentionDays,
  bool showUsage,
});

class _StorageSettings extends AsyncNotifier<_StorageView> {
  _StorageSettings()
    : _storageRoot = null,
      _storageGuard = null,
      _store = null,
      _cacheCleanup = null,
      _folderPicker = null,
      _failWith = null,
      _pending = false,
      _empty = false,
      _snapshot = null;

  _StorageSettings.withDeps({
    this._storageRoot,
    this._storageGuard,
    this._store,
    this._cacheCleanup,
    this._folderPicker,
    this._failWith,
    this._pending = false,
    this._empty = false,
    this._snapshot,
  });

  final StorageRoot? _storageRoot;
  final StorageGuard? _storageGuard;
  final SettingsStore? _store;
  final CacheCleanup? _cacheCleanup;
  final FolderPicker? _folderPicker;
  final Object? _failWith;
  final bool _pending;
  final bool _empty;
  final _StorageView? _snapshot;

  @override
  Future<_StorageView> build() {
    if (_pending) {
      return Completer<_StorageView>().future;
    }
    final Object? failWith = _failWith;
    if (failWith != null) {
      throw _asError(failWith);
    }
    if (_empty) {
      return Future<_StorageView>.value((
        projects: const <_ProjectUse>[],
        headroom: null,
        volume: null,
        rootPath: '',
        cacheBytes: 0,
        retentionDays: SettingKeys.retentionDays.defaultValue,
        showUsage: false,
      ));
    }
    final _StorageView? snapshot = _snapshot;
    if (snapshot != null) {
      return Future<_StorageView>.value(snapshot);
    }
    return _load();
  }

  /// Confirms, prunes `.cache` only, then reloads the totals.
  Future<void> clearCache(BuildContext context) async {
    final bool confirmed = await showAppConfirm(
      context,
      title: Copy.settingsClearCacheTitle,
      message: Copy.settingsClearCacheMessage,
      confirmLabel: Copy.settingsClearCache,
      destructive: true,
    );
    if (!confirmed) {
      return;
    }
    final CacheCleanup cleanup =
        _cacheCleanup ?? CacheCleanup(storageRoot: await _root());
    final Result<int> pruned = await cleanup.prune(maxBytes: 0);
    if (pruned is FailureResult<int>) {
      if (context.mounted) {
        await showAppAlert(
          context,
          title: Copy.settingsClearCache,
          message: pruned.failure.message,
        );
      }
      return;
    }
    final _StorageView? current = state.asData?.value;
    if (current != null) {
      final int reclaimed = (pruned as Success<int>).value;
      final int nextCache = current.cacheBytes - reclaimed;
      state = AsyncData<_StorageView>((
        projects: current.projects,
        headroom: current.headroom,
        volume: current.volume,
        rootPath: current.rootPath,
        cacheBytes: nextCache < 0 ? 0 : nextCache,
        retentionDays: current.retentionDays,
        showUsage: current.showUsage,
      ));
      return;
    }
    state = AsyncData<_StorageView>(await _load());
  }

  /// Cycles the retention window between the two AppConstants values.
  Future<void> cycleRetention() async {
    final SettingsStore store = await _settings();
    final int current = store.read(SettingKeys.retentionDays);
    final int next = current == AppConstants.retention.days
        ? AppConstants.logging.retentionDays
        : AppConstants.retention.days;
    await store.write(SettingKeys.retentionDays, next);
    state = AsyncData<_StorageView>(await _load());
  }

  /// Picks a folder, probes it, persists the path, then reloads.
  Future<void> chooseRoot(BuildContext context) async {
    final FolderPicker picker = _folderPicker ?? ref.read(folderPickerProvider);
    final Result<String?> picked = await picker.pick();
    switch (picked) {
      case FailureResult<String?>(:final Failure failure):
        if (failure is CancelledFailure) {
          return;
        }
        if (context.mounted) {
          await showAppAlert(
            context,
            title: Copy.settingsStorageRoot,
            message: failure.message,
          );
        }
        return;
      case Success<String?>(:final String? value):
        if (value == null || value.isEmpty) {
          return;
        }
        final Result<Directory> probed = await (await _root()).openAt(value);
        if (probed is FailureResult<Directory>) {
          if (context.mounted) {
            await showAppAlert(
              context,
              title: Copy.settingsStorageRoot,
              message: probed.failure.message,
            );
          }
          return;
        }
        final Result<void> written = await (await _settings()).write(
          SettingKeys.storageRootPath,
          value,
        );
        if (written is FailureResult<void>) {
          if (context.mounted) {
            await showAppAlert(
              context,
              title: Copy.settingsStorageRoot,
              message: written.failure.message,
            );
          }
          return;
        }
        ref.invalidate(storageRootProvider);
        state = AsyncData<_StorageView>(await _load());
    }
  }

  Future<_StorageView> _load() async {
    final SettingsStore store = await _settings();
    final int retentionDays = store.read(SettingKeys.retentionDays);
    final StorageRoot root = await _root();
    final Result<Directory> resolved = await root.resolve();
    switch (resolved) {
      case FailureResult<Directory>():
        return _usageOnly(retentionDays);
      case Success<Directory>(:final Directory value):
        final Result<VolumeStats> volume = await (await _guard()).volume();
        switch (volume) {
          case FailureResult<VolumeStats>(:final Failure failure):
            throw failure;
          case Success<VolumeStats>(value: final VolumeStats stats):
            return (
              projects: const <_ProjectUse>[],
              headroom: StorageGuard.classify(stats.freeBytes),
              volume: stats,
              rootPath: value.path,
              cacheBytes: _sum(Directory('${value.path}/.cache')),
              retentionDays: retentionDays,
              showUsage: true,
            );
        }
    }
  }

  _StorageView _usageOnly(int retentionDays) {
    return (
      projects: const <_ProjectUse>[],
      headroom: null,
      volume: null,
      rootPath: '',
      cacheBytes: 0,
      retentionDays: retentionDays,
      showUsage: true,
    );
  }

  Future<StorageRoot> _root() async {
    return _storageRoot ?? ref.read(storageRootProvider);
  }

  Future<StorageGuard> _guard() async {
    return _storageGuard ?? ref.read(storageGuardProvider);
  }

  Future<SettingsStore> _settings() async {
    final SettingsStore? injected = _store;
    if (injected != null) {
      return injected;
    }
    return ref.read(offlineStoreProvider);
  }
}

int _sum(Directory directory) {
  if (!directory.existsSync()) {
    return 0;
  }
  var total = 0;
  for (final FileSystemEntity entity in directory.listSync(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is File) {
      total += entity.statSync().size;
    }
  }
  return total;
}

Object _asError(Object error) {
  if (error is Failure || error is Exception || error is Error) {
    return error;
  }
  return Exception(error.toString());
}

String _headroomLabel(HeadroomState headroom) {
  return switch (headroom) {
    HeadroomState.ample => Copy.settingsHeadroomAmple,
    HeadroomState.low => Copy.settingsHeadroomLow,
    HeadroomState.critical => Copy.settingsHeadroomCritical,
  };
}
