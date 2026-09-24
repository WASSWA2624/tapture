import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/templates/presentation/template_locations.dart';

import '../domain/field_def.dart';
import '../domain/template_def.dart';
import '../domain/template_row.dart';
import '../templates.dart' show templateRepositoryProvider;

/// Asks only for a name, then opens the field list so one field makes it usable.
class TemplateCreateScreen extends ConsumerStatefulWidget {
  /// Creates the blank-template form.
  const TemplateCreateScreen({super.key});

  @override
  ConsumerState<TemplateCreateScreen> createState() =>
      _TemplateCreateScreenState();
}

class _TemplateCreateScreenState extends ConsumerState<TemplateCreateScreen> {
  final TextEditingController _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _TemplateCreateView view = ref.watch(_templateCreateProvider);
    return AppPage(
      key: const ValueKey<String>('route-template-create'),
      title: Copy.templatesCreateTitle,
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
            textInputAction: TextInputAction.done,
            errorText: view.nameError,
          ),
        ],
        submitLabel: Copy.templatesCreate,
        onSubmit: () async {
          final TemplateDef? created = await ref
              .read(_templateCreateProvider.notifier)
              .submit(name: _name.text);
          if (created == null || !context.mounted) {
            return;
          }
          final GoRouter? router = GoRouter.maybeOf(context);
          if (router != null) {
            router.go(TemplateLocations.detail(context, created.id));
          }
        },
      ),
    );
  }
}

final NotifierProvider<_TemplateCreate, _TemplateCreateView>
_templateCreateProvider =
    NotifierProvider<_TemplateCreate, _TemplateCreateView>(
      _TemplateCreate.new,
      retry: (int _, Object _) => null,
    );

typedef _TemplateCreateView = ({String? nameError, String? saveError});

class _TemplateCreate extends Notifier<_TemplateCreateView> {
  @override
  _TemplateCreateView build() {
    return (nameError: null, saveError: null);
  }

  /// Validates, writes a nameless-field template, and returns the stored row.
  Future<TemplateDef?> submit({required String name}) async {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) {
      state = (nameError: Copy.nameRequired, saveError: null);
      return null;
    }
    final String? projectId = ref.read(currentProjectProvider);
    if (projectId == null || projectId.isEmpty) {
      state = (nameError: null, saveError: Copy.statusNoProject);
      return null;
    }
    final Result<TemplateDef> result = await ref
        .read(templateRepositoryProvider)
        .save(
          TemplateDef(
            id: '',
            templateKey: _keyFor(trimmed),
            name: trimmed,
            version: 1,
            fields: const <FieldDef>[],
            identityFieldKeys: const <String>[],
            rows: const <TemplateRow>[],
            projectId: projectId,
          ),
        );
    switch (result) {
      case Success<TemplateDef>(:final TemplateDef value):
        state = (nameError: null, saveError: null);
        return value;
      case FailureResult<TemplateDef>(:final Failure failure):
        state = (nameError: null, saveError: failure.message);
        return null;
    }
  }
}

String _keyFor(String name) {
  final String slug = name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return slug.isEmpty ? 'template' : slug;
}

/// Must match [AppRoutes.template]. This file cannot import `router.dart`.