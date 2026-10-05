import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/speech/speech.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_chip.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/choice.dart';

import 'setting_choice.dart';
import 'speech_models_view.dart';
import 'speech_settings_providers.dart';

/// On-device speech on the Language screen (spec §30.4.2, §57): which
/// engine turns speech into text, that it works offline, the one quality
/// choice, and the model files with Verify, import and removal.
class SpeechSettingsSection extends ConsumerWidget {
  /// Creates the section.
  const SpeechSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);
    final SpeechReadiness readiness = ref.watch(speechReadinessProvider);
    final bool platformOnDevice =
        ref.watch(speechPlatformOnDeviceProvider).value ?? false;
    final AsyncValue<SpeechModelsView> models = ref.watch(speechModelsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(title: localCopy.settingsSpeechSection),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: AppChip(
                  icon: AppIcons.offline,
                  label: localCopy.speechOfflineBadge,
                ),
              ),
              ..._engineLines(context, readiness, platformOnDevice),
            ],
          ),
        ),
        SettingChoice<SpeechQuality>(
          label: localCopy.settingsSpeechQuality,
          effect: localCopy.settingsSpeechQualityEffect,
          value: SpeechQuality.parse(ref.watch(speechQualitySettingProvider)),
          options: <Choice<SpeechQuality>>[
            Choice<SpeechQuality>(
              SpeechQuality.auto,
              localCopy.settingsSpeechQualityAuto,
            ),
            Choice<SpeechQuality>(
              SpeechQuality.fast,
              localCopy.settingsSpeechQualityFast,
            ),
            Choice<SpeechQuality>(
              SpeechQuality.accurate,
              localCopy.settingsSpeechQualityAccurate,
            ),
          ],
          onChanged: (SpeechQuality quality) {
            unawaited(
              ref.read(speechQualitySettingProvider.notifier).set(quality),
            );
          },
        ),
        AppSectionHeader(title: localCopy.settingsSpeechModels),
        AsyncValueView<SpeechModelsView>(
          value: models,
          onRetry: () => ref.invalidate(speechModelsProvider),
          data: (SpeechModelsView view) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final SpeechModelStatus status in view.models)
                _ModelRow(
                  key: ValueKey<String>('speech-model-${status.entry.id}'),
                  status: status,
                  view: view,
                  inUse: _inUse(readiness, status.entry),
                ),
              if (view.canImport)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.x4,
                    vertical: Space.x2,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AppButton(
                      key: const ValueKey<String>('speech-model-import'),
                      label: localCopy.settingsSpeechImport,
                      icon: AppIcons.import,
                      variant: AppButtonVariant.secondary,
                      busy: view.importing,
                      onPressed: view.working == null
                          ? () => unawaited(_import(context, ref))
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// The engine dictation uses now, and why Whisper is not ready when it
  /// has been checked and is not.
  static List<Widget> _engineLines(
    BuildContext context,
    SpeechReadiness readiness,
    bool platformOnDevice,
  ) {
    final LocalizedCopy localCopy = Copy.of(context);
    final SpeechSelection? selection = readiness.selection;
    final String? engine = readiness.ready && selection != null
        ? localCopy.settingsSpeechEngineWhisper(
            _modelName(localCopy, selection.model),
          )
        : platformOnDevice
        ? localCopy.settingsSpeechEnginePlatform
        : readiness.verdict == null
        ? null
        : localCopy.settingsSpeechEngineNone;
    final Failure? failure = readiness.ready ? null : readiness.failure;
    final TextStyle style = AppText.body.copyWith(
      color: context.colors.onSurface,
    );
    return <Widget>[
      if (engine != null) ...<Widget>[
        const SizedBox(height: Space.x2),
        Text(engine, style: style),
      ],
      if (failure != null) ...<Widget>[
        const SizedBox(height: Space.x1),
        Text(
          localCopy.failureMessage(failure),
          style: AppText.caption.copyWith(color: context.colors.onSurface),
        ),
      ],
    ];
  }

  static bool _inUse(SpeechReadiness readiness, SpeechModelEntry entry) {
    final SpeechSelection? selection = readiness.selection;
    return readiness.ready &&
        selection != null &&
        (selection.model.id == entry.id || selection.vad.id == entry.id);
  }

  static Future<void> _import(BuildContext context, WidgetRef ref) async {
    final Result<SpeechModelEntry> imported = await ref
        .read(speechModelsProvider.notifier)
        .importModel();
    if (!context.mounted) {
      return;
    }
    final LocalizedCopy localCopy = Copy.of(context);
    switch (imported) {
      case Success<SpeechModelEntry>(:final SpeechModelEntry value):
        showAppSnack(
          context,
          localCopy.settingsSpeechImported(_modelName(localCopy, value)),
          tone: SnackTone.success,
        );
      case FailureResult<SpeechModelEntry>(failure: CancelledFailure()):
        return;
      case FailureResult<SpeechModelEntry>(:final Failure failure):
        showAppSnack(
          context,
          localCopy.failureMessage(failure),
          tone: SnackTone.error,
        );
    }
  }
}

