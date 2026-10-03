import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/export/xlsx_sheet.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/picked_document.dart';
import 'package:tapture/core/files/project_folders.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/import/import.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/app_radio_group.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/templates/presentation/template_locations.dart';

import '../domain/field_def.dart';
import '../domain/template_def.dart';
import '../domain/template_row.dart';
import '../templates.dart'
    show
        XlsxTemplateImport,
        PredefinedRowsImport,
        TemplateDocumentImport,
        templateRepositoryProvider;
import 'field_add_sheet.dart';
import 'xlsx_document_controller.dart';

/// Two-column confirmation of spreadsheet columns against proposed fields.
class XlsxMappingScreen extends ConsumerWidget {
  /// Creates the mapping screen. [path] is the chosen workbook.
  const XlsxMappingScreen({
    super.key,
    this.path,
    this.document,
    this.targetTemplateId,
    this.projectId,
    this.project,
    this.persist,
  });

  /// Absolute path of the chosen spreadsheet. Blank is the empty state.
  final String? path;

  /// A validated device or browser pick, owned until this page closes.
  final PickedDocument? document;

  /// When set, import checklist rows onto this existing template.
  final String? targetTemplateId;

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
    final LocalizedCopy localCopy = Copy.of(context);

    final String? wantedId =
        projectId ??
        this.project?.id ??
        (GoRouter.maybeOf(context) == null
            ? null
            : TemplateLocations.projectIdOf(context)) ??
        ref.watch(currentProjectProvider);
    final Project? project =
        this.project ??
        (wantedId == null
            ? null
            : ref.watch(projectByIdProvider(wantedId)).asData?.value);
    final Object? initial =
        document ?? ((path?.trim().isEmpty ?? true) ? null : path);
    final AsyncValue<Object?> picked = ref.watch(
      xlsxDocumentControllerProvider(initial),
    );
    void choose() => unawaited(
      ref.read(xlsxDocumentControllerProvider(initial).notifier).choose(),
    );
    final Object? source = picked.asData?.value;
    if (source == null ||
        project == null ||
        project.id.isEmpty ||
        (wantedId != null && wantedId.isNotEmpty && project.id != wantedId)) {
      return AppPage(
        key: const ValueKey<String>('route-xlsx-mapping'),
        title: localCopy.xlsxMappingTitle,
        body: AsyncValueView<Object?>(
          value: picked,
          isEmpty: (_) => true,
          empty: () => AppEmptyState(
            icon: AppIcons.dataset,
            headline: Copy.of(context).xlsxMappingEmptyHeadline,
            message: Copy.of(context).xlsxMappingEmptyMessage,
            actionLabel: wantedId == null
                ? Copy.of(context).navProjects
                : Copy.of(context).templatesImport,
            onAction: wantedId == null
                ? () => context.go(RoutePaths.projects)
                : choose,
          ),
          onRetry: choose,
          data: (_) => const SizedBox.shrink(),
        ),
      );
    }
    final AsyncValue<WorkbookSnapshot> value = ref.watch(
      xlsxWorkbookProvider(source),
    );
    final _XlsxMappingView view = ref.watch(_xlsxMappingProvider(source));
    Future<void> commit() => _commit(context, ref, project, source);
    return AppPage(
      key: const ValueKey<String>('route-xlsx-mapping'),
      title: localCopy.xlsxMappingTitle,
      scrollable: false,
      footer: value.maybeWhen(
        data: (WorkbookSnapshot book) {
          final LocalizedCopy localCopy = Copy.of(context);

          if (book.sheets.isEmpty || book.sheets.first.columns.isEmpty) {
            return null;
          }
          return AppPrimaryAction(
            label: localCopy.xlsxMappingConfirm,
            busy: view.confirming,
            onPressed: commit,
          );
        },
        orElse: () => null,
      ),
      body: AsyncValueView<WorkbookSnapshot>(
        value: value,
        isEmpty: (WorkbookSnapshot book) =>
            book.sheets.isEmpty || book.sheets.first.columns.isEmpty,
        empty: () => AppEmptyState(
          icon: AppIcons.dataset,
          headline: Copy.of(context).xlsxMappingEmptyHeadline,
          message: Copy.of(context).xlsxMappingEmptyMessage,
          actionLabel: Copy.of(context).templatesImport,
          onAction: choose,
        ),
        onRetry: () => ref.invalidate(xlsxWorkbookProvider(source)),
        data: (WorkbookSnapshot book) =>
            _list(context, ref, source, view, book.sheets.first),
      ),
    );
  }

  Widget _list(
    BuildContext context,
    WidgetRef ref,
    Object source,
    _XlsxMappingView view,
    WorkbookSheet sheet,
  ) {
    final _XlsxMapping controller = ref.read(
      _xlsxMappingProvider(source).notifier,
    );
    return ListView(
      padding: const EdgeInsets.only(bottom: Space.x4),
      children: <Widget>[
        AppSectionHeader(
          title: Copy.of(context).checklistTitle,
          expanded: targetTemplateId == null ? view.rowColumns.expanded : null,
          onToggle: targetTemplateId == null ? controller.toggleRows : null,
        ),
        if (view.rowColumns.expanded || targetTemplateId != null)
          _rowColumns(context, controller, view, sheet),
        if (Copy.of(
              context,
            ).stateText(view.localizedSaveError, view.saveError) !=
            null)
          AppBanner(
            message: Copy.of(
              context,
            ).stateText(view.localizedSaveError, view.saveError)!,
            icon: AppIcons.error,
            tone: SnackTone.error,
          ),
        if (targetTemplateId == null)
          for (final _XlsxRow row in view.rows) ...<Widget>[
            AppListTile(
              key: ValueKey<String>('xlsx-col-${row.index}'),
              title: row.source,
              subtitle: row.skipped
                  ? Copy.of(context).xlsxMappingSkipped
                  : Copy.of(context).xlsxMappingProposal(
                      field: row.label,
                      type: Copy.of(context).fieldTypeLabel(row.type.name),
                      rule: _ruleCopy(
                        row.rule,
                        localizedCopy: Copy.of(context),
                      ),
                    ),
              selected: view.editing == row.index,
              trailing: AppOverflowMenu(
                items: <AppOverflowAction>[
                  AppOverflowAction(
                    label: row.skipped
                        ? Copy.of(context).xlsxMappingInclude
                        : Copy.of(context).xlsxMappingSkip,
                    icon: row.skipped ? AppIcons.add : AppIcons.remove,
                    onTap: () => controller.toggleSkip(row.index),
                  ),
                ],
              ),
              onTap: () => controller.edit(row.index),
            ),
            if (view.editing == row.index && !row.skipped)
              _editor(context, controller, row),
          ],
      ],
    );
  }

  Widget _editor(BuildContext context, _XlsxMapping controller, _XlsxRow row) {
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
            label: Copy.of(context).fieldType,
            value: row.type,
            options: <Choice<FieldType>>[
              for (final FieldType type in FieldType.values)
                Choice<FieldType>(
                  type,
                  Copy.of(context).fieldTypeLabel(type.name),
                ),
            ],
            onChanged: (FieldType? type) {
              if (type != null) {
                controller.setType(row.index, type);
              }
            },
          ),
          AppRadioGroup<Requiredness>(
            label: Copy.of(context).fieldRequiredness,
            value: row.rule,
            direction: Axis.horizontal,
            options: <Choice<Requiredness>>[
              Choice<Requiredness>(
                Requiredness.required,
                Copy.of(context).fieldRequired,
              ),
              Choice<Requiredness>(
                Requiredness.recommended,
                Copy.of(context).fieldRecommended,
              ),
              Choice<Requiredness>(
                Requiredness.optional,
                Copy.of(context).fieldOptional,
              ),
            ],
            onChanged: (Requiredness value) {
              controller.setRule(row.index, value);
            },
          ),
        ],
      ),
    );
  }

  Widget _rowColumns(
    BuildContext context,
    _XlsxMapping controller,
    _XlsxMappingView view,
    WorkbookSheet sheet,
  ) {
    final _RowColumns columns = view.rowColumns;
    final List<Choice<String>> options = <Choice<String>>[
      Choice<String>('', Copy.of(context).fieldPatternNone),
      for (int index = 0; index < sheet.columns.length; index++)
        Choice<String>(
          XlsxSheet.columnName(index),
          '${XlsxSheet.columnName(index)} · ${sheet.columns[index].header}',
        ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.x4),
      child: Column(
        children: <Widget>[
          for (final ({_RowColumn kind, String label, String value}) entry
              in <({_RowColumn kind, String label, String value})>[
                (
                  kind: _RowColumn.identifier,
                  label: Copy.of(context).checklistIdentifierColumn,
                  value: columns.identifier,
                ),
                (
                  kind: _RowColumn.label,
                  label: Copy.of(context).checklistLabelColumn,
                  value: columns.label,
                ),
                (
                  kind: _RowColumn.alias,
                  label: Copy.of(context).rowAliasesColumn,
                  value: columns.alias,
                ),
                (
                  kind: _RowColumn.context,
                  label: Copy.of(context).checklistContextColumn,
                  value: columns.context,
                ),
              ])
            AppChoiceField<String>(
              key: ValueKey<String>('checklist-column-${entry.kind.name}'),
              label: entry.label,
              value: entry.value,
              options: options,
              onChanged: (String? value) =>
                  controller.setRowColumn(entry.kind, value ?? ''),
            ),
        ],
      ),
    );
  }

  Future<void> _commit(
    BuildContext context,
    WidgetRef ref,
    Project project,
    Object source,
  ) async {
    final TemplateDef? saved = await ref
        .read(_xlsxMappingProvider(source).notifier)
        .commit(
          project: project,
          source: source,
          persist: persist,
          targetTemplateId: targetTemplateId,
        );
    if (saved == null || !context.mounted) {
      return;
    }
    GoRouter.maybeOf(context)?.go(TemplateLocations.detail(context, saved.id));
  }
}

