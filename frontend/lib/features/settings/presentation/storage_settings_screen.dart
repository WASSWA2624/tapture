import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/cache_cleanup.dart';
import 'package:tapture/core/files/folder_picker.dart';
import 'package:tapture/core/files/folder_usage.dart';
import 'package:tapture/core/files/storage_guard.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/files/volume_stats.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/projects/projects.dart'
    show Project, projectRepositoryProvider;

import '../domain/setting_keys.dart';
import '../settings.dart' show SettingsStore;
import 'offline_switch.dart';
import 'setting_choice.dart';

// The notifier is private so this file holds one public class (FE-STR-06).
// ignore_for_file: library_private_types_in_public_api

/// Space used per project, free headroom, cache clear and retention.
///
/// Where no storage folder can be opened (a browser, or a refused
/// folder) the page keeps retention and the recycle bin, and leaves the
/// usage out. A storage folder whose free space cannot be read shows the
/// error with a retry.
class StorageSettingsScreen extends ConsumerWidget {
  /// Creates the storage screen.
  const StorageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final AsyncValue<_StorageView> value = ref.watch(storageSettingsProvider);
    return AppPage(
      title: localCopy.settingsStorageTitle,
      inset: false,
      body: AsyncValueView<_StorageView>(
        value: value,
        isEmpty: (_StorageView view) => !view.showUsage,
        onRetry: () => ref.invalidate(storageSettingsProvider),
        empty: () {
          final LocalizedCopy localCopy = Copy.of(context);

          return AppEmptyState(
            icon: AppIcons.folder,
            headline: localCopy.settingsStorageEmptyHeadline,
            message: localCopy.settingsStorageEmptyMessage,
            actionLabel: localCopy.navProjects,
            onAction: () => context.go(RoutePaths.projects),
          );
        },
        data: (_StorageView view) {
          final LocalizedCopy localCopy = Copy.of(context);

          final _StorageSettings notifier = ref.read(
            storageSettingsProvider.notifier,
          );
          final VolumeStats? volume = view.volume;
          final HeadroomState? headroom = view.headroom;
          final Failure? volumeFailure = view.volumeFailure;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (volumeFailure != null) ...<Widget>[
                AppSectionHeader(title: localCopy.settingsHeadroomHeader),
                AppErrorState(
                  key: const ValueKey<String>('storage-volume-error'),
                  failure: volumeFailure,
                  onRetry: () => ref.invalidate(storageSettingsProvider),
                ),
              ] else if (volume != null && headroom != null) ...<Widget>[
                AppSectionHeader(title: localCopy.settingsHeadroomHeader),
                if (headroom == HeadroomState.ample)
                  AppListTile(title: localCopy.settingsHeadroomAmple)
                else
                  AppBanner(
                    key: const ValueKey<String>('storage-headroom'),
                    message: _headroomLabel(headroom, localCopy),
                    icon: AppIcons.warning,
                    tone: headroom == HeadroomState.critical
                        ? SnackTone.error
                        : SnackTone.warning,
                  ),
                AppListTile(
                  title: localCopy.settingsVolumeTotal,
                  subtitle: localCopy.fileSize(volume.totalBytes),
                ),
                AppListTile(
                  title: localCopy.settingsVolumeUsed,
                  subtitle: localCopy.fileSize(volume.usedBytes),
                ),
                AppListTile(
                  title: localCopy.settingsVolumeAvailable,
                  subtitle: localCopy.fileSize(volume.freeBytes),
                ),
              ],
              if (view.projects.isNotEmpty) ...<Widget>[
                AppSectionHeader(title: localCopy.settingsProjectsHeader),
                for (final _ProjectUse use in view.projects)
                  AppListTile(
                    title: use.name,
                    subtitle: localCopy.settingsProjectUse(
                      photos: localCopy.fileSize(use.photosBytes),
                      documents: localCopy.fileSize(use.documentsBytes),
                      audio: localCopy.fileSize(use.audioBytes),
                      exports: localCopy.fileSize(use.exportsBytes),
                    ),
                  ),
              ],
              if (view.rootFailure case final Failure rootFailure)
                AppListTile(
                  key: const ValueKey<String>('storage-root-failed'),
                  leading: const Icon(AppIcons.error),
                  title: localCopy.settingsStorageRoot,
                  subtitle: localCopy.failureMessage(rootFailure),
                  onTap: ref.read(folderPickerProvider).canPick
                      ? () {
                          unawaited(notifier.chooseRoot(context));
                        }
                      : null,
                ),
              if (view.rootPath.isNotEmpty) ...<Widget>[
                AppSectionHeader(title: localCopy.settingsCache),
                AppListTile(
                  title: localCopy.settingsStorageRoot,
                  subtitle: view.rootPath,
                  onTap: ref.read(folderPickerProvider).canPick
                      ? () {
                          unawaited(notifier.chooseRoot(context));
                        }
                      : null,
                ),
                AppListTile(
                  title: localCopy.settingsClearCache,
                  subtitle: localCopy.settingsCacheSize(
                    localCopy.fileSize(view.cacheBytes),
                  ),
                  onTap: () {
                    unawaited(notifier.clearCache(context));
                  },
                ),
              ],
              AppSectionHeader(title: localCopy.settingsRetentionHeader),
              SettingChoice<int>(
                key: const ValueKey<String>('storage-retention'),
                label: localCopy.settingsRetention,
                effect: localCopy.settingsRetentionEffect,
                value: view.retentionDays,
                options: <Choice<int>>[
                  for (final int days in _retentionChoices)
                    Choice<int>(days, localCopy.settingsRetentionDays(days)),
                ],
                onChanged: (int days) {
                  unawaited(notifier.setRetention(days));
                },
              ),
              AppListTile(
                key: const ValueKey<String>('storage-recycle-bin'),
                title: localCopy.recycleBinTitle,
                subtitle: localCopy.recycleBinSettingsSubtitle,
                trailing: const Icon(AppIcons.open),
                onTap: () => context.go(RoutePaths.recycleBin),
              ),
              AppListTile(
                key: const ValueKey<String>('storage-check-files'),
                title: localCopy.storageCheckTitle,
                subtitle: localCopy.storageCheckSubtitle,
                trailing: const Icon(AppIcons.open),
                onTap: () => context.go(RoutePaths.settingsStorageCheck),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The retention windows on offer, from `AppConstants`.
List<int> get _retentionChoices => <int>[
  AppConstants.logging.retentionDays,
  AppConstants.retention.days,
];

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
              volumeFailure: null,
              rootFailure: null,
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
  Failure? volumeFailure,
  Failure? rootFailure,
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
        volumeFailure: null,
        rootFailure: null,
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
    final LocalizedCopy localCopy = Copy.of(context);

    final bool confirmed = await showAppConfirm(
      context,
      title: localCopy.settingsClearCacheTitle,
      message: localCopy.settingsClearCacheMessage,
      confirmLabel: localCopy.settingsClearCache,
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
          title: localCopy.settingsClearCache,
          message: Copy.of(context).failureMessage(pruned.failure),
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
        volumeFailure: current.volumeFailure,
        rootFailure: current.rootFailure,
        rootPath: current.rootPath,
        cacheBytes: nextCache < 0 ? 0 : nextCache,
        retentionDays: current.retentionDays,
        showUsage: current.showUsage,
      ));
      return;
    }
    state = AsyncData<_StorageView>(await _load());
  }

  /// Stores [days] as the retention window, then reloads.
  Future<void> setRetention(int days) async {
    final SettingsStore store = await _settings();
    await store.write(SettingKeys.retentionDays, days);
    if (!ref.mounted) {
      return;
    }
    state = AsyncData<_StorageView>(await _load());
  }

  /// Picks a folder, probes it, persists the path, then reloads.
  Future<void> chooseRoot(BuildContext context) async {
    final LocalizedCopy localCopy = Copy.of(context);

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
            title: localCopy.settingsStorageRoot,
            message: Copy.of(context).failureMessage(failure),
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
              title: localCopy.settingsStorageRoot,
              message: Copy.of(context).failureMessage(probed.failure),
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
              title: localCopy.settingsStorageRoot,
              message: Copy.of(context).failureMessage(written.failure),
            );
          }
          return;
        }
        // The running app keeps writing under the folder it opened with, so
        // nothing is split across two roots; the new one applies on restart.
        if (context.mounted) {
          showAppSnack(context, localCopy.settingsStorageRootAfterRestart);
        }
    }
  }

  Future<_StorageView> _load() async {
    final SettingsStore store = await _settings();
    final int retentionDays = store.read(SettingKeys.retentionDays);
    final StorageRoot root = await _root();
    final Result<Directory> resolved;
    try {
      resolved = await root.resolve();
    } on Object {
      // A browser has no documents folder and its lookup throws: keep
      // retention and leave usage out rather than failing the page.
      return _usageOnly(retentionDays);
    }
    switch (resolved) {
      case FailureResult<Directory>(:final Failure failure):
        // The folder cannot be opened: keep the chooser so another one can
        // be picked, with the reason beneath it.
        return (
          projects: const <_ProjectUse>[],
          headroom: null,
          volume: null,
          volumeFailure: null,
          rootFailure: failure,
          rootPath: '',
          cacheBytes: 0,
          retentionDays: retentionDays,
          showUsage: true,
        );
      case Success<Directory>(:final Directory value):
        final Result<VolumeStats> volume = await (await _guard()).volume();
        final ({List<_ProjectUse> projects, int cacheBytes}) usage =
            await _usage(value.path);
        // A volume whose free space is unreadable shows the error with a
        // retry in the headroom block; usage and the chooser stay.
        return (
          projects: usage.projects,
          headroom: switch (volume) {
            Success<VolumeStats>(value: final VolumeStats stats) =>
              StorageGuard.classify(stats.freeBytes),
            FailureResult<VolumeStats>() => null,
          },
          volume: switch (volume) {
            Success<VolumeStats>(value: final VolumeStats stats) => stats,
            FailureResult<VolumeStats>() => null,
          },
          volumeFailure: switch (volume) {
            Success<VolumeStats>() => null,
            FailureResult<VolumeStats>(:final Failure failure) => failure,
          },
          rootFailure: null,
          rootPath: value.path,
          cacheBytes: usage.cacheBytes,
          retentionDays: retentionDays,
          showUsage: true,
        );
    }
  }

  /// The cache, and the photos, documents, audio and exports of every
  /// project with a folder under [rootPath], archived ones included. One
  /// walk off the UI isolate through core/files (FE-PERF-02, FE-STR-11).
  Future<({List<_ProjectUse> projects, int cacheBytes})> _usage(
    String rootPath,
  ) async {
    final List<Project> projects = await ref
        .read(projectRepositoryProvider)
        .watchAll(includeArchived: true)
        .first;
    final List<({String name, String base})> folders =
        <({String name, String base})>[
          for (final Project project in projects)
            if (project.folderName.trim().isNotEmpty)
              (
                name: project.name,
                base: '$rootPath/projects/${project.folderName.trim()}',
              ),
        ];
    final List<String> paths = <String>[
      '$rootPath/.cache',
      for (final ({String name, String base}) folder in folders) ...<String>[
        folder.base,
        '${folder.base}/photos',
        '${folder.base}/documents',
        '${folder.base}/audio',
        '${folder.base}/exports',
      ],
    ];
    final List<int?> sizes = (await measureFolders(paths)).fold(
      (Failure _) => List<int?>.filled(paths.length, null),
      (List<int?> measured) => measured,
    );
    final List<_ProjectUse> uses = <_ProjectUse>[];
    for (int index = 0; index < folders.length; index++) {
      final int at = 1 + index * 5;
      if (sizes[at] == null) {
        continue;
      }
      uses.add((
        name: folders[index].name,
        photosBytes: sizes[at + 1] ?? 0,
        documentsBytes: sizes[at + 2] ?? 0,
        audioBytes: sizes[at + 3] ?? 0,
        exportsBytes: sizes[at + 4] ?? 0,
      ));
    }
    return (projects: uses, cacheBytes: sizes.first ?? 0);
  }

  _StorageView _usageOnly(int retentionDays) {
    return (
      projects: const <_ProjectUse>[],
      headroom: null,
      volume: null,
      volumeFailure: null,
      rootFailure: null,
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

Object _asError(Object error) {
  if (error is Failure || error is Exception || error is Error) {
    return error;
  }
  return Exception(error.toString());
}

String _headroomLabel(HeadroomState headroom, LocalizedCopy copy) {
  return switch (headroom) {
    HeadroomState.ample => copy.settingsHeadroomAmple,
    HeadroomState.low => copy.settingsHeadroomLow,
    HeadroomState.critical => copy.settingsHeadroomCritical,
  };
}