/// A catalogue model's name as the operator reads it.
String _modelName(LocalizedCopy localCopy, SpeechModelEntry entry) {
  return switch (entry.tier) {
    SpeechModelTier.fast => localCopy.settingsSpeechModelFast,
    SpeechModelTier.balanced => localCopy.settingsSpeechModelBalanced,
    SpeechModelTier.accurate => localCopy.settingsSpeechModelAccurate,
    null => localCopy.settingsSpeechModelVad,
  };
}

/// One model: its name, origin, state and size, whether it is in use or
/// too large here, and Verify or Remove.
class _ModelRow extends ConsumerWidget {
  const _ModelRow({
    super.key,
    required this.status,
    required this.view,
    required this.inUse,
  });

  final SpeechModelStatus status;
  final SpeechModelsView view;
  final bool inUse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);
    final SpeechModelEntry entry = status.entry;
    final bool checked = view.verified.contains(entry.id);
    final String origin = status.imported
        ? localCopy.settingsSpeechModelImported
        : entry.asset != null
        ? localCopy.settingsSpeechModelBundled
        : localCopy.settingsSpeechModelImportOnly;
    final String state = !status.present
        ? localCopy.settingsSpeechModelMissing
        : status.damaged
        ? localCopy.settingsSpeechModelDamaged
        : checked
        ? localCopy.settingsSpeechModelVerified
        : localCopy.settingsSpeechModelPresent;
    final IconData icon = !status.present
        ? AppIcons.info
        : status.damaged
        ? AppIcons.warning
        : checked
        ? AppIcons.verified
        : AppIcons.success;
    final bool tooLarge =
        entry.kind == SpeechModelKind.whisper &&
        !SpeechModelSelector.fits(entry, view.device);
    final bool idle = view.working == null && !view.importing;
    final bool working = view.working == entry.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppListTile(
          leading: Icon(icon),
          title: _modelName(localCopy, entry),
          subtitle: localCopy.settingsSpeechModelDetail(
            origin,
            state,
            localCopy.fileSize(entry.bytes),
          ),
          wrapText: true,
          trailing: inUse
              ? AppChip(label: localCopy.settingsSpeechModelInUse)
              : null,
        ),
        if (tooLarge)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.x4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(AppIcons.warning, color: context.colors.warning),
                const SizedBox(width: Space.x2),
                Expanded(
                  child: Text(
                    localCopy.settingsSpeechTooLarge,
                    style: AppText.caption.copyWith(
                      color: context.colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (status.present || status.imported)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.x4,
              vertical: Space.x1,
            ),
            child: Wrap(
              spacing: Space.x2,
              runSpacing: Space.x2,
              children: <Widget>[
                if (status.present)
                  AppButton(
                    key: ValueKey<String>('speech-model-verify-${entry.id}'),
                    label: localCopy.settingsSpeechVerify,
                    icon: AppIcons.verified,
                    variant: AppButtonVariant.text,
                    busy: working,
                    onPressed: idle
                        ? () => unawaited(_verify(context, ref))
                        : null,
                  ),
                if (status.imported)
                  AppButton(
                    key: ValueKey<String>('speech-model-remove-${entry.id}'),
                    label: localCopy.settingsSpeechRemove,
                    icon: AppIcons.delete,
                    variant: AppButtonVariant.text,
                    onPressed: idle
                        ? () => unawaited(_remove(context, ref))
                        : null,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _verify(BuildContext context, WidgetRef ref) async {
    final Result<void> checked = await ref
        .read(speechModelsProvider.notifier)
        .verify(status.entry);
    if (!context.mounted) {
      return;
    }
    final LocalizedCopy localCopy = Copy.of(context);
    final String name = _modelName(localCopy, status.entry);
    switch (checked) {
      case Success<void>():
        showAppSnack(
          context,
          localCopy.settingsSpeechVerified(name),
          tone: SnackTone.success,
        );
      case FailureResult<void>(failure: CancelledFailure()):
        return;
      case FailureResult<void>(failure: CorruptionFailure()):
        showAppSnack(
          context,
          localCopy.settingsSpeechVerifyMismatch(name),
          tone: SnackTone.error,
        );
      case FailureResult<void>(:final Failure failure):
        showAppSnack(
          context,
          localCopy.failureMessage(failure),
          tone: SnackTone.error,
        );
    }
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final LocalizedCopy localCopy = Copy.of(context);
    final String name = _modelName(localCopy, status.entry);
    final bool confirmed = await showAppConfirm(
      context,
      title: localCopy.settingsSpeechRemoveTitle(name),
      message: localCopy.settingsSpeechRemoveMessage,
      confirmLabel: localCopy.settingsSpeechRemove,
      destructive: true,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    final Result<void> removed = await ref
        .read(speechModelsProvider.notifier)
        .remove(status.entry);
    if (!context.mounted) {
      return;
    }
    switch (removed) {
      case Success<void>():
        showAppSnack(
          context,
          localCopy.settingsSpeechRemoved(name),
          tone: SnackTone.success,
        );
      case FailureResult<void>(:final Failure failure):
        showAppSnack(
          context,
          localCopy.failureMessage(failure),
          tone: SnackTone.error,
        );
    }
  }
}