typedef _XlsxMappingView = ({
  List<_XlsxRow> rows,
  int? editing,
  String? saveError,
  LocalizedMessage? localizedSaveError,
  bool confirming,
  bool dirty,
  _RowColumns rowColumns,
});

typedef _RowColumns = ({
  bool expanded,
  String identifier,
  String label,
  String alias,
  String context,
});
const _RowColumns _noRowColumns = (
  expanded: false,
  identifier: '',
  label: '',
  alias: '',
  context: '',
);

enum _RowColumn { identifier, label, alias, context }

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
  _XlsxMapping(this.source);

  final Object source;

  _XlsxMappingView? _held;

  void toggleRows() => _setRowColumns((
    expanded: !state.rowColumns.expanded,
    identifier: state.rowColumns.identifier,
    label: state.rowColumns.label,
    alias: state.rowColumns.alias,
    context: state.rowColumns.context,
  ));

  void setRowColumn(_RowColumn kind, String value) => _setRowColumns((
    expanded: true,
    identifier: kind == _RowColumn.identifier
        ? value
        : state.rowColumns.identifier,
    label: kind == _RowColumn.label ? value : state.rowColumns.label,
    alias: kind == _RowColumn.alias ? value : state.rowColumns.alias,
    context: kind == _RowColumn.context ? value : state.rowColumns.context,
  ));

  void _setRowColumns(_RowColumns columns) {
    state = (
      rows: state.rows,
      editing: state.editing,
      saveError: null,
      localizedSaveError: null,
      confirming: false,
      dirty: true,
      rowColumns: columns,
    );
    _held = state;
  }

  @override
  _XlsxMappingView build() {
    ref.onDispose(() => _held = null);
    final _XlsxMappingView? held = _held;
    if (held != null && held.dirty) {
      return held;
    }
    final WorkbookSnapshot? book = ref
        .watch(xlsxWorkbookProvider(source))
        .asData
        ?.value;
    if (book == null || book.sheets.isEmpty) {
      return (
        rows: const <_XlsxRow>[],
        editing: null,
        saveError: null,
        localizedSaveError: null,
        confirming: false,
        dirty: false,
        rowColumns: _noRowColumns,
      );
    }
    return (
      rows: _rowsOf(book.sheets.first),
      editing: null,
      saveError: null,
      localizedSaveError: null,
      confirming: false,
      dirty: false,
      rowColumns: _noRowColumns,
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
    required Object source,
    String? targetTemplateId,
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
        .read(xlsxWorkbookProvider(source))
        .asData
        ?.value;
    if (book == null || book.sheets.isEmpty) {
      _fail(
        StorageFailure(
          localizedMessage: Copy.messages.xlsxMappingMissing,
          localizedRecovery: Copy.messages.xlsxMappingMissingRecovery,
        ),
      );
      return null;
    }
    state = (
      rows: state.rows,
      editing: state.editing,
      saveError: null,
      localizedSaveError: null,
      confirming: true,
      dirty: true,
      rowColumns: state.rowColumns,
    );
    _held = state;
    final WorkbookSheet sheet = book.sheets.first;
    final _RowColumns columns = state.rowColumns;
    final bool wantsRows =
        columns.identifier.isNotEmpty ||
        columns.label.isNotEmpty ||
        targetTemplateId != null;
    if (wantsRows && (columns.identifier.isEmpty || columns.label.isEmpty)) {
      _fail(
        ValidationFailure(
          localizedMessage: Copy.messages.checklistMappingIncomplete,
          localizedRecovery: Copy.messages.checklistMappingRecovery,
        ),
      );
      return null;
    }
    final List<TemplateRow> rows = wantsRows
        ? PredefinedRowsImport.draft(
            rows: sheet.rows,
            headerRow: sheet.header.rowNumber,
            identifierColumn: columns.identifier,
            labelColumn: columns.label,
            aliasColumn: columns.alias.isEmpty ? null : columns.alias,
            contextColumn: columns.context.isEmpty ? null : columns.context,
          )
        : const <TemplateRow>[];
    TemplateDef draft = _draft(project, sheet, state.rows).copyWith(rows: rows);
    if (targetTemplateId != null) {
      final Result<TemplateDef?> found = await ref
          .read(templateRepositoryProvider)
          .byId(targetTemplateId);
      if (!ref.mounted) return null;
      if (found case FailureResult<TemplateDef?>(:final Failure failure)) {
        _fail(failure);
        return null;
      }
      final TemplateDef? target = (found as Success<TemplateDef?>).value;
      if (target == null || target.projectId != project.id) {
        _fail(
          ValidationFailure(
            localizedMessage: Copy.messages.xlsxMappingMissing,
            localizedRecovery: Copy.messages.xlsxMappingMissingRecovery,
          ),
        );
        return null;
      }
      draft = target.copyWith(
        rows: rows,
        sheetName: sheet.name,
        headerRow: sheet.header.rowNumber,
      );
    }
    final String path = switch (source) {
      String() => source,
      PickedFile(:final file) => file.path,
      PickedDocument(:final String name) => name,
      _ => '',
    };
    final Result<TemplateDef> result = persist == null
        ? source is PickedDocument
              ? await _importer().applyDocument(
                  projectId: project.id,
                  projectName: project.name,
                  folderName: project.folderName,
                  document: source,
                  draft: draft,
                )
              : await _importer().apply(
                  projectId: project.id,
                  projectName: project.name,
                  folderName: project.folderName,
                  path: path,
                  draft: draft,
                  preserveId: targetTemplateId != null,
                )
        : await persist(
            projectId: project.id,
            projectName: project.name,
            folderName: project.folderName,
            path: path,
            draft: draft,
          );
    if (!ref.mounted) return null;
    switch (result) {
      case Success<TemplateDef>(:final TemplateDef value):
        state = (
          rows: state.rows,
          editing: state.editing,
          saveError: null,
          localizedSaveError: null,
          confirming: false,
          dirty: false,
          rowColumns: state.rowColumns,
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
      localizedSaveError: null,
      confirming: false,
      dirty: true,
      rowColumns: state.rowColumns,
    );
    _held = state;
  }

  void _fail(Failure failure) {
    state = (
      rows: state.rows,
      editing: state.editing,
      saveError: failure.message,
      localizedSaveError: failure.explanation,
      confirming: false,
      dirty: true,
      rowColumns: state.rowColumns,
    );
    _held = state;
  }

  XlsxTemplateImport _importer() {
    final StorageRoot storage = ref.read(storageRootProvider);
    return XlsxTemplateImport(
      storageRoot: storage,
      folders: ProjectFolders(storageRoot: storage),
      writer: ref.read(fileWriterProvider),
      templates: ref.read(templateRepositoryProvider),
    );
  }
}

final xlsxWorkbookProvider = FutureProvider.autoDispose
    .family<WorkbookSnapshot, Object>((Ref ref, Object source) async {
      final CancellationToken cancel = CancellationToken();
      ref.onDispose(cancel.cancel);
      final Result<WorkbookSnapshot> result = source is PickedDocument
          ? await TemplateDocumentImport.workbook(source, cancel: cancel)
          : await WorkbookReader.open(source as String, cancel: cancel);
      return switch (result) {
        Success<WorkbookSnapshot>(:final WorkbookSnapshot value) => value,
        FailureResult<WorkbookSnapshot>(:final Failure failure) =>
          throw failure,
      };
    }, retry: (int _, Object _) => null);

final _xlsxMappingProvider = NotifierProvider.autoDispose
    .family<_XlsxMapping, _XlsxMappingView, Object>(
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
    final LocalizedCopy localCopy = Copy.of(context);

    return AppTextField(
      label: localCopy.fieldLabel,
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

_XlsxRow _rowOf(
  int index,
  ColumnSuggestion column, {
  LocalizedCopy? localizedCopy,
}) {
  final String letter = XlsxSheet.columnName(index);
  final String header = column.header.trim();
  return _XlsxRow(
    index: index,
    source: header.isEmpty ? letter : header,
    label: header.isEmpty
        ? (localizedCopy ?? Copy.english).xlsxMappingUntitled(letter)
        : header,
    type: XlsxTemplateImport.typeFromWire(column.typeName),
    rule: Requiredness.optional,
    outputColumn: letter,
    options: column.options,
    unit: column.unit,
    skipped: false,
  );
}

TemplateDef _draft(
  Project project,
  WorkbookSheet sheet,
  List<_XlsxRow> rows, {
  LocalizedCopy? localizedCopy,
}) {
  final String name = sheet.name.trim().isEmpty
      ? (localizedCopy ?? Copy.english).xlsxMappingDefaultName
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

String _ruleCopy(Requiredness rule, {LocalizedCopy? localizedCopy}) {
  return switch (rule) {
    Requiredness.required => (localizedCopy ?? Copy.english).fieldRequired,
    Requiredness.recommended =>
      (localizedCopy ?? Copy.english).fieldRecommended,
    Requiredness.optional => (localizedCopy ?? Copy.english).fieldOptional,
  };
}

/// Must match [AppRoutes.template]. This file cannot import `router.dart`.
