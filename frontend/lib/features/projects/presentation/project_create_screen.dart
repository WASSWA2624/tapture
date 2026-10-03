import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';
import 'package:tapture/core/widgets/state_refresh.dart';

import '../domain/project_repository.dart';
import '../projects.dart' show projectRepositoryProvider;
import 'current_project.dart';
import 'project_photo_field.dart';

/// Short form that creates a project, or duplicates one, then opens it.
class ProjectCreateScreen extends ConsumerStatefulWidget {
  /// Creates the form. [sourceId] copies structure from that project;
  /// [initialName] is the editable suggested name.
  const ProjectCreateScreen({super.key, this.sourceId, this.initialName});

  /// Existing project to copy structure from, or null for a blank project.
  final String? sourceId;

  /// Prefills the name field. Duplicate supplies a suggested copy name.
  final String? initialName;

  @override
  ConsumerState<ProjectCreateScreen> createState() =>
      _ProjectCreateScreenState();
}

class _ProjectCreateScreenState extends ConsumerState<ProjectCreateScreen>
    with StateRefresh {
  late final TextEditingController _name;
  final TextEditingController _description = TextEditingController();
  final TextEditingController _organisation = TextEditingController();

  /// The optional photo, stored once the project exists.
  Uint8List? _photo;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _organisation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final _ProjectCreateView view = ref.watch(_projectCreateProvider);
    final bool duplicating =
        widget.sourceId != null && widget.sourceId!.isNotEmpty;
    return AppPage(
      key: const ValueKey<String>('route-project-create'),
      title: duplicating
          ? localCopy.projectDuplicateTitle
          : localCopy.projectCreateTitle,
      scrollable: false,
      body: AppForm(
        guardUnsaved: true,
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
            controller: _name,
            requiredness: FieldRequiredness.required,
            textInputAction: TextInputAction.next,
            errorText: Copy.of(
              context,
            ).stateText(view.localizedNameError, view.nameError),
          ),
          AppTextField(
            label: localCopy.projectDescription,
            controller: _description,
            requiredness: FieldRequiredness.optional,
            textInputAction: TextInputAction.next,
            maxLines: 3,
          ),
          AppTextField(
            label: localCopy.projectOrganisation,
            controller: _organisation,
            requiredness: FieldRequiredness.optional,
            textInputAction: TextInputAction.done,
          ),
          ProjectPhotoField(
            pending: _photo,
            onPicked: (Uint8List bytes) => refresh(() => _photo = bytes),
            onRemove: () => refresh(() => _photo = null),
          ),
        ],
        submitLabel: duplicating
            ? localCopy.projectsDuplicate
            : localCopy.projectsCreate,
        onSubmit: () async {
          final Project? created = await ref
              .read(_projectCreateProvider.notifier)
              .submit(
                name: _name.text,
                description: _description.text,
                organisation: _organisation.text,
                sourceId: widget.sourceId,
              );
          if (created == null) {
            return false;
          }
          if (!context.mounted) {
            return true;
          }
          final Uint8List? photo = _photo;
          if (photo != null) {
            final Result<ProjectSettings> stored = await ref
                .read(projectRepositoryProvider)
                .setCoverPhoto(created.id, photo);
            if (!context.mounted) {
              return true;
            }
            // The project stands without its photo; say why it is missing.
            if (stored case FailureResult<ProjectSettings>(:final failure)) {
              showAppSnack(
                context,
                failure.message,
                tone: SnackTone.error,
                localizedMessage: failure.explanation,
              );
            }
          }
          final GoRouter? router = GoRouter.maybeOf(context);
          if (router != null) {
            router.go(RoutePaths.project(created.id));
          }
          return true;
        },
      ),
    );
  }
}

final NotifierProvider<_ProjectCreate, _ProjectCreateView>
_projectCreateProvider = NotifierProvider<_ProjectCreate, _ProjectCreateView>(
  _ProjectCreate.new,
  retry: (int _, Object _) => null,
);

typedef _ProjectCreateView = ({
  String? nameError,
  LocalizedMessage? localizedNameError,
  String? saveError,
  LocalizedMessage? localizedSaveError,
});

class _ProjectCreate extends Notifier<_ProjectCreateView> {
  @override
  _ProjectCreateView build() {
    return (
      nameError: null,
      localizedNameError: null,
      saveError: null,
      localizedSaveError: null,
    );
  }

  /// Validates, writes through [createReady], and opens the new project.
  Future<Project?> submit({
    required String name,
    String? description,
    String? organisation,
    String? sourceId,
  }) async {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) {
      state = (
        nameError: Copy.nameRequired,
        localizedNameError: Copy.messages.nameRequired,
        saveError: null,
        localizedSaveError: null,
      );
      return null;
    }
    final Result<Project> result = await ref
        .read(projectRepositoryProvider)
        .createReady(
          name: trimmed,
          description: description,
          organisation: organisation,
          sourceId: sourceId,
        );
    switch (result) {
      case Success<Project>(:final Project value):
        ref.read(currentProjectProvider.notifier).open(value.id);
        state = (
          nameError: null,
          localizedNameError: null,
          saveError: null,
          localizedSaveError: null,
        );
        return value;
      case FailureResult<Project>(:final Failure failure):
        state = (
          nameError: null,
          localizedNameError: null,
          saveError: failure.message,
          localizedSaveError: failure.explanation,
        );
        return null;
    }
  }
}
