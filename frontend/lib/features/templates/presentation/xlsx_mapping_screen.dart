import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/export/xlsx_sheet.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/project_folders.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/import/import.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/app_radio_group.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/projects/projects.dart';

import '../domain/field_def.dart';
import '../domain/template_def.dart';
import '../domain/template_row.dart';
import '../templates.dart' show XlsxTemplateImport, templateRepositoryProvider;
import 'field_add_sheet.dart';

/// Two-column confirmation of spreadsheet columns against proposed fields.
class XlsxMappingScreen extends ConsumerWidget {
  /// Creates the mapping screen. [path] is the chosen workbook.
  const XlsxMappingScreen({
    super.key,
    this.path,
    this.projectId,
    this.project,
    this.persist,
  });

  /// Absolute path of the chosen spreadsheet. Blank is the empty state.
  final String? path;

  /// Owning project. Falls back to the open project.
  final String? projectId;

  /// Owning project row. Tests pass this so the list does not have to load.
  final Project? project;

  /// Writes the confirmed mapping. Null uses [XlsxTemplateImport.apply].
  final Future<Result<TemplateDef>> Function({
    required String projectId,
    required String projectName,
    required String folderName,
    required String path,
    required TemplateDef draft,
  })?
  persist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Project? project =
        this.project ?? ref.watch(currentProjectDetailsProvider);
    final String? wantedId =
        projectId ?? project?.id ?? ref.watch(currentProjectProvider);
    final String path = this.path?.trim() ?? '';
    if (path.isEmpty ||
        project == null ||
        project.id.isEmpty ||
        (wantedId != null && wantedId.isNotEmpty && project.id != wantedId)) {
      return const AppPage(
        key: ValueKey<String>('route-xlsx-mapping'),
        title: Copy.xlsxMappingTitle,
        body: AppEmptyState(
          icon: Icons.table_chart_outlined,
          headline: Copy.xlsxMappingEmptyHeadline,
          message: Copy.xlsxMappingEmptyMessage,
        ),
      );
    }
    final AsyncValue<WorkbookSnapshot> value = ref.watch(
      _xlsxWorkbookProvider(path),
    );
    final _XlsxMappingView view = ref.watch(_xlsxMappingProvider(path));
    return AppPage(
      key: const ValueKey<String>('route-xlsx-mapping'),
      title: Copy.xlsxMappingTitle,
      scrollable: false,
      footer: value.maybeWhen(
        data: (WorkbookSnapshot book) {
          if (book.sheets.isEmpty || book.sheets.first.columns.isEmpty) {
            return null;
          }
          return AppPrimaryAction(
            label: Copy.xlsxMappingConfirm,
            busy: view.confirming,
            onPressed: () => unawaited(_commit(context, ref, project, path)),
          );
        },
        orElse: () => null,
      ),
      body: AsyncValueView<WorkbookSnapshot>(
        value: value,
        isEmpty: (WorkbookSnapshot book) =>
            book.sheets.isEmpty || book.sheets.first.columns.isEmpty,
        empty: () => const AppEmptyState(
          icon: Icons.table_chart_outlined,
          headline: Copy.xlsxMappingEmptyHeadline,
          message: Copy.xlsxMappingEmptyMessage,
        ),
        onRetry: () => ref.invalidate(_xlsxWorkbookProvider(path)),
        data: (WorkbookSnapshot _) => _list(ref, path, view),
      ),
    );
  }

  Widget _list(WidgetRef ref, String path, _XlsxMappingView view) {
    final _XlsxMapping controller = ref.read(
      _xlsxMappingProvider(path).notifier,
    );
    return ListView(
      padding: const EdgeInsets.only(bottom: Space.x4),
      children: <Widget>[
        if (view.saveError != null)
          AppBanner(
            message: view.saveError!,
            icon: Icons.error_outline,
            tone: SnackTone.error,
          ),
        for (final _XlsxRow row in view.rows) ...<Widget>[
          AppListTile(
            key: ValueKey<String>('xlsx-col-${row.index}'),
            title: row.source,
            subtitle: row.skipped
                ? Copy.xlsxMappingSkipped
                : Copy.xlsxMappingProposal(
                    field: row.label,
                    type: Copy.fieldTypeLabel(row.type.name),
                    rule: _ruleCopy(row.rule),
                  ),
            selected: view.editing == row.index,
            trailing: AppOverflowMenu(
              items: <AppOverflowAction>[
                AppOverflowAction(
                  label: row.skipped
                      ? Copy.xlsxMappingInclude
                      : Copy.xlsxMappingSkip,
                  icon: row.skipped
                      ? Icons.add_outlined
                      : Icons.remove_circle_outline,
                  onTap: () => controller.toggleSkip(row.index),
                ),
              ],
            ),
            onTap: () => controller.edit(row.index),
          ),
          if (view.editing == row.index && !row.skipped)
            _editor(controller, row),
        ],
      ],
    );
  }

  Widget _editor(_XlsxMapping controller, _XlsxRow row) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.x4,
        Space.x2,
        Space.x4,
        Space.x2,
      ),
      child: Column(
        children: <Widget>[
          _XlsxLabelField(
            key: ValueKey<String>('xlsx-label-${row.index}'),
            value: row.label,
            onChanged: (String next) => controller.setLabel(row.index, next),
          ),
          AppChoiceField<FieldType>(
            label: Copy.fieldType,
            value: row.type,
            options: <Choice<FieldType>>[
              for (final FieldType type in FieldType.values)
                Choice<FieldType>(type, Copy.fieldTypeLabel(type.name)),
            ],
            onChanged: (FieldType? type) {
              if (type != null) {
                controller.setType(row.index, type);
              }
            },
          ),
          AppRadioGroup<Requiredness>(
            label: Copy.fieldRequiredness,
            value: row.rule,
            direction: Axis.horizontal,
            options: const <Choice<Requiredness>>[
              Choice<Requiredness>(Requiredness.required, Copy.fieldRequired),
              Choice<Requiredness>(
                Requiredness.recommended,
                Copy.fieldRecommended,
              ),
              Choice<Requiredness>(Requiredness.optional, Copy.fieldOptional),
            ],
            onChanged: (Requiredness value) {
              controller.setRule(row.index, value);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _commit(
    BuildContext context,
    WidgetRef ref,
    Project project,
    String path,
  ) async {
    final TemplateDef? saved = await ref
        .read(_xlsxMappingProvider(path).notifier)
        .commit(project: project, path: path, persist: persist);
    if (saved == null || !context.mounted) {
      return;
    }
    GoRouter.maybeOf(context)?.go(_fieldsLocation(saved.id));
  }
}

typedef _XlsxMappingView = ({
  List<_XlsxRow> rows,
  int? editing,
  String? saveError,
  bool confirming,
  bool dirty,
});

final class _XlsxRow {
  const _XlsxRow({
    required this.index,
    required this.source,
    required this.label,
    required this.type,
    required this.rule,
    required this.outputColumn,
    required this.options,
    required this.unit,
    required this.skipped,
  });

  final int index;
  final String source;
  final String label;
  final FieldType type;
  final Requiredness rule;
  final String outputColumn;
  final List<String> options;
  final String? unit;
  final bool skipped;

  _XlsxRow copyWith({
    String? label,
    FieldType? type,
    Requiredness? rule,
    bool? skipped,
  }) {
    return _XlsxRow(
      index: index,
      source: source,
      label: label ?? this.label,
      type: type ?? this.type,
      rule: rule ?? this.rule,
      outputColumn: outputColumn,
      options: options,
      unit: unit,
      skipped: skipped ?? this.skipped,
    );
  }
}

final class _XlsxMapping extends Notifier<_XlsxMappingView> {
  _XlsxMapping(this.path);

  final String path;

  _XlsxMappingView? _held;

  @override
  _XlsxMappingView build() {
    ref.onDispose(() => _held = null);
    final _XlsxMappingView? held = _held;
    if (held != null && held.dirty) {
      return held;
    }
    final WorkbookSnapshot? book = ref
        .watch(_xlsxWorkbookProvider(path))
        .asData
        ?.value;
    if (book == null || book.sheets.isEmpty) {
      return (
        rows: const <_XlsxRow>[],
        editing: null,
        saveError: null,
        confirming: false,
        dirty: false,
      );
    }
    return (
      rows: _rowsOf(book.sheets.first),
      editing: null,
      saveError: null,
      confirming: false,
      dirty: false,
    );
  }

  void toggleSkip(int index) {
    _setRows(<_XlsxRow>[
      for (final _XlsxRow row in state.rows)
        row.index == index ? row.copyWith(skipped: !row.skipped) : row,
    ], editing: state.editing == index ? null : state.editing);
  }

  void edit(int index) {
    _setRows(state.rows, editing: state.editing == index ? null : index);
  }

  void setLabel(int index, String label) {
    _setRows(<_XlsxRow>[
      for (final _XlsxRow row in state.rows)
        row.index == index ? row.copyWith(label: label) : row,
    ], editing: state.editing);
  }

  void setType(int index, FieldType type) {
    _setRows(<_XlsxRow>[
      for (final _XlsxRow row in state.rows)
        row.index == index ? row.copyWith(type: type) : row,
    ], editing: state.editing);
  }

  void setRule(int index, Requiredness rule) {
    _setRows(<_XlsxRow>[
      for (final _XlsxRow row in state.rows)
        row.index == index ? row.copyWith(rule: rule) : row,
    ], editing: state.editing);
  }

  Future<TemplateDef?> commit({
    required Project project,
    required String path,
    Future<Result<TemplateDef>> Function({
      required String projectId,
      required String projectName,
      required String folderName,
      required String path,
      required TemplateDef draft,
    })?
    persist,
  }) async {
    if (state.confirming) {
      return null;
    }
    final WorkbookSnapshot? book = ref
        .read(_xlsxWorkbookProvider(path))
        .asData
        ?.value;
    if (book == null || book.sheets.isEmpty) {
      _fail(
        const StorageFailure(
          message: Copy.xlsxMappingMissing,
          recoveryAction: Copy.xlsxMappingMissingRecovery,
        ),
      );
      return null;
    }
    state = (
      rows: state.rows,
      editing: state.editing,
      saveError: null,
      confirming: true,
      dirty: true,
    );
    _held = state;
    final WorkbookSheet sheet = book.sheets.first;
    final TemplateDef draft = _draft(project, sheet, state.rows);
    final Result<TemplateDef> result = persist == null
        ? await _importer().apply(
            projectId: project.id,
            projectName: project.name,
            folderName: project.folderName,
            path: path,
            draft: draft,
          )
        : await persist(
            projectId: project.id,
            projectName: project.name,
            folderName: project.folderName,
            path: path,
            draft: draft,
          );
    switch (result) {
      case Success<TemplateDef>(:final TemplateDef value):
        state = (
          rows: state.rows,
          editing: state.editing,
          saveError: null,
          confirming: false,
          dirty: false,
        );
        _held = state;
        return value;
      case FailureResult<TemplateDef>(:final Failure failure):
        _fail(failure);
        return null;
    }
  }

  void _setRows(List<_XlsxRow> rows, {required int? editing}) {
    state = (
      rows: rows,
      editing: editing,
      saveError: null,
      confirming: false,
      dirty: true,
    );
    _held = state;
  }

  void _fail(Failure failure) {
    state = (
      rows: state.rows,
      editing: state.editing,
      saveError: failure.message,
      confirming: false,
      dirty: true,
    );
    _held = state;
  }

  XlsxTemplateImport _importer() {
    final StorageRoot storage = ref.read(storageRootProvider);
    return XlsxTemplateImport(
      storageRoot: storage,
      folders: ProjectFolders(storageRoot: storage),
      writer: FileWriter(storageRoot: storage),
      templates: ref.read(templateRepositoryProvider),
    );
  }
}

final _xlsxWorkbookProvider = FutureProvider.autoDispose
    .family<WorkbookSnapshot, String>((Ref ref, String path) async {
      final Result<WorkbookSnapshot> result = await WorkbookReader.open(path);
      return switch (result) {
        Success<WorkbookSnapshot>(:final WorkbookSnapshot value) => value,
        FailureResult<WorkbookSnapshot>(:final Failure failure) =>
          throw failure,
      };
    }, retry: (int _, Object _) => null);

final _xlsxMappingProvider = NotifierProvider.autoDispose
    .family<_XlsxMapping, _XlsxMappingView, String>(
      _XlsxMapping.new,
      retry: (int _, Object _) => null,
    );

class _XlsxLabelField extends StatefulWidget {
  const _XlsxLabelField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_XlsxLabelField> createState() => _XlsxLabelFieldState();
}

class _XlsxLabelFieldState extends State<_XlsxLabelField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(_XlsxLabelField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.value = TextEditingValue(text: widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: Copy.fieldLabel,
      controller: _controller,
      onChanged: widget.onChanged,
    );
  }
}

List<_XlsxRow> _rowsOf(WorkbookSheet sheet) {
  return <_XlsxRow>[
    for (int index = 0; index < sheet.columns.length; index++)
      _rowOf(index, sheet.columns[index]),
  ];
}

_XlsxRow _rowOf(int index, ColumnSuggestion column) {
  final String letter = XlsxSheet.columnName(index);
  final String header = column.header.trim();
  return _XlsxRow(
    index: index,
    source: header.isEmpty ? letter : header,
    label: header.isEmpty ? Copy.xlsxMappingUntitled(letter) : header,
    type: XlsxTemplateImport.typeFromWire(column.typeName),
    rule: Requiredness.optional,
    outputColumn: letter,
    options: column.options,
    unit: column.unit,
    skipped: false,
  );
}

TemplateDef _draft(Project project, WorkbookSheet sheet, List<_XlsxRow> rows) {
  final String name = sheet.name.trim().isEmpty
      ? Copy.xlsxMappingDefaultName
      : sheet.name.trim();
  final Set<String> taken = <String>{};
  final List<FieldDef> fields = <FieldDef>[];
  var order = 0;
  for (final _XlsxRow row in rows) {
    if (row.skipped) {
      continue;
    }
    final String key = FieldAddSheet.uniqueKey(
      FieldAddSheet.keyFrom(row.label.trim().isEmpty ? row.source : row.label),
      taken,
    );
    taken.add(key);
    fields.add(
      FieldDef(
        fieldKey: key,
        label: row.label.trim().isEmpty ? row.source : row.label.trim(),
        type: row.type,
        requiredness: row.rule,
        unit: row.unit,
        options: row.options,
        outputColumn: row.outputColumn,
        sortOrder: order,
      ),
    );
    order += 1;
  }
  return TemplateDef(
    id: '',
    templateKey: FieldAddSheet.keyFrom(name),
    name: name,
    version: 1,
    fields: fields,
    identityFieldKeys: const <String>[],
    rows: const <TemplateRow>[],
    projectId: project.id,
    source: 'imported',
    sheetName: sheet.name,
    headerRow: sheet.header.rowNumber,
  );
}

String _ruleCopy(Requiredness rule) {
  return switch (rule) {
    Requiredness.required => Copy.fieldRequired,
    Requiredness.recommended => Copy.fieldRecommended,
    Requiredness.optional => Copy.fieldOptional,
  };
}

/// Must match [AppRoutes.template]. This file cannot import `router.dart`.
String _fieldsLocation(String id) {
  return '$_templatesRoot/${Uri.encodeComponent(id)}';
}

const String _templatesRoot = '/templates';
