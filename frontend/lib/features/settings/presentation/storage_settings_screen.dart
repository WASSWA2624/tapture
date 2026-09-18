import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/device/device_identity.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/cache_cleanup.dart';
import 'package:tapture/core/files/storage_guard.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/setting_keys.dart';
import '../settings.dart' show SettingsStore;

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
            icon: Icons.folder_outlined,
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
              AppListTile(
                title: _headroomLabel(view.headroom),
                subtitle: Copy.settingsStorageSubtitle,
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
              const AppSectionHeader(title: Copy.settingsProjectsHeader),
              for (final _ProjectUse project in view.projects)
                AppListTile(
                  title: project.name,
                  subtitle: Copy.settingsProjectUse(
                    photos: Copy.fileSize(project.photosBytes),
                    documents: Copy.fileSize(project.documentsBytes),
                    audio: Copy.fileSize(project.audioBytes),
                    exports: Copy.fileSize(project.exportsBytes),
                  ),
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
}) {
  return storageSettingsProvider.overrideWith(
    () => _StorageSettings.withDeps(
      storageRoot: storageRoot,
      storageGuard: storageGuard,
      store: store,
      cacheCleanup: cacheCleanup,
      failWith: failWith,
      pending: pending,
      empty: empty,
      snapshot: projects == null && cacheBytes == null
          ? null
          : (
              projects: projects ?? const <_ProjectUse>[],
              headroom: headroom ?? HeadroomState.ample,
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
  HeadroomState headroom,
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
      _failWith = null,
      _pending = false,
      _empty = false,
      _snapshot = null;

  _StorageSettings.withDeps({
    this._storageRoot,
    this._storageGuard,
    this._store,
    this._cacheCleanup,
    this._failWith,
    this._pending = false,
    this._empty = false,
    this._snapshot,
  });

  final StorageRoot? _storageRoot;
  final StorageGuard? _storageGuard;
  final SettingsStore? _store;
  final CacheCleanup? _cacheCleanup;
  final Object? _failWith;
  final bool _pending;
  final bool _empty;
  final _StorageView? _snapshot;
  SettingsStore? _openedStore;

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
        headroom: HeadroomState.ample,
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

  Future<_StorageView> _load() async {
    final SettingsStore store = await _settings();
    final int retentionDays = store.read(SettingKeys.retentionDays);
    try {
      final StorageRoot root = await _root();
      final Result<HeadroomState> headroom = await (await _guard()).check();
      final HeadroomState state = switch (headroom) {
        Success<HeadroomState>(:final HeadroomState value) => value,
        FailureResult<HeadroomState>() => HeadroomState.ample,
      };
      final Result<Directory> resolved = await root.resolve();
      switch (resolved) {
        case FailureResult<Directory>():
          return _usageOnly(retentionDays);
        case Success<Directory>(:final Directory value):
          return (
            projects: _projectUse(value),
            headroom: state,
            cacheBytes: _sum(Directory('${value.path}/.cache')),
            retentionDays: retentionDays,
            showUsage: true,
          );
      }
    } on Object {
      return _usageOnly(retentionDays);
    }
  }

  _StorageView _usageOnly(int retentionDays) {
    return (
      projects: const <_ProjectUse>[],
      headroom: HeadroomState.ample,
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
    final SettingsStore? opened = _openedStore;
    if (opened != null) {
      return opened;
    }
    const SystemClock clock = SystemClock();
    return _openedStore = await SettingsStore.open(
      db: AppDatabase.open(),
      deviceId: await deviceId(clock: clock, ids: UuidV7Service(clock)),
      clock: clock,
    );
  }
}

List<_ProjectUse> _projectUse(Directory root) {
  final Directory projects = Directory('${root.path}/projects');
  if (!projects.existsSync()) {
    return const <_ProjectUse>[];
  }
  final List<_ProjectUse> used = <_ProjectUse>[];
  for (final FileSystemEntity entity in projects.listSync(followLinks: false)) {
    if (entity is! Directory) {
      continue;
    }
    used.add((
      name: _folderName(entity),
      photosBytes: _sum(Directory('${entity.path}/photos')),
      documentsBytes: _sum(Directory('${entity.path}/documents')),
      audioBytes: _sum(Directory('${entity.path}/audio')),
      exportsBytes: _sum(Directory('${entity.path}/exports')),
    ));
  }
  used.sort((_ProjectUse a, _ProjectUse b) => a.name.compareTo(b.name));
  return used;
}

String _folderName(Directory directory) {
  final List<String> parts = directory.uri.pathSegments
      .where((String part) => part.isNotEmpty)
      .toList();
  return parts.isEmpty ? directory.path : parts.last;
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
  if (error is Exception || error is Error) {
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
