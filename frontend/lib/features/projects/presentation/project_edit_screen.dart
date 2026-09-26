import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/app_date_field.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/project_repository.dart';
import '../projects.dart' show projectRepositoryProvider;
import 'current_project.dart';
import 'project_photo_field.dart';

/// Details form: name, description, organisation, dates, status and the
/// optional project photo.
class ProjectEditScreen extends ConsumerStatefulWidget {
  /// Creates the details form. The open project comes from
  /// [currentProjectDetailsProvider]; this widget holds no id.
  const ProjectEditScreen({super.key});

  @override
  ConsumerState<ProjectEditScreen> createState() => _ProjectEditScreenState();
}

class _ProjectEditScreenState extends ConsumerState<ProjectEditScreen> {
  TextEditingController? _name;
  TextEditingController? _description;
  TextEditingController? _organisation;
  String? _boundId;
  bool _photoBusy = false;

  @override
  void dispose() {
    _name?.dispose();
    _description?.dispose();
    _organisation?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Project? project = ref.watch(currentProjectDetailsProvider);
    if (project == null) {
      return AppPage(
        key: const ValueKey<String>('route-project-edit'),
        title: Copy.projectEditTitle,
        body: AppEmptyState(
          icon: AppIcons.project,
          headline: Copy.projectEditEmptyHeadline,
          message: Copy.projectEditEmptyMessage,
          actionLabel: Copy.navProjects,
          onAction: () => context.go(_projectsRoot),
        ),
      );
    }
    _bind(project);
    final _ProjectEditView view = ref.watch(_projectEditProvider);
    return AppPage(
      key: const ValueKey<String>('route-project-edit'),
      title: Copy.projectEditTitle,
      scrollable: false,
      overflow: <AppOverflowAction>[
        AppOverflowAction(
          label: Copy.projectSettingsTitle,
          icon: AppIcons.settings,
          onTap: () => context.go(_settings(project.id)),
        ),
      ],
      body: AppForm(
        guardUnsaved: true,
        dirty: view.dirty,
        errors: view.saveError == null
            ? const <String>[]
            : <String>[view.saveError!],
        fields: <Widget>[
          AppTextField(
            label: Copy.projectName,
            controller: _name!,
            requiredness: FieldRequiredness.required,
            textInputAction: TextInputAction.next,
            errorText: view.nameError,
          ),
          AppTextField(
            label: Copy.projectDescription,
            controller: _description!,
            requiredness: FieldRequiredness.optional,
            textInputAction: TextInputAction.next,
            maxLines: 3,
          ),
          AppTextField(
            label: Copy.projectOrganisation,
            controller: _organisation!,
            requiredness: FieldRequiredness.optional,
            textInputAction: TextInputAction.next,
          ),
          AppDateField(
            label: Copy.projectStartsOn,
            value: view.startsOn,
            clock: const SystemClock(),
            onChanged: ref.read(_projectEditProvider.notifier).setStartsOn,
          ),
          AppDateField(
            label: Copy.projectEndsOn,
            value: view.endsOn,
            clock: const SystemClock(),
            onChanged: ref.read(_projectEditProvider.notifier).setEndsOn,
          ),
          AppChoiceField<ProjectStatus>(
            label: Copy.projectStatus,
            value: view.status,
            options: const <Choice<ProjectStatus>>[
              Choice<ProjectStatus>(
                ProjectStatus.active,
                Copy.projectStatusActive,
              ),
              Choice<ProjectStatus>(
                ProjectStatus.archived,
                Copy.projectStatusArchived,
              ),
            ],
            onChanged: (ProjectStatus? status) {
              if (status != null) {
                ref.read(_projectEditProvider.notifier).setStatus(status);
              }
            },
          ),
          ProjectPhotoField(
            stored: project.settings.coverPhoto,
            busy: _photoBusy,
            onPicked: (Uint8List bytes) {
              _photo((_ProjectEdit edit) => edit.setPhoto(project.id, bytes));
            },
            onRemove: () {
              _photo((_ProjectEdit edit) => edit.clearPhoto(project.id));
            },
          ),
        ],
        submitLabel: Copy.save,
        onSubmit: () async {
          await ref
              .read(_projectEditProvider.notifier)
              .submit(
                name: _name!.text,
                description: _description!.text,
                organisation: _organisation!.text,
              );
        },
      ),
    );
  }

  /// Stores a photo change straight away, as a photo is a file, and says
  /// when it could not be stored.
  Future<void> _photo(
    Future<Result<ProjectSettings>> Function(_ProjectEdit edit) change,
  ) async {
    setState(() => _photoBusy = true);
    final Result<ProjectSettings> result = await change(
      ref.read(_projectEditProvider.notifier),
    );
    if (!mounted) {
      return;
    }
    setState(() => _photoBusy = false);
    if (result case FailureResult<ProjectSettings>(:final failure)) {
      showAppSnack(context, failure.message, tone: SnackTone.error);
    }
  }

