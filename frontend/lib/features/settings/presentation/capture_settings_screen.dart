import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/device/device_identity.dart';
import 'package:tapture/core/files/photo_path_builder.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/setting_key.dart';
import '../domain/setting_keys.dart';
import '../settings.dart' show SettingsStore;

// The notifier is private so this file holds one public class (FE-STR-06).
// ignore_for_file: library_private_types_in_public_api

/// Capture defaults: camera, dates, GPS, quality, folders and names.
class CaptureSettingsScreen extends ConsumerWidget {
  /// Creates the capture defaults screen.
  const CaptureSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<_CaptureView> value = ref.watch(captureSettingsProvider);
    return AppPage(
      title: Copy.navCapture,
      body: AsyncValueView<_CaptureView>(
        value: value,
        isEmpty: (_CaptureView view) => view.missing,
        onRetry: () => ref.invalidate(captureSettingsProvider),
        empty: () {
          return const AppEmptyState(
            icon: Icons.photo_camera_outlined,
            headline: Copy.settingsCaptureEmptyHeadline,
            message: Copy.settingsCaptureEmptyMessage,
          );
        },
        data: (_CaptureView view) {
          final _CaptureSettings notifier = ref.read(
            captureSettingsProvider.notifier,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const AppSectionHeader(title: Copy.navCapture),
              AppListTile(
                title: Copy.settingsCamera,
                subtitle: Copy.settingsCameraSubtitle(
                  _cameraLabel(view.cameraMode),
                ),
                onTap: () {
                  unawaited(
                    notifier.write(SettingKeys.cameraMode, view.cameraMode),
                  );
                },
              ),
              AppListTile(
                title: Copy.settingsAutoFillDates,
                subtitle: Copy.settingsAutoFillDatesEffect,
                selected: view.autoFillDates,
                onTap: () {
                  unawaited(
                    notifier.write(
                      SettingKeys.autoFillDates,
                      !view.autoFillDates,
                    ),
                  );
                },
              ),
              AppListTile(
                title: Copy.settingsGps,
                subtitle: Copy.settingsGpsWhyOff,
                selected: view.gpsEnabled,
                onTap: () {
                  unawaited(
                    notifier.write(SettingKeys.gpsEnabled, !view.gpsEnabled),
                  );
                },
              ),
              AppListTile(
                title: Copy.settingsPhotoQuality,
                subtitle: Copy.settingsPhotoQualitySubtitle(
                  _qualityLabel(view.photoQuality),
                ),
                onTap: () {
                  unawaited(
                    notifier.write(
                      SettingKeys.photoQuality,
                      _nextQuality(view.photoQuality),
                    ),
                  );
                },
              ),
              AppListTile(
                title: Copy.settingsFolderStrategy,
                subtitle: Copy.settingsFolderStrategySubtitle(
                  _strategyLabel(view.folderStrategy),
                ),
                onTap: () {
                  unawaited(
                    notifier.write(
                      SettingKeys.folderStrategy,
                      _nextStrategy(view.folderStrategy),
                    ),
                  );
                },
              ),
              AppListTile(
                title: Copy.settingsNamingPattern,
                subtitle: Copy.settingsNamingSubtitle(view.namingPattern),
                onTap: () {
                  unawaited(
                    notifier.write(
                      SettingKeys.namingPattern,
                      view.namingPattern,
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Injects [store] so tests never open a database (FE-TEST-03).
Override captureSettingsOverride({
  SettingsStore? store,
  bool missing = false,
  Object? failWith,
  bool pending = false,
}) {
  return captureSettingsProvider.overrideWith(
    () => _CaptureSettings.withStore(
      store,
      missing: missing,
      failWith: failWith,
      pending: pending,
    ),
  );
}

/// Capture defaults on this device. A failed read shows immediately —
/// Riverpod's default backoff would keep the screen in [AsyncLoading]
/// (FE-STATE-11).
final AsyncNotifierProvider<_CaptureSettings, _CaptureView>
captureSettingsProvider = AsyncNotifierProvider<_CaptureSettings, _CaptureView>(
  _CaptureSettings.new,
  retry: (int _, Object _) => null,
);

typedef _CaptureView = ({
  bool missing,
  String cameraMode,
  bool autoFillDates,
  bool gpsEnabled,
  int photoQuality,
  String folderStrategy,
  String namingPattern,
});

class _CaptureSettings extends AsyncNotifier<_CaptureView> {
  _CaptureSettings()
    : _injected = null,
      _missing = false,
      _failWith = null,
      _pending = false;

  _CaptureSettings.withStore(
    this._injected, {
    this._missing = false,
    this._failWith,
    this._pending = false,
  });

  final SettingsStore? _injected;
  final bool _missing;
  final Object? _failWith;
  final bool _pending;
  SettingsStore? _opened;

  @override
  Future<_CaptureView> build() async {
    if (_pending) {
      return Completer<_CaptureView>().future;
    }
    final Object? failWith = _failWith;
    if (failWith != null) {
      throw _asError(failWith);
    }
    if (_missing) {
      return (
        missing: true,
        cameraMode: SettingKeys.cameraMode.defaultValue,
        autoFillDates: SettingKeys.autoFillDates.defaultValue,
        gpsEnabled: SettingKeys.gpsEnabled.defaultValue,
        photoQuality: SettingKeys.photoQuality.defaultValue,
        folderStrategy: SettingKeys.folderStrategy.defaultValue,
        namingPattern: SettingKeys.namingPattern.defaultValue,
      );
    }
    return _snapshot(await _store());
  }

  /// Persists [value] and rebuilds after the write commits.
  Future<void> write<T>(SettingKey<T> key, T value) async {
    final SettingsStore store = await _store();
    await store.write(key, value);
    state = AsyncData<_CaptureView>(_snapshot(store));
  }

  Future<SettingsStore> _store() async {
    final SettingsStore? injected = _injected;
    if (injected != null) {
      return injected;
    }
    final SettingsStore? opened = _opened;
    if (opened != null) {
      return opened;
    }
    const SystemClock clock = SystemClock();
    return _opened = await SettingsStore.open(
      db: AppDatabase.open(),
      deviceId: await deviceId(clock: clock, ids: UuidV7Service(clock)),
      clock: clock,
    );
  }

  _CaptureView _snapshot(SettingsStore store) {
    return (
      missing: false,
      cameraMode: store.read(SettingKeys.cameraMode),
      autoFillDates: store.read(SettingKeys.autoFillDates),
      gpsEnabled: store.read(SettingKeys.gpsEnabled),
      photoQuality: store.read(SettingKeys.photoQuality),
      folderStrategy: store.read(SettingKeys.folderStrategy),
      namingPattern: store.read(SettingKeys.namingPattern),
    );
  }
}

Object _asError(Object error) {
  if (error is Exception || error is Error) {
    return error;
  }
  return Exception(error.toString());
}

String _cameraLabel(String mode) {
  return mode == SettingKeys.cameraMode.defaultValue
      ? Copy.settingsCameraPhoto
      : mode;
}

String _qualityLabel(int quality) {
  if (quality == AppConstants.images.thumbnailQuality) {
    return Copy.settingsQualitySmaller;
  }
  return Copy.settingsQualityStandard;
}

int _nextQuality(int quality) {
  if (quality == AppConstants.images.quality) {
    return AppConstants.images.thumbnailQuality;
  }
  return AppConstants.images.quality;
}

String _strategyLabel(String strategy) {
  return switch (strategy) {
    'byTemplate' => Copy.settingsFolderByTemplate,
    'byCaptureDate' => Copy.settingsFolderByDate,
    'flat' => Copy.settingsFolderFlat,
    _ => Copy.settingsFolderByContext,
  };
}

String _nextStrategy(String strategy) {
  final List<String> names = PhotoFolderStrategy.values
      .map((PhotoFolderStrategy value) => value.name)
      .toList();
  final int index = names.indexOf(strategy);
  return names[(index + 1) % names.length];
}
