import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
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
import 'package:tapture/core/widgets/state_refresh.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';

import '../domain/project_name_validation.dart';
import '../domain/project_repository.dart';
import '../projects.dart' show projectRepositoryProvider;
import 'current_project.dart';
import 'project_photo_field.dart';

/// Details form: name, description, organisation, dates, status and the
/// optional project photo.
class ProjectEditScreen extends ConsumerStatefulWidget {
  /// Creates the details form for the project the route names. It reads
  /// [projectByIdProvider], so an archived project stays editable.
  const ProjectEditScreen({required this.projectId, super.key});

  /// Project the form edits.
  final String projectId;

  @override
  ConsumerState<ProjectEditScreen> createState() => _ProjectEditScreenState();
}

class _ProjectEditScreenState extends ConsumerState<ProjectEditScreen>
    with StateRefresh {
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
    final LocalizedCopy localCopy = Copy.of(context);

    final AsyncValue<Project?> value = ref.watch(
      projectByIdProvider(widget.projectId),
    );
    final Project? project = value.value;
    if (project == null) {
      return AppPage(
        key: const ValueKey<String>('route-project-edit'),
        title: localCopy.projectEditFormTitle,
        body: value.isLoading
            ? const AppSkeleton()
            : AppEmptyState(
                icon: AppIcons.project,
                headline: localCopy.projectEditEmptyHeadline,
                message: localCopy.projectEditEmptyMessage,
                actionLabel: localCopy.navProjects,
                onAction: () => context.go(RoutePaths.projects),
              ),
      );
    }
    _bind(project);
    final _ProjectEditView view = ref.watch(_projectEditProvider);
    return AppPage(
      key: const ValueKey<String>('route-project-edit'),
      title: localCopy.projectEditFormTitle,
      scrollable: false,
      overflow: <AppOverflowAction>[
        AppOverflowAction(
          label: localCopy.projectSettingsTitle,
          icon: AppIcons.settings,
          onTap: () => context.go(RoutePaths.projectSettings(project.id)),
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
          AppTextField(
            label: localCopy.projectName,
            wrapLabel: true,
            controller: _name!,
            requiredness: FieldRequiredness.required,
            textInputAction: TextInputAction.next,
            errorText: Copy.of(
              context,
            ).stateText(view.localizedNameError, view.nameError),
            onChanged: ref.read(_projectEditProvider.notifier).changeName,
          ),
          AppTextField(
            label: localCopy.projectDescription,
            wrapLabel: true,
            controller: _description!,
            requiredness: FieldRequiredness.optional,
            textInputAction: TextInputAction.next,
            maxLines: 3,
          ),
          AppTextField(
            label: localCopy.projectOrganisation,
            wrapLabel: true,
            controller: _organisation!,
            requiredness: FieldRequiredness.optional,
            textInputAction: TextInputAction.next,
          ),
          AppDateField(
            label: localCopy.projectStartsOn,
            value: view.startsOn,
            clock: const SystemClock(),
            onChanged: ref.read(_projectEditProvider.notifier).setStartsOn,
          ),
          AppDateField(
            label: localCopy.projectEndsOn,
            value: view.endsOn,
            clock: const SystemClock(),
            onChanged: ref.read(_projectEditProvider.notifier).setEndsOn,
          ),
          AppChoiceField<ProjectStatus>(
            label: localCopy.projectStatus,
            value: view.status,
            options: <Choice<ProjectStatus>>[
              Choice<ProjectStatus>(
                ProjectStatus.active,
                localCopy.projectStatusActive,
              ),
              Choice<ProjectStatus>(
                ProjectStatus.archived,
                localCopy.projectStatusArchived,
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
        submitLabel: localCopy.save,
        onSubmit: () async {
          final LocalizedCopy localCopy = Copy.of(context);

          final bool saved = await ref
              .read(_projectEditProvider.notifier)
              .submit(
                name: _name!.text,
                description: _description!.text,
                organisation: _organisation!.text,
              );
          if (saved && context.mounted) {
            showAppSnack(
              context,
              localCopy.projectSaved,
              tone: SnackTone.success,
            );
            // After the form has forgotten its edits, so leaving asks
            // nothing: back to the details page (D8).
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) {
                return;
              }
              final NavigatorState navigator = Navigator.of(context);
              if (navigator.canPop()) {
                navigator.pop();
              } else {
                GoRouter.maybeOf(
                  context,
                )?.go(RoutePaths.projectDetails(project.id));
              }
            });
          }
          return saved;
        },
      ),
    );
  }

  /// Stores a photo change straight away, as a photo is a file, and says
  /// when it could not be stored.
  Future<void> _photo(
    Future<Result<ProjectSettings>> Function(_ProjectEdit edit) change,
  ) async {
    refresh(() => _photoBusy = true);
    final Result<ProjectSettings> result = await change(
      ref.read(_projectEditProvider.notifier),
    );
    if (!mounted) {
      return;
    }
    refresh(() => _photoBusy = false);
    if (result case FailureResult<ProjectSettings>(:final failure)) {
      showAppSnack(
        context,
        failure.message,
        tone: SnackTone.error,
        localizedMessage: failure.explanation,
      );
    }
  }

  void _bind(Project project) {
    if (_boundId == project.id && _name != null) {
      // The stored row moved on (this form saved, or another screen wrote
      // it): the next save starts from it, while typed text stays.
      ref.read(_projectEditProvider.notifier).follow(project);
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
    NotifierProvider.autoDispose<_ProjectEdit, _ProjectEditView>(
      _ProjectEdit.new,
      retry: (int _, Object _) => null,
    );

typedef _ProjectEditView = ({
  String? nameError,
  LocalizedMessage? localizedNameError,
  String? saveError,
  LocalizedMessage? localizedSaveError,
  bool dirty,
  DateTime? startsOn,
  DateTime? endsOn,
  ProjectStatus status,
});

class _ProjectEdit extends Notifier<_ProjectEditView> {
  Project? _source;
  bool _nameTouched = false;

  @override
  _ProjectEditView build() {
    _nameTouched = false;
    return (
      nameError: null,
      localizedNameError: null,
      saveError: null,
      localizedSaveError: null,
      dirty: false,
      startsOn: null,
      endsOn: null,
      status: ProjectStatus.active,
    );
  }

  /// Loads dates and status from [project] without marking the form dirty.
  void hydrate(Project project) {
    _source = project;
    _nameTouched = false;
    state = (
      nameError: null,
      localizedNameError: null,
      saveError: null,
      localizedSaveError: null,
      dirty: false,
      startsOn: project.startsOn,
      endsOn: project.endsOn,
      status: project.status,
    );
  }

  /// Takes [project] as the row the next save starts from, without
  /// touching the form's values.
  void follow(Project project) {
    _source = project;
  }

  /// Validate only an edited or submitted name, preserving storage failures.
  void changeName(String name) {
    _nameTouched = true;
    _validateName(name);
  }

  bool _validateName(String name, {bool submitted = false}) {
    final bool valid = ProjectNameValidation.isValid(name);
    final bool showError = (_nameTouched || submitted) && !valid;
    state = (
      nameError: showError ? Copy.nameRequired : null,
      localizedNameError: showError ? Copy.messages.nameRequired : null,
      saveError: state.saveError,
      localizedSaveError: state.localizedSaveError,
      dirty: state.dirty,
      startsOn: state.startsOn,
      endsOn: state.endsOn,
      status: state.status,
    );
    return valid;
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
      localizedNameError: state.localizedNameError,
      saveError: state.saveError,
      localizedSaveError: state.localizedSaveError,
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
      localizedNameError: state.localizedNameError,
      saveError: state.saveError,
      localizedSaveError: state.localizedSaveError,
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
      localizedNameError: state.localizedNameError,
      saveError: state.saveError,
      localizedSaveError: state.localizedSaveError,
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
    if (!_validateName(name, submitted: true)) {
      return false;
    }
    final Result<void> result = await ref
        .read(projectRepositoryProvider)
        .update(
          Project(
            id: source.id,
            name: name.trim(),
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
    if (!ref.mounted) {
      return result is Success<void>;
    }
    switch (result) {
      case Success<void>():
        state = (
          nameError: null,
          localizedNameError: null,
          saveError: null,
          localizedSaveError: null,
          dirty: false,
          startsOn: state.startsOn,
          endsOn: state.endsOn,
          status: state.status,
        );
        return true;
      case FailureResult<void>(:final Failure failure):
        state = (
          nameError: state.nameError,
          localizedNameError: state.localizedNameError,
          saveError: failure.message,
          localizedSaveError: failure.explanation,
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