  void _bind(Project project) {
    if (_boundId == project.id && _name != null) {
      return;
    }
    _name?.dispose();
    _description?.dispose();
    _organisation?.dispose();
    _name = TextEditingController(text: project.name);
    _description = TextEditingController(text: project.description ?? '');
    _organisation = TextEditingController(text: project.organisation ?? '');
    _boundId = project.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(_projectEditProvider.notifier).hydrate(project);
    });
  }
}

final NotifierProvider<_ProjectEdit, _ProjectEditView> _projectEditProvider =
    NotifierProvider<_ProjectEdit, _ProjectEditView>(
      _ProjectEdit.new,
      retry: (int _, Object _) => null,
    );

typedef _ProjectEditView = ({
  String? nameError,
  String? saveError,
  bool dirty,
  DateTime? startsOn,
  DateTime? endsOn,
  ProjectStatus status,
});

class _ProjectEdit extends Notifier<_ProjectEditView> {
  Project? _source;

  @override
  _ProjectEditView build() {
    return (
      nameError: null,
      saveError: null,
      dirty: false,
      startsOn: null,
      endsOn: null,
      status: ProjectStatus.active,
    );
  }

  /// Loads dates and status from [project] without marking the form dirty.
  void hydrate(Project project) {
    _source = project;
    state = (
      nameError: null,
      saveError: null,
      dirty: false,
      startsOn: project.startsOn,
      endsOn: project.endsOn,
      status: project.status,
    );
  }

  /// Stores [bytes] as the project's photo. Save keeps it, because the
  /// settings it writes are the stored ones.
  Future<Result<ProjectSettings>> setPhoto(
    String projectId,
    Uint8List bytes,
  ) async {
    final Result<ProjectSettings> stored = await ref
        .read(projectRepositoryProvider)
        .setCoverPhoto(projectId, bytes);
    _keep(stored);
    return stored;
  }

  /// Takes the photo off the project; its file stays.
  Future<Result<ProjectSettings>> clearPhoto(String projectId) async {
    final Result<ProjectSettings> stored = await ref
        .read(projectRepositoryProvider)
        .clearCoverPhoto(projectId);
    _keep(stored);
    return stored;
  }

  void _keep(Result<ProjectSettings> stored) {
    final Project? source = _source;
    if (source != null && stored is Success<ProjectSettings>) {
      _source = source.copyWith(settings: stored.value);
    }
  }

  /// Sets the start date and marks the form dirty.
  void setStartsOn(DateTime? value) {
    state = (
      nameError: state.nameError,
      saveError: state.saveError,
      dirty: true,
      startsOn: value,
      endsOn: state.endsOn,
      status: state.status,
    );
  }

  /// Sets the end date and marks the form dirty.
  void setEndsOn(DateTime? value) {
    state = (
      nameError: state.nameError,
      saveError: state.saveError,
      dirty: true,
      startsOn: state.startsOn,
      endsOn: value,
      status: state.status,
    );
  }

  /// Writes the same status field the archive action writes.
  void setStatus(ProjectStatus status) {
    state = (
      nameError: state.nameError,
      saveError: state.saveError,
      dirty: true,
      startsOn: state.startsOn,
      endsOn: state.endsOn,
      status: status,
    );
  }

  /// Validates and writes the row. [folderName] is taken from the stored
  /// project, never recomputed from [name].
  Future<bool> submit({
    required String name,
    String? description,
    String? organisation,
  }) async {
    final Project? source = _source;
    if (source == null) {
      return false;
    }
    final String trimmed = name.trim();
    if (trimmed.isEmpty) {
      state = (
        nameError: Copy.nameRequired,
        saveError: null,
        dirty: state.dirty,
        startsOn: state.startsOn,
        endsOn: state.endsOn,
        status: state.status,
      );
      return false;
    }
    final Result<void> result = await ref
        .read(projectRepositoryProvider)
        .update(
          Project(
            id: source.id,
            name: trimmed,
            status: state.status,
            folderName: source.folderName,
            settings: source.settings,
            createdAt: source.createdAt,
            updatedAt: source.updatedAt,
            description: _optionalText(description),
            organisation: _optionalText(organisation),
            startsOn: state.startsOn,
            endsOn: state.endsOn,
          ),
        );
    switch (result) {
      case Success<void>():
        state = (
          nameError: null,
          saveError: null,
          dirty: false,
          startsOn: state.startsOn,
          endsOn: state.endsOn,
          status: state.status,
        );
        return true;
      case FailureResult<void>(:final Failure failure):
        state = (
          nameError: null,
          saveError: failure.message,
          dirty: state.dirty,
          startsOn: state.startsOn,
          endsOn: state.endsOn,
          status: state.status,
        );
        return false;
    }
  }
}

String? _optionalText(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return null;
  }
  return raw.trim();
}

/// Must match [AppRoutes.projectSettings].
String _settings(String id) {
  return '$_projectsRoot/${Uri.encodeComponent(id)}/$_settingsSegment';
}

const String _projectsRoot = '/projects';
const String _settingsSegment = 'settings';
