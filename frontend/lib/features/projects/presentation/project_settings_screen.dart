import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/quality/quality.dart'
    show VerificationModeToggle;
import 'package:tapture/features/settings/settings.dart';

import '../domain/project_repository.dart';
import '../projects.dart'
    show appProjectSettingsDefaults, projectRepositoryProvider;
import 'current_project.dart';

/// Per-project switches that override the app defaults on this row.
class ProjectSettingsScreen extends ConsumerStatefulWidget {
  /// Creates the settings form. The open project comes from
  /// [currentProjectDetailsProvider]; this widget holds no id.
  const ProjectSettingsScreen({super.key});

  @override
  ConsumerState<ProjectSettingsScreen> createState() =>
      _ProjectSettingsScreenState();
}

class _ProjectSettingsScreenState extends ConsumerState<ProjectSettingsScreen> {
  TextEditingController? _high;
  TextEditingController? _medium;
  String? _boundId;

  @override
  void dispose() {
    _high?.dispose();
    _medium?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final Project? project = ref.watch(currentProjectDetailsProvider);
    if (project == null) {
      return AppPage(
        key: const ValueKey<String>('route-project-settings'),
        title: localCopy.projectSettingsTitle,
        body: AppEmptyState(
          icon: AppIcons.settings,
          headline: localCopy.projectSettingsEmptyHeadline,
          message: localCopy.projectSettingsEmptyMessage,
          actionLabel: localCopy.navProjects,
          onAction: () => context.go(RoutePaths.projects),
        ),
      );
    }
    _bind(project);
    final SettingsStore store = ref.watch(projectSettingsStoreProvider);
    final ProjectSettingsDefaults app = appProjectSettingsDefaults(store);
    final _ProjectSettingsView view = ref.watch(_projectSettingsProvider);
    return AppPage(
      key: const ValueKey<String>('route-project-settings'),
      title: localCopy.projectSettingsTitle,
      scrollable: false,
      overflow: <AppOverflowAction>[
        AppOverflowAction(
          label: localCopy.projectEditTitle,
          icon: AppIcons.info,
          onTap: () =>
              unawaited(context.push(RoutePaths.projectDetails(project.id))),
        ),
      ],
      body: AppForm(
        guardUnsaved: true,
        dirty: view.dirty,
        errors:
            Copy.of(
                  context,
                ).stateText(view.localizedSaveError, view.saveError) ==
                null
            ? const <String>[]
            : <String>[
                Copy.of(
                  context,
                ).stateText(view.localizedSaveError, view.saveError)!,
              ],
        fields: <Widget>[
          AppChoiceField<bool?>(
            label:
                '${localCopy.projectAiEnabled} · ${localCopy.projectAppDefault(_onOff(app.aiEnabled, localizedCopy: Copy.of(context)))}',
            value: view.draft.aiEnabled,
            options: <Choice<bool?>>[
              Choice<bool?>(null, localCopy.projectUseAppDefault),
              Choice<bool?>(true, localCopy.projectOn),
              Choice<bool?>(false, localCopy.projectOff),
            ],
            onChanged: (bool? value) {
              ref.read(_projectSettingsProvider.notifier).setAiEnabled(value);
            },
          ),
          AppChoiceField<bool?>(
            label:
                '${localCopy.projectDoNotSendImages} · ${localCopy.projectAppDefault(_onOff(app.doNotSendImages, localizedCopy: Copy.of(context)))}',
            value: view.draft.doNotSendImages,
            options: <Choice<bool?>>[
              Choice<bool?>(null, localCopy.projectUseAppDefault),
              Choice<bool?>(true, localCopy.projectOn),
              Choice<bool?>(false, localCopy.projectOff),
            ],
            onChanged: (bool? value) {
              ref
                  .read(_projectSettingsProvider.notifier)
                  .setDoNotSendImages(value);
            },
          ),
          AppChoiceField<bool?>(
            label:
                '${localCopy.settingsGps} · ${localCopy.projectAppDefault(_onOff(app.gpsEnabled, localizedCopy: Copy.of(context)))}',
            value: view.draft.gpsEnabled,
            options: <Choice<bool?>>[
              Choice<bool?>(null, localCopy.projectUseAppDefault),
              Choice<bool?>(true, localCopy.projectOn),
              Choice<bool?>(false, localCopy.projectOff),
            ],
            onChanged: (bool? value) {
              ref.read(_projectSettingsProvider.notifier).setGpsEnabled(value);
            },
          ),
          AppChoiceField<String?>(
            label: localCopy.settingsFolderStrategy,
            value: view.draft.folderStrategy,
            options: <Choice<String?>>[
              Choice<String?>(
                null,
                localCopy.projectAppDefault(
                  _strategyLabel(
                    app.folderStrategy,
                    localizedCopy: Copy.of(context),
                  ),
                ),
              ),
              Choice<String?>('byContext', localCopy.settingsFolderByContext),
              Choice<String?>('byTemplate', localCopy.settingsFolderByTemplate),
              Choice<String?>('byCaptureDate', localCopy.settingsFolderByDate),
              Choice<String?>('flat', localCopy.settingsFolderFlat),
            ],
            onChanged: ref
                .read(_projectSettingsProvider.notifier)
                .setFolderStrategy,
          ),
          const VerificationModeToggle(),
          AppTextField(
            label: localCopy.projectConfidenceHigh,
            controller: _high!,
            helper: localCopy.projectAppDefault(_band(app.confidenceHigh)),
            requiredness: FieldRequiredness.optional,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            errorText: Copy.of(
              context,
            ).stateText(view.localizedHighError, view.highError),
            dictation: false,
          ),
          AppTextField(
            label: localCopy.projectConfidenceMedium,
            controller: _medium!,
            helper: localCopy.projectAppDefault(_band(app.confidenceMedium)),
            requiredness: FieldRequiredness.optional,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            errorText: Copy.of(
              context,
            ).stateText(view.localizedMediumError, view.mediumError),
            dictation: false,
          ),
          AppChoiceField<String?>(
            label: localCopy.templateChoiceLabel,
            value: view.draft.templateChoice,
            options: <Choice<String?>>[
              Choice<String?>(null, localCopy.templateChoiceAuto),
              Choice<String?>('suggest', localCopy.templateChoiceSuggest),
              Choice<String?>('manual', localCopy.templateChoiceManual),
            ],
            onChanged: (String? value) {
              ref
                  .read(_projectSettingsProvider.notifier)
                  .setTemplateChoice(value);
            },
          ),
          AppChoiceField<bool?>(
            label:
                '${localCopy.projectRefineColumns} · ${localCopy.projectAppDefault(_onOff(app.refineColumns, localizedCopy: Copy.of(context)))}',
            value: view.draft.refineColumns,
            options: <Choice<bool?>>[
              Choice<bool?>(null, localCopy.projectUseAppDefault),
              Choice<bool?>(true, localCopy.projectOn),
              Choice<bool?>(false, localCopy.projectOff),
            ],
            onChanged: (bool? value) {
              ref
                  .read(_projectSettingsProvider.notifier)
                  .setRefineColumns(value);
            },
          ),
        ],
        submitLabel: localCopy.save,
        onSubmit: () async {
          final LocalizedCopy localCopy = Copy.of(context);

          final bool saved = await ref
              .read(_projectSettingsProvider.notifier)
              .submit(high: _high!.text, medium: _medium!.text);
          if (saved && context.mounted) {
            showAppSnack(
              context,
              localCopy.projectSettingsSaved,
              tone: SnackTone.success,
            );
          }
          return saved;
        },
      ),
    );
  }

