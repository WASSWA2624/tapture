import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/picked_document.dart';
import 'package:tapture/core/import/import.dart';
import 'package:tapture/core/validation/validation.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/projects/projects.dart'
    show currentProjectProvider;
import 'package:tapture/features/templates/templates.dart' show TemplateDef;

import '../domain/import_duplicates.dart';
import '../domain/record_import.dart';
import 'import_controller.dart';
import 'import_match_sheet.dart';
import 'import_providers.dart';
import 'record_import_controller.dart';

/// Matches a workbook's columns onto one of the open project's templates
/// (task 020 step 3), with the workbook reader, header detection and type
/// inference of 009 reading the sheet.
///
/// Each column starts at the field whose key or label its header names and
/// stays the operator's to change. Import is refused, naming the field,
/// while an identity field has no column, and the first rows are shown as
/// they will be read. Import settles every row that matches a record here
/// on the match sheet, then runs and opens the summary.
final class RecordMappingScreen extends ConsumerWidget {
  /// Creates the mapping for the spreadsheet the import page holds.
  const RecordMappingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final String? projectId = ref.watch(currentProjectProvider);
    return AppPage(
      key: const ValueKey<String>('route-import-records'),
      title: localCopy.importMappingTitle,
      scrollable: false,
      body: AsyncValueView<WorkbookSheet?>(
        value: ref.watch(importSheetProvider),
        isEmpty: (WorkbookSheet? sheet) =>
            sheet == null || sheet.header.labels.isEmpty || projectId == null,
        empty: () => AppEmptyState(
          icon: AppIcons.columns,
          headline: Copy.of(context).importNoSheetHeadline,
          message: Copy.of(context).importNoSheetMessage,
          actionLabel: Copy.of(context).importChooseFile,
          onAction: () => context.go(RoutePaths.projectImport),
        ),
        onRetry: () => ref.invalidate(importSheetProvider),
        data: (WorkbookSheet? sheet) => AsyncValueView<List<TemplateDef>>(
          value: ref.watch(importTemplatesProvider(projectId!)),
          isEmpty: (List<TemplateDef> templates) => templates.isEmpty,
          empty: () => AppEmptyState(
            icon: AppIcons.template,
            headline: Copy.of(context).importNoTemplateHeadline,
            message: Copy.of(context).importNoTemplateMessage,
            actionLabel: Copy.of(context).importMakeTemplate,
            onAction: () => _makeTemplate(context, ref, projectId),
          ),
          onRetry: () => ref.invalidate(importTemplatesProvider(projectId)),
          data: (List<TemplateDef> templates) => _Mapping(
            projectId: projectId,
            sheet: sheet!,
            templates: templates,
          ),
        ),
      ),
    );
  }
}

class _Mapping extends ConsumerWidget {
  const _Mapping({
    required this.projectId,
    required this.sheet,
    required this.templates,
  });

  final String projectId;
  final WorkbookSheet sheet;
  final List<TemplateDef> templates;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final RecordImportView view = ref.watch(recordImportControllerProvider);
    final RecordImportController controller = ref.read(
      recordImportControllerProvider.notifier,
    );
    final TemplateDef template = templates.firstWhere(
      (TemplateDef candidate) => candidate.id == view.templateId,
      orElse: () => templates.first,
    );
    final List<String> headers = RecordImportController.headersOf(sheet);
    final List<FieldRule> rules = RecordImportController.rulesOf(template);
    final Map<String, String> mapping =
        view.columnToField ??
        RecordImport.suggest(headers: headers, fields: rules);
    final List<String> missing = RecordImport.missingIdentity(
      fields: rules,
      columnToField: mapping,
    );
    final RecordMapping planned = RecordImportController.mappingOf(
      projectId: projectId,
      template: template,
      sheet: sheet,
      columnToField: mapping,
    );
    final List<Choice<String>> fieldChoices = <Choice<String>>[
      Choice<String>('', localCopy.importUnmapped),
      for (final FieldRule rule in rules)
        Choice<String>(rule.fieldKey, rule.label),
    ];
    return AppForm(
      submitLabel: localCopy.importRun(planned.rows.length),
      errors: <String>[
        if (missing.isNotEmpty) localCopy.importIdentityMissing(missing.first),
      ],
      onSubmit: () async {
        if (missing.isNotEmpty) {
          return false;
        }
        await _start(context, ref, planned, headers);
        return true;
      },
      fields: <Widget>[
        AppChoiceField<String>(
          key: const ValueKey<String>('import-template'),
          label: localCopy.importMappingTemplate,
          value: template.id,
          alwaysSheet: true,
          options: <Choice<String>>[
            for (final TemplateDef candidate in templates)
              Choice<String>(candidate.id, candidate.name),
          ],
          onChanged: (String? id) {
            if (id != null) {
              controller.useTemplate(id);
            }
          },
        ),
        AppSectionHeader(title: localCopy.importMappingColumns),
        for (final String header in headers)
          AppChoiceField<String>(
            key: ValueKey<String>('import-map-$header'),
            label: header,
            value: mapping[header] ?? '',
            alwaysSheet: true,
            options: fieldChoices,
            onChanged: (String? fieldKey) => controller.mapColumn(
              header: header,
              fieldKey: fieldKey,
              from: mapping,
            ),
          ),
        AppSectionHeader(title: localCopy.importPreviewTitle),
        for (
          int index = 0;
          index < planned.rows.length && index < _previewRows;
          index++
        )
          _PreviewRow(
            row: planned.firstDataRow + index,
            cells: planned.rows[index],
            mapping: mapping,
            rules: rules,
          ),
      ],
    );
  }
}

