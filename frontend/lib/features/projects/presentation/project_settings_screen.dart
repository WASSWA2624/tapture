import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/settings/settings.dart';

import '../domain/project_repository.dart';
import '../projects.dart' show projectRepositoryProvider;
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
    final Project? project = ref.watch(currentProjectDetailsProvider);
    if (project == null) {
      return AppPage(
        key: const ValueKey<String>('route-project-settings'),
        title: Copy.projectSettingsTitle,
        body: AppEmptyState(
          icon: AppIcons.settings,
          headline: Copy.projectSettingsEmptyHeadline,
          message: Copy.projectSettingsEmptyMessage,
          actionLabel: Copy.navProjects,
          onAction: () => context.go(_projectsRoot),
        ),
      );
    }
    _bind(project);
    final SettingsStore store = ref.watch(projectSettingsStoreProvider);
    final ProjectSettingsDefaults app = _appDefaults(store);
    final _ProjectSettingsView view = ref.watch(_projectSettingsProvider);
    return AppPage(
      key: const ValueKey<String>('route-project-settings'),
      title: Copy.projectSettingsTitle,
      scrollable: false,
      overflow: <AppOverflowAction>[
        AppOverflowAction(
          label: Copy.projectEditTitle,
          icon: AppIcons.edit,
          onTap: () => context.go(_edit(project.id)),
        ),
      ],
      body: AppForm(
        guardUnsaved: true,
        dirty: view.dirty,
        errors: view.saveError == null
            ? const <String>[]
            : <String>[view.saveError!],
        fields: <Widget>[
          AppChoiceField<bool?>(
            label:
                '${Copy.projectAiEnabled} · ${Copy.projectAppDefault(_onOff(app.aiEnabled))}',
            value: view.draft.aiEnabled,
            options: const <Choice<bool?>>[
              Choice<bool?>(null, Copy.projectUseAppDefault),
              Choice<bool?>(true, Copy.projectOn),
              Choice<bool?>(false, Copy.projectOff),
            ],
            onChanged: (bool? value) {
              ref.read(_projectSettingsProvider.notifier).setAiEnabled(value);
            },
          ),
          AppChoiceField<bool?>(
            label:
                '${Copy.projectDoNotSendImages} · ${Copy.projectAppDefault(_onOff(app.doNotSendImages))}',
            value: view.draft.doNotSendImages,
            options: const <Choice<bool?>>[
              Choice<bool?>(null, Copy.projectUseAppDefault),
              Choice<bool?>(true, Copy.projectOn),
              Choice<bool?>(false, Copy.projectOff),
            ],
            onChanged: (bool? value) {
              ref
                  .read(_projectSettingsProvider.notifier)
                  .setDoNotSendImages(value);
            },
          ),
          AppChoiceField<bool?>(
            label:
                '${Copy.settingsGps} · ${Copy.projectAppDefault(_onOff(app.gpsEnabled))}',
            value: view.draft.gpsEnabled,
            options: const <Choice<bool?>>[
              Choice<bool?>(null, Copy.projectUseAppDefault),
              Choice<bool?>(true, Copy.projectOn),
              Choice<bool?>(false, Copy.projectOff),
            ],
            onChanged: (bool? value) {
              ref.read(_projectSettingsProvider.notifier).setGpsEnabled(value);
            },
          ),
          AppChoiceField<String?>(
            label: Copy.settingsFolderStrategy,
            value: view.draft.folderStrategy,
            options: <Choice<String?>>[
              Choice<String?>(
                null,
                Copy.projectAppDefault(_strategyLabel(app.folderStrategy)),
              ),
              const Choice<String?>('byContext', Copy.settingsFolderByContext),
              const Choice<String?>(
                'byTemplate',
                Copy.settingsFolderByTemplate,
              ),
              const Choice<String?>('byCaptureDate', Copy.settingsFolderByDate),
              const Choice<String?>('flat', Copy.settingsFolderFlat),
            ],
            onChanged: ref
                .read(_projectSettingsProvider.notifier)
                .setFolderStrategy,
          ),
          AppTextField(
            label: Copy.projectConfidenceHigh,
            controller: _high!,
            helper: Copy.projectAppDefault(_band(app.confidenceHigh)),
            requiredness: FieldRequiredness.optional,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            errorText: view.highError,
            dictation: false,
          ),
          AppTextField(
            label: Copy.projectConfidenceMedium,
            controller: _medium!,
            helper: Copy.projectAppDefault(_band(app.confidenceMedium)),
            requiredness: FieldRequiredness.optional,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            errorText: view.mediumError,
            dictation: false,
          ),
          AppChoiceField<String?>(
            label: Copy.templateChoiceLabel,
            value: view.draft.templateChoice,
            options: const <Choice<String?>>[
              Choice<String?>(null, Copy.templateChoiceAuto),
              Choice<String?>('suggest', Copy.templateChoiceSuggest),
              Choice<String?>('manual', Copy.templateChoiceManual),
            ],
            onChanged: (String? value) {
              ref
                  .read(_projectSettingsProvider.notifier)
                  .setTemplateChoice(value);
            },
          ),
          AppChoiceField<bool?>(
            label:
                '${Copy.projectRefineColumns} · ${Copy.projectAppDefault(_onOff(app.refineColumns))}',
            value: view.draft.refineColumns,
            options: const <Choice<bool?>>[
              Choice<bool?>(null, Copy.projectUseAppDefault),
              Choice<bool?>(true, Copy.projectOn),
              Choice<bool?>(false, Copy.projectOff),
            ],
            onChanged: (bool? value) {
              ref
                  .read(_projectSettingsProvider.notifier)
                  .setRefineColumns(value);
            },
          ),
        ],
        submitLabel: Copy.save,
        onSubmit: () async {
          await ref
              .read(_projectSettingsProvider.notifier)
              .submit(high: _high!.text, medium: _medium!.text);
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
  String? highError,
  String? mediumError,
  bool dirty,
  ProjectSettings draft,
});

class _ProjectSettings extends Notifier<_ProjectSettingsView> {
  Project? _source;

  @override
  _ProjectSettingsView build() {
    return (
      saveError: null,
      highError: null,
      mediumError: null,
      dirty: false,
      draft: ProjectSettings.defaults,
    );
  }

  /// Loads the stored overrides without marking the form dirty.
  void hydrate(Project project) {
    _source = project;
    state = (
      saveError: null,
      highError: null,
      mediumError: null,
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
        highError: parsedHigh.error,
        mediumError: parsedMedium.error,
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
          highError: null,
          mediumError: null,
          dirty: false,
          draft: draft,
        );
        return true;
      case FailureResult<void>(:final Failure failure):
        state = (
          saveError: failure.message,
          highError: null,
          mediumError: null,
          dirty: state.dirty,
          draft: draft,
        );
        return false;
    }
  }

  void _replace(ProjectSettings draft) {
    state = (
      saveError: state.saveError,
      highError: state.highError,
      mediumError: state.mediumError,
      dirty: true,
      draft: draft,
    );
  }
}