  void _bind(Project project) {
    if (_boundId == project.id && _high != null) {
      return;
    }
    _high?.dispose();
    _medium?.dispose();
    _high = TextEditingController(
      text: _bandOrEmpty(project.settings.confidenceHigh),
    );
    _medium = TextEditingController(
      text: _bandOrEmpty(project.settings.confidenceMedium),
    );
    _boundId = project.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(_projectSettingsProvider.notifier).hydrate(project);
    });
  }
}

final NotifierProvider<_ProjectSettings, _ProjectSettingsView>
_projectSettingsProvider =
    NotifierProvider<_ProjectSettings, _ProjectSettingsView>(
      _ProjectSettings.new,
      retry: (int _, Object _) => null,
    );

typedef _ProjectSettingsView = ({
  String? saveError,
  LocalizedMessage? localizedSaveError,
  String? highError,
  LocalizedMessage? localizedHighError,
  String? mediumError,
  LocalizedMessage? localizedMediumError,
  bool dirty,
  ProjectSettings draft,
});

class _ProjectSettings extends Notifier<_ProjectSettingsView> {
  Project? _source;

  @override
  _ProjectSettingsView build() {
    return (
      saveError: null,
      localizedSaveError: null,
      highError: null,
      localizedHighError: null,
      mediumError: null,
      localizedMediumError: null,
      dirty: false,
      draft: ProjectSettings.defaults,
    );
  }

  /// Loads the stored overrides without marking the form dirty.
  void hydrate(Project project) {
    _source = project;
    state = (
      saveError: null,
      localizedSaveError: null,
      highError: null,
      localizedHighError: null,
      mediumError: null,
      localizedMediumError: null,
      dirty: false,
      draft: project.settings,
    );
  }

  /// Sets or clears the AI override.
  void setAiEnabled(bool? value) {
    _replace(
      state.draft.copyWith(aiEnabled: value, clearAiEnabled: value == null),
    );
  }