/// One row of the sheet as the import will read it: each field it fills,
/// under the field's label.
class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.row,
    required this.cells,
    required this.mapping,
    required this.rules,
  });

  final int row;
  final Map<String, String> cells;
  final Map<String, String> mapping;
  final List<FieldRule> rules;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final Map<String, String> byField = <String, String>{
      for (final MapEntry<String, String> entry in mapping.entries)
        entry.value: (cells[entry.key] ?? '').trim(),
    };
    return Column(
      key: ValueKey<String>('import-preview-$row'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(title: localCopy.importRow(row), dense: true),
        for (final FieldRule rule in rules)
          if (byField.containsKey(rule.fieldKey))
            AppListTile(
              dense: true,
              title: rule.label,
              subtitle: byField[rule.fieldKey]!.isEmpty
                  ? null
                  : byField[rule.fieldKey],
            ),
      ],
    );
  }
}

/// Settles every row that matches a record here, one sheet per match until
/// a choice covers the rest, then starts the run and opens the summary. A
/// dismissed sheet stops here, with nothing written.
Future<void> _start(
  BuildContext context,
  WidgetRef ref,
  RecordMapping mapping,
  List<String> headers,
) async {
  final RecordImportController controller = ref.read(
    recordImportControllerProvider.notifier,
  );
  final Result<List<ImportMatchRow>> found = await controller.matches(mapping);
  if (!context.mounted) {
    return;
  }
  final List<ImportMatchRow> matches;
  switch (found) {
    case FailureResult<List<ImportMatchRow>>(:final Failure failure):
      showAppSnack(
        context,
        failure.message,
        tone: SnackTone.error,
        localizedMessage: failure.explanation,
      );
      return;
    case Success<List<ImportMatchRow>>(:final List<ImportMatchRow> value):
      matches = value;
  }
  final Map<int, ImportDuplicateChoice> choices =
      <int, ImportDuplicateChoice>{};
  ImportDuplicateChoice? applyToAll;
  for (final ImportMatchRow match in matches) {
    final ImportMatchDecision? decision = await showImportMatchSheet(
      context,
      row: match.row,
    );
    if (decision == null || !context.mounted) {
      return;
    }
    if (decision.applyToAll) {
      applyToAll = decision.choice;
      break;
    }
    choices[match.row] = decision.choice;
  }
  unawaited(
    controller.run((
      projectId: mapping.projectId,
      templateId: mapping.templateId,
      fields: mapping.fields,
      identityKeys: mapping.identityKeys,
      columnToField: mapping.columnToField,
      rows: mapping.rows,
      firstDataRow: mapping.firstDataRow,
      choices: choices,
      applyToAll: applyToAll,
      onlyRows: null,
      batchSize: mapping.batchSize,
    ), headers: headers),
  );
  unawaited(context.push(RoutePaths.projectImportSummary));
}

/// A project with no template: make one from this sheet's columns with the
/// mapping screen of 009 when the sheet is a file here, else start a new
/// template.
void _makeTemplate(BuildContext context, WidgetRef ref, String projectId) {
  final PickedDocument? document = ref.read(importControllerProvider).document;
  if (document case PickedFile(:final file)) {
    unawaited(
      context.push(
        RoutePaths.templateXlsx(projectId: projectId),
        extra: file.path,
      ),
    );
    return;
  }
  unawaited(context.push(RoutePaths.templateCreate(projectId: projectId)));
}

/// How many rows the preview shows.
const int _previewRows = 3;