ProjectSettingsDefaults _appDefaults(SettingsStore store) {
  return (
    aiEnabled: builtInProjectSettingsDefaults.aiEnabled,
    doNotSendImages: store.read(SettingKeys.aiDoNotSendImages),
    gpsEnabled: store.read(SettingKeys.gpsEnabled),
    folderStrategy: store.read(SettingKeys.folderStrategy),
    confidenceHigh: store.read(SettingKeys.confidenceHigh),
    confidenceMedium: store.read(SettingKeys.confidenceMedium),
    refineColumns: builtInProjectSettingsDefaults.refineColumns,
  );
}

({double? value, String? error}) _parseBand(String raw) {
  final String trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return (value: null, error: null);
  }
  final double? parsed = double.tryParse(trimmed);
  if (parsed == null || parsed < 0 || parsed > 1) {
    return (value: null, error: Copy.outOfRange);
  }
  return (value: parsed, error: null);
}

String _onOff(bool value) => value ? Copy.projectOn : Copy.projectOff;

String _strategyLabel(String strategy) {
  return switch (strategy) {
    'byTemplate' => Copy.settingsFolderByTemplate,
    'byCaptureDate' => Copy.settingsFolderByDate,
    'flat' => Copy.settingsFolderFlat,
    _ => Copy.settingsFolderByContext,
  };
}

String _band(double value) => value.toString();

String _bandOrEmpty(double? value) => value == null ? '' : _band(value);

/// Must match [AppRoutes.projectEdit].
String _edit(String id) {
  return '$_projectsRoot/${Uri.encodeComponent(id)}/$_editSegment';
}

const String _projectsRoot = '/projects';
const String _editSegment = 'edit';
