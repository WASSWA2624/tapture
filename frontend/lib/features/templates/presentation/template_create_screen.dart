import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/templates/presentation/template_locations.dart';

import '../domain/field_def.dart';
import '../domain/template_def.dart';
import '../domain/template_row.dart';
import '../templates.dart' show templateRepositoryProvider;
import 'field_add_sheet.dart';
import 'template_field_rows.dart';

/// A name and any number of fields, saved together, then the field list
/// opens for everything past the three questions (FBK0000144).
class TemplateCreateScreen extends ConsumerStatefulWidget {
  /// Creates the new-template form.
  const TemplateCreateScreen({super.key});

  @override
  ConsumerState<TemplateCreateScreen> createState() =>
      _TemplateCreateScreenState();
}

class _TemplateCreateScreenState extends ConsumerState<TemplateCreateScreen> {
  final TextEditingController _name = TextEditingController();
  final Map<int, TextEditingController> _labels =
      <int, TextEditingController>{};

  @override
  void dispose() {
    _name.dispose();
    for (final TextEditingController label in _labels.values) {
      label.dispose();
    }
    super.dispose();
  }

  TextEditingController _labelFor(int id) {
    return _labels.putIfAbsent(id, TextEditingController.new);
  }

  @override
  Widget build(BuildContext context) {
    final _TemplateCreateView view = ref.watch(_templateCreateProvider);
    final _TemplateCreate notifier = ref.read(_templateCreateProvider.notifier);
    return AppPage(
      key: const ValueKey<String>('route-template-create'),
      title: Copy.templatesCreateTitle,
      scrollable: false,
      body: AppForm(
        guardUnsaved: true,
        dirty: view.dirty,
        errors: <String>[
          ?view.saveError,
          if (view.warnTwoFacts) Copy.fieldTwoFactsWarning,
        ],
        fields: <Widget>[
          AppTextField(
            label: Copy.projectName,
            controller: _name,
            requiredness: FieldRequiredness.required,
            textInputAction: TextInputAction.next,
            errorText: view.nameError,
            onChanged: (String _) => notifier.markDirty(),
          ),
          if (view.warnTwoFacts) ...<Widget>[
            const AppBanner(
              message: Copy.fieldTwoFactsWarning,
              icon: AppIcons.warning,
              tone: SnackTone.warning,
            ),
            AppButton(
              label: Copy.fieldKeepAnyway,
              variant: AppButtonVariant.secondary,
              onPressed: notifier.keepAnyway,
            ),
          ],
          TemplateFieldRows(
            drafts: view.rows,
            labelFor: _labelFor,
            onLabelChanged: (String _) => notifier.markDirty(),
            onType: notifier.setType,
            onRequiredness: notifier.setRequiredness,
            onRemove: (int id) {
              _labels.remove(id)?.dispose();
              notifier.removeRow(id);
            },
            onAdd: notifier.addRow,
          ),
        ],
        submitLabel: Copy.templatesCreate,
        onSubmit: () async {
          final TemplateDef? created = await notifier.submit(
            name: _name.text,
            labels: <int, String>{
              for (final TemplateFieldDraft row in view.rows)
                row.id: _labelFor(row.id).text,
            },
          );
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

/// Draft for one visit to the page (FE-STATE-09).
final NotifierProvider<_TemplateCreate, _TemplateCreateView>
_templateCreateProvider =
    NotifierProvider.autoDispose<_TemplateCreate, _TemplateCreateView>(
      _TemplateCreate.new,
      retry: (int _, Object _) => null,
    );

typedef _TemplateCreateView = ({
  String? nameError,
  String? saveError,
  List<TemplateFieldDraft> rows,
  bool warnTwoFacts,
  bool keepAnyway,
  bool dirty,
  int nextId,
});

class _TemplateCreate extends Notifier<_TemplateCreateView> {
  @override
  _TemplateCreateView build() {
    return (
      nameError: null,
      saveError: null,
      rows: const <TemplateFieldDraft>[_firstRow],
      warnTwoFacts: false,
      keepAnyway: false,
      dirty: false,
      nextId: 1,
    );
  }

  void markDirty() {
    if (!state.dirty) {
      _update(dirty: true);
    }
  }

  void addRow() {
    _update(
      rows: <TemplateFieldDraft>[
        ...state.rows,
        (
          id: state.nextId,
          type: FieldType.text,
          requiredness: Requiredness.optional,
        ),
      ],
      nextId: state.nextId + 1,
      dirty: true,
    );
  }

  void removeRow(int id) {
    _update(
      rows: <TemplateFieldDraft>[
        for (final TemplateFieldDraft row in state.rows)
          if (row.id != id) row,
      ],
      dirty: true,
    );
  }

  void setType(int id, FieldType type) {
    _replace(id, (TemplateFieldDraft row) {
      return (id: row.id, type: type, requiredness: row.requiredness);
    });
  }

  void setRequiredness(int id, Requiredness requiredness) {
    _replace(id, (TemplateFieldDraft row) {
      return (id: row.id, type: row.type, requiredness: requiredness);
    });
  }

  void keepAnyway() {
    _update(keepAnyway: true, warnTwoFacts: false);
  }

  /// Validates, writes the template with every labelled row as a field in
  /// row order, and returns the stored template. A label that packs two
  /// facts warns once; Keep anyway lets the next Create save (FE-SIMP-08).
  Future<TemplateDef?> submit({
    required String name,
    required Map<int, String> labels,
  }) async {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) {
      _update(nameError: Copy.nameRequired, clearSaveError: true);
      return null;
    }
    final String? projectId = ref.read(currentProjectProvider);
    if (projectId == null || projectId.isEmpty) {
      _update(saveError: Copy.statusNoProject, clearNameError: true);
      return null;
    }
    final List<({TemplateFieldDraft row, String label})> named =
        <({TemplateFieldDraft row, String label})>[
          for (final TemplateFieldDraft row in state.rows)
            if ((labels[row.id] ?? '').trim().isNotEmpty)
              (row: row, label: labels[row.id]!.trim()),
        ];
    if (!state.keepAnyway &&
        named.any(
          (({TemplateFieldDraft row, String label}) entry) =>
              FieldAddSheet.packsTwoFacts(entry.label),
        )) {
      _update(warnTwoFacts: true, clearNameError: true, clearSaveError: true);
      return null;
    }
    final List<String> keys = <String>[];
    final List<FieldDef> fields = <FieldDef>[];
    for (int index = 0; index < named.length; index++) {
      final String key = FieldAddSheet.uniqueKey(
        FieldAddSheet.keyFrom(named[index].label),
        keys,
      );
      keys.add(key);
      fields.add(
        FieldDef(
          fieldKey: key,
          label: named[index].label,
          type: named[index].row.type,
          requiredness: named[index].row.requiredness,
          sortOrder: index,
        ),
      );
    }
    final Result<TemplateDef> result = await ref
        .read(templateRepositoryProvider)
        .save(
          TemplateDef(
            id: '',
            templateKey: _keyFor(trimmed),
            name: trimmed,
            version: 1,
            fields: fields,
            identityFieldKeys: const <String>[],
            rows: const <TemplateRow>[],
            projectId: projectId,
          ),
        );
    switch (result) {
      case Success<TemplateDef>(:final TemplateDef value):
        _update(clearNameError: true, clearSaveError: true, dirty: false);
        return value;
      case FailureResult<TemplateDef>(:final Failure failure):
        _update(saveError: failure.message, clearNameError: true);
        return null;
    }
  }

  void _replace(
    int id,
    TemplateFieldDraft Function(TemplateFieldDraft row) change,
  ) {
    _update(
      rows: <TemplateFieldDraft>[
        for (final TemplateFieldDraft row in state.rows)
          row.id == id ? change(row) : row,
      ],
      dirty: true,
    );
  }

  void _update({
    String? nameError,
    bool clearNameError = false,
    String? saveError,
    bool clearSaveError = false,
    List<TemplateFieldDraft>? rows,
    bool? warnTwoFacts,
    bool? keepAnyway,
    bool? dirty,
    int? nextId,
  }) {
    state = (
      nameError: clearNameError ? null : (nameError ?? state.nameError),
      saveError: clearSaveError ? null : (saveError ?? state.saveError),
      rows: rows ?? state.rows,
      warnTwoFacts: warnTwoFacts ?? state.warnTwoFacts,
      keepAnyway: keepAnyway ?? state.keepAnyway,
      dirty: dirty ?? state.dirty,
      nextId: nextId ?? state.nextId,
    );
  }
}

/// The page opens with one empty row (FBK0000144).
const TemplateFieldDraft _firstRow = (
  id: 0,
  type: FieldType.text,
  requiredness: Requiredness.optional,
);

String _keyFor(String name) {
  final String slug = name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return slug.isEmpty ? 'template' : slug;
}
