import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';

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

class _ProjectCreateScreenState extends ConsumerState<ProjectCreateScreen> {
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
    final _ProjectCreateView view = ref.watch(_projectCreateProvider);
    final bool duplicating =
        widget.sourceId != null && widget.sourceId!.isNotEmpty;
    return AppPage(
      key: const ValueKey<String>('route-project-create'),
      title: duplicating ? Copy.projectDuplicateTitle : Copy.projectCreateTitle,
      scrollable: false,
      body: AppForm(
        guardUnsaved: true,
        errors: view.saveError == null
            ? const <String>[]
            : <String>[view.saveError!],
        fields: <Widget>[
          AppTextField(
            label: Copy.projectName,
            controller: _name,
            requiredness: FieldRequiredness.required,
            textInputAction: TextInputAction.next,
            errorText: view.nameError,
          ),
          AppTextField(
            label: Copy.projectDescription,
            controller: _description,
            requiredness: FieldRequiredness.optional,
            textInputAction: TextInputAction.next,
            maxLines: 3,
          ),
          AppTextField(
            label: Copy.projectOrganisation,
            controller: _organisation,
            requiredness: FieldRequiredness.optional,
            textInputAction: TextInputAction.done,
          ),
          ProjectPhotoField(
            pending: _photo,
            onPicked: (Uint8List bytes) => setState(() => _photo = bytes),
            onRemove: () => setState(() => _photo = null),
          ),
        ],
        submitLabel: duplicating ? Copy.projectsDuplicate : Copy.projectsCreate,
        onSubmit: () async {
          final Project? created = await ref
              .read(_projectCreateProvider.notifier)
              .submit(
                name: _name.text,
                description: _description.text,
                organisation: _organisation.text,
                sourceId: widget.sourceId,
              );
          if (created == null || !context.mounted) {
            return;
          }
          final Uint8List? photo = _photo;
          if (photo != null) {
            final Result<ProjectSettings> stored = await ref
                .read(projectRepositoryProvider)
                .setCoverPhoto(created.id, photo);
            if (!context.mounted) {
              return;
            }
            // The project stands without its photo; say why it is missing.
            if (stored case FailureResult<ProjectSettings>(:final failure)) {
              showAppSnack(context, failure.message, tone: SnackTone.error);
            }
          }
          final GoRouter? router = GoRouter.maybeOf(context);
          if (router != null) {
            router.go(_projectHome(created.id));
          }
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

typedef _ProjectCreateView = ({String? nameError, String? saveError});

class _ProjectCreate extends Notifier<_ProjectCreateView> {
  @override
  _ProjectCreateView build() {
    return (nameError: null, saveError: null);
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
      state = (nameError: Copy.nameRequired, saveError: null);
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
        state = (nameError: null, saveError: null);
        return value;
      case FailureResult<Project>(:final Failure failure):
        state = (nameError: null, saveError: failure.message);
        return null;
    }
  }
}

/// Must match [AppRoutes.project]. This file cannot import `router.dart`.
String _projectHome(String id) {
  return '$_projectsRoot/${Uri.encodeComponent(id)}';
}

const String _projectsRoot = '/projects';