  /// Sets or clears the image-egress override.
  void setDoNotSendImages(bool? value) {
    _replace(
      state.draft.copyWith(
        doNotSendImages: value,
        clearDoNotSendImages: value == null,
      ),
    );
  }

  /// Sets or clears the GPS override.
  void setGpsEnabled(bool? value) {
    _replace(
      state.draft.copyWith(gpsEnabled: value, clearGpsEnabled: value == null),
    );
  }

  /// Sets or clears the folder-strategy override.
  void setFolderStrategy(String? value) {
    _replace(
      state.draft.copyWith(
        folderStrategy: value,
        clearFolderStrategy: value == null,
      ),
    );
  }

  /// Sets or clears how capture chooses a template.
  void setTemplateChoice(String? value) {
    _replace(
      state.draft.copyWith(
        templateChoice: value,
        clearTemplateChoice: value == null,
      ),
    );
  }

  /// Sets or clears the refined-columns override.
  void setRefineColumns(bool? value) {
    _replace(
      state.draft.copyWith(
        refineColumns: value,
        clearRefineColumns: value == null,
      ),
    );
  }

  /// Validates the thresholds and writes settings onto the project row.
  Future<bool> submit({required String high, required String medium}) async {
    final Project? source = _source;
    if (source == null) {
      return false;
    }
    final ({double? value, String? error}) parsedHigh = _parseBand(high);
    final ({double? value, String? error}) parsedMedium = _parseBand(medium);
    if (parsedHigh.error != null || parsedMedium.error != null) {
      state = (
        saveError: null,
        localizedSaveError: null,
        highError: parsedHigh.error,
        localizedHighError: parsedHigh.error == null
            ? null
            : Copy.messages.outOfRange,
        mediumError: parsedMedium.error,
        localizedMediumError: parsedMedium.error == null
            ? null
            : Copy.messages.outOfRange,
        dirty: state.dirty,
        draft: state.draft,
      );
      return false;
    }
    final ProjectSettings draft = state.draft.copyWith(
      confidenceHigh: parsedHigh.value,
      clearConfidenceHigh: parsedHigh.value == null,
      confidenceMedium: parsedMedium.value,
      clearConfidenceMedium: parsedMedium.value == null,
    );
    final Result<void> result = await ref
        .read(projectRepositoryProvider)
        .update(
          Project(
            id: source.id,
            name: source.name,
            status: source.status,
            folderName: source.folderName,
            settings: draft,
            createdAt: source.createdAt,
            updatedAt: source.updatedAt,
            description: source.description,
            organisation: source.organisation,
            startsOn: source.startsOn,
            endsOn: source.endsOn,
          ),
        );
    switch (result) {
      case Success<void>():
        _source = source.copyWith(settings: draft);
        state = (
          saveError: null,
          localizedSaveError: null,
          highError: null,
          localizedHighError: null,
          mediumError: null,
          localizedMediumError: null,
          dirty: false,
          draft: draft,
        );
        return true;
      case FailureResult<void>(:final Failure failure):
        state = (
          saveError: failure.message,
          localizedSaveError: failure.explanation,
          highError: null,
          localizedHighError: null,
          mediumError: null,
          localizedMediumError: null,
          dirty: state.dirty,
          draft: draft,
        );
        return false;
    }
  }

  void _replace(ProjectSettings draft) {
    state = (
      saveError: state.saveError,
      localizedSaveError: state.localizedSaveError,
      highError: state.highError,
      localizedHighError: state.localizedHighError,
      mediumError: state.mediumError,
      localizedMediumError: state.localizedMediumError,
      dirty: true,
      draft: draft,
    );
  }
}

({double? value, String? error}) _parseBand(
  String raw, {
  LocalizedCopy? localizedCopy,
}) {
  final String trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return (value: null, error: null);
  }
  final double? parsed = double.tryParse(trimmed);
  if (parsed == null || parsed < 0 || parsed > 1) {
    return (value: null, error: (localizedCopy ?? Copy.english).outOfRange);
  }
  return (value: parsed, error: null);
}

String _onOff(bool value, {LocalizedCopy? localizedCopy}) => value
    ? (localizedCopy ?? Copy.english).projectOn
    : (localizedCopy ?? Copy.english).projectOff;

String _strategyLabel(String strategy, {LocalizedCopy? localizedCopy}) {
  return switch (strategy) {
    'byTemplate' => (localizedCopy ?? Copy.english).settingsFolderByTemplate,
    'byCaptureDate' => (localizedCopy ?? Copy.english).settingsFolderByDate,
    'flat' => (localizedCopy ?? Copy.english).settingsFolderFlat,
    _ => (localizedCopy ?? Copy.english).settingsFolderByContext,
  };
}

String _band(double value) => value.toString();

String _bandOrEmpty(double? value) => value == null ? '' : _band(value);
