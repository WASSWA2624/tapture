import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/photo_path_builder.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/setting_key.dart';
import '../domain/setting_keys.dart';
import '../settings.dart' show SettingsStore;
import 'offline_switch.dart';
import 'setting_choice.dart';
import 'settings_disclosure.dart';

// The notifier is private so this file holds one public class (FE-STR-06).
// ignore_for_file: library_private_types_in_public_api

/// Capture defaults: camera, dates, location, quality, folders and names.
///
/// Primary controls stay visible; advanced groups keep their stored values.
class CaptureSettingsScreen extends ConsumerWidget {
  /// Creates the capture defaults screen.
  const CaptureSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final AsyncValue<_CaptureView> value = ref.watch(captureSettingsProvider);
    return AppPage(
      title: localCopy.settingsCaptureTitle,
      inset: false,
      body: AsyncValueView<_CaptureView>(
        value: value,
        isEmpty: (_CaptureView view) => view.missing,
        onRetry: () => ref.invalidate(captureSettingsProvider),
        empty: () {
          final LocalizedCopy localCopy = Copy.of(context);

          return AppEmptyState(
            icon: AppIcons.camera,
            headline: localCopy.settingsCaptureEmptyHeadline,
            message: localCopy.settingsCaptureEmptyMessage,
            actionLabel: localCopy.tryAgain,
            onAction: () => ref.invalidate(captureSettingsProvider),
          );
        },
        data: (_CaptureView view) {
          final LocalizedCopy localCopy = Copy.of(context);

          final _CaptureSettings notifier = ref.read(
            captureSettingsProvider.notifier,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SettingChoice<String>(
                key: const ValueKey<String>('capture-camera'),
                label: localCopy.settingsCamera,
                effect: localCopy.settingsCameraEffect,
                value: view.cameraMode,
                options: <Choice<String>>[
                  Choice<String>('photo', localCopy.settingsCameraPhoto),
                  Choice<String>('document', localCopy.settingsCameraDocument),
                ],
                onChanged: (String next) {
                  unawaited(
                    _writeSetting(
                      context,
                      notifier,
                      SettingKeys.cameraMode,
                      next,
                    ),
                  );
                },
              ),
              AppSwitchTile(
                title: localCopy.settingsAutoFillDates,
                description: localCopy.settingsAutoFillDatesEffect,
                value: view.autoFillDates,
                onChanged: (bool value) {
                  unawaited(
                    _writeSetting(
                      context,
                      notifier,
                      SettingKeys.autoFillDates,
                      value,
                    ),
                  );
                },
              ),
              // The one location switch (FE-SIMP-10). Privacy links here.
              AppSwitchTile(
                key: const ValueKey<String>('capture-gps'),
                title: localCopy.gpsPrivacyCapture,
                description: localCopy.settingsGpsWhyOff,
                value: view.gpsEnabled,
                onChanged: (bool value) {
                  unawaited(
                    _writeSetting(
                      context,
                      notifier,
                      SettingKeys.gpsEnabled,
                      value,
                    ),
                  );
                },
              ),
              SettingsDisclosure(
                id: 'capture-photo-files',
                title: localCopy.settingsPhotoFiles,
                summary: localCopy.settingsPhotoFilesSummary(
                  view.photoQuality == AppConstants.images.thumbnailQuality
                      ? localCopy.settingsQualitySmaller
                      : localCopy.settingsQualityStandard,
                  _strategyLabel(view.folderStrategy, localCopy),
                ),
                children: <Widget>[
                  SettingChoice<int>(
                    key: const ValueKey<String>('capture-quality'),
                    alwaysSheet: true,
                    label: localCopy.settingsPhotoQuality,
                    effect: localCopy.settingsPhotoQualityEffect,
                    value: view.photoQuality,
                    options: <Choice<int>>[
                      Choice<int>(
                        AppConstants.images.quality,
                        localCopy.settingsQualityStandard,
                      ),
                      Choice<int>(
                        AppConstants.images.thumbnailQuality,
                        localCopy.settingsQualitySmaller,
                      ),
                    ],
                    onChanged: (int next) {
                      unawaited(
                        _writeSetting(
                          context,
                          notifier,
                          SettingKeys.photoQuality,
                          next,
                        ),
                      );
                    },
                  ),
                  SettingChoice<String>(
                    key: const ValueKey<String>('capture-folders'),
                    alwaysSheet: true,
                    label: localCopy.settingsFolderStrategy,
                    effect: localCopy.settingsFolderStrategyNewFilesOnly,
                    value: view.folderStrategy,
                    options: <Choice<String>>[
                      for (final PhotoFolderStrategy strategy
                          in PhotoFolderStrategy.values)
                        Choice<String>(
                          strategy.name,
                          _strategyLabel(strategy.name, localCopy),
                        ),
                    ],
                    onChanged: (String next) {
                      unawaited(
                        _writeSetting(
                          context,
                          notifier,
                          SettingKeys.folderStrategy,
                          next,
                        ),
                      );
                    },
                  ),
                  AppListTile(
                    title: localCopy.settingsNamingPattern,
                    subtitle: localCopy.settingsNamingSubtitle(
                      view.namingPattern,
                    ),
                    trailing: const Icon(AppIcons.edit),
                    onTap: () {
                      unawaited(
                        _editNaming(context, notifier, view.namingPattern),
                      );
                    },
                  ),
                ],
              ),
              SettingsDisclosure(
                id: 'capture-project-contexts',
                title: localCopy.settingsProjectContexts,
                summary: localCopy.settingsProjectContextsSummary(
                  view.autoClear
                      ? localCopy.settingsContextIdleOption(
                          view.idleSeconds ~/ 60,
                        )
                      : localCopy.projectOff,
                  view.movementPrompt
                      ? localCopy.settingsContextDistanceOption(
                          view.movementMetres,
                        )
                      : localCopy.projectOff,
                ),
                children: <Widget>[
                  AppSwitchTile(
                    title: localCopy.settingsContextAutoClear,
                    description: localCopy.settingsContextAutoClearEffect,
                    value: view.autoClear,
                    onChanged: (bool value) {
                      unawaited(
                        _writeSetting(
                          context,
                          notifier,
                          SettingKeys.contextAutoClearEnabled,
                          value,
                        ),
                      );
                    },
                  ),
                  if (view.autoClear)
                    SettingChoice<int>(
                      key: const ValueKey<String>('capture-idle'),
                      alwaysSheet: true,
                      label: localCopy.settingsContextIdle,
                      effect: localCopy.settingsContextIdleEffect,
                      value: view.idleSeconds,
                      options: <Choice<int>>[
                        for (final int seconds
                            in AppConstants.context.idleChoices)
                          Choice<int>(
                            seconds,
                            localCopy.settingsContextIdleOption(seconds ~/ 60),
                          ),
                      ],
                      onChanged: (int next) {
                        unawaited(
                          _writeSetting(
                            context,
                            notifier,
                            SettingKeys.contextAutoClearSeconds,
                            next,
                          ),
                        );
                      },
                    ),
                  AppSwitchTile(
                    title: localCopy.settingsContextMovement,
                    description: localCopy.settingsContextMovementEffect,
                    value: view.movementPrompt,
                    onChanged: (bool value) {
                      unawaited(
                        _writeSetting(
                          context,
                          notifier,
                          SettingKeys.contextMovementPromptEnabled,
                          value,
                        ),
                      );
                    },
                  ),
                  if (view.movementPrompt)
                    SettingChoice<int>(
                      key: const ValueKey<String>('capture-distance'),
                      alwaysSheet: true,
                      label: localCopy.settingsContextDistance,
                      effect: localCopy.settingsContextDistanceEffect,
                      value: view.movementMetres,
                      options: <Choice<int>>[
                        for (final int metres
                            in AppConstants.context.distanceChoices)
                          Choice<int>(
                            metres,
                            localCopy.settingsContextDistanceOption(metres),
                          ),
                      ],
                      onChanged: (int next) {
                        unawaited(
                          _writeSetting(
                            context,
                            notifier,
                            SettingKeys.contextMovementMetres,
                            next,
                          ),
                        );
                      },
                    ),
                ],
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
  bool autoClear,
  int idleSeconds,
  bool movementPrompt,
  int movementMetres,
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
        autoClear: SettingKeys.contextAutoClearEnabled.defaultValue,
        idleSeconds: SettingKeys.contextAutoClearSeconds.defaultValue,
        movementPrompt: SettingKeys.contextMovementPromptEnabled.defaultValue,
        movementMetres: SettingKeys.contextMovementMetres.defaultValue,
      );
    }
    return _snapshot(await _store());
  }

  /// Persists [value] and rebuilds after the write commits.
  Future<Result<void>> write<T>(SettingKey<T> key, T value) async {
    final SettingsStore store = await _store();
    final Result<void> result = await store.write(key, value);
    if (ref.mounted && result is Success<void>) {
      state = AsyncData<_CaptureView>(_snapshot(store));
    }
    return result;
  }

  Future<SettingsStore> _store() async {
    final SettingsStore? injected = _injected;
    if (injected != null) {
      return injected;
    }
    return ref.read(offlineStoreProvider);
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
      autoClear: store.read(SettingKeys.contextAutoClearEnabled),
      idleSeconds: store.read(SettingKeys.contextAutoClearSeconds),
      movementPrompt: store.read(SettingKeys.contextMovementPromptEnabled),
      movementMetres: store.read(SettingKeys.contextMovementMetres),
    );
  }
}

Object _asError(Object error) {
  if (error is Exception || error is Error) {
    return error;
  }
  return Exception(error.toString());
}

Future<void> _writeSetting<T>(
  BuildContext context,
  _CaptureSettings notifier,
  SettingKey<T> key,
  T value,
) async {
  final Result<void> result = await notifier.write(key, value);
  if (result case FailureResult<void>(
    :final Failure failure,
  ) when context.mounted) {
    showAppSnack(
      context,
      failure.message,
      localizedMessage: failure.explanation,
      tone: SnackTone.error,
    );
  }
}

Future<void> _editNaming(
  BuildContext context,
  _CaptureSettings notifier,
  String current,
) async {
  final LocalizedCopy localCopy = Copy.of(context);

  final TextEditingController controller = TextEditingController(text: current);
  await showAppSheet<void>(
    context,
    title: localCopy.settingsNamingEdit,
    builder: (BuildContext sheetContext) {
      final LocalizedCopy localCopy = Copy.of(sheetContext);

      return AppForm(
        fields: <Widget>[
          AppTextField(
            label: localCopy.settingsNamingPattern,
            helper: localCopy.settingsNamingPatternEffect,
            controller: controller,
            dictation: false,
          ),
        ],
        submitLabel: localCopy.save,
        onSubmit: () async {
          final Result<void> result = await notifier.write(
            SettingKeys.namingPattern,
            controller.text,
          );
          if (result case FailureResult<void>(:final Failure failure)) {
            if (sheetContext.mounted) {
              showAppSnack(
                sheetContext,
                failure.message,
                localizedMessage: failure.explanation,
                tone: SnackTone.error,
              );
            }
            return false;
          }
          if (sheetContext.mounted) {
            Navigator.of(sheetContext).pop();
          }
          return true;
        },
      );
    },
  );
  controller.dispose();
}

String _strategyLabel(String strategy, LocalizedCopy copy) {
  return switch (strategy) {
    'byTemplate' => copy.settingsFolderByTemplate,
    'byCaptureDate' => copy.settingsFolderByDate,
    'flat' => copy.settingsFolderFlat,
    _ => copy.settingsFolderByContext,
  };
}
