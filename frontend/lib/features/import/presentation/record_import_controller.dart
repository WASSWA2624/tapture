import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/export/xlsx_sheet.dart';
import 'package:tapture/core/files/download_service.dart';
import 'package:tapture/core/import/import.dart';
import 'package:tapture/core/validation/validation.dart';
import 'package:tapture/features/quality/quality.dart' show RecordRules;
import 'package:tapture/features/templates/templates.dart'
    show FieldDef, TemplateDef;

import '../domain/import_duplicates.dart';
import '../domain/record_import.dart';
import '../import.dart' show recordImportStoreProvider;

/// A spreadsheet's rows on their way to records (task 020 steps 3 to 5):
/// the template they are matched onto, which column fills which field, the
/// run with its progress, and what it did.
///
/// Mappings start as the header-name suggestion of [RecordImport.suggest]
/// and stay the operator's to change. A run writes nothing until every row
/// is settled, and then everything in one transaction.
final class RecordImportController extends Notifier<RecordImportView> {
  CancellationToken? _token;

  /// The mapping of the last run, which a retry narrows to its failures.
  RecordMapping? _last;

  /// The sheet's headers, for the rows-to-fix file.
  List<String> _headers = const <String>[];

  /// Shows [next] on the mapping and summary pages.
  void present(RecordImportView next) {
    state = next;
  }

  @override
  RecordImportView build() {
    ref.onDispose(() => _token?.cancel());
    return _initial;
  }

  /// Matches the sheet onto [templateId], starting again from the
  /// suggested mapping.
  void useTemplate(String templateId) {
    if (templateId == state.templateId) {
      return;
    }
    state = _next(templateId: templateId, resetMapping: true);
  }

  /// Makes [header] fill [fieldKey], or no field when it is null or empty.
  /// A field fills from one column, so a column that held it lets it go.
  /// [from] is the mapping on screen, suggested or already changed.
  void mapColumn({
    required String header,
    required String? fieldKey,
    required Map<String, String> from,
  }) {
    final Map<String, String> next = Map<String, String>.of(from)
      ..remove(header);
    if (fieldKey != null && fieldKey.isNotEmpty) {
      next.removeWhere((String _, String key) => key == fieldKey);
      next[header] = fieldKey;
    }
    state = _next(columnToField: next);
  }

  /// The rows of [mapping] that match a record already here, for a person
  /// to settle before [run].
  Future<Result<List<ImportMatchRow>>> matches(RecordMapping mapping) async {
    if (state.checking || state.running) {
      return const Success<List<ImportMatchRow>>(<ImportMatchRow>[]);
    }
    final CancellationToken token = CancellationToken();
    _token = token;
    state = _next(checking: true, clearFailure: true);
    final Result<List<ImportMatchRow>> found = await RecordImport(
      ref.read(recordImportStoreProvider),
    ).matches(mapping, token: token);
    if (ref.mounted) {
      state = _next(checking: false);
    }
    return found;
  }

  /// Imports [mapping], whose sheet has [headers], and reports progress in
  /// [RecordImportView.done] until [RecordImportView.result] holds what it
  /// did, or [RecordImportView.failure] why nothing was kept.
  Future<void> run(RecordMapping mapping, {required List<String> headers}) {
    _headers = headers;
    return _run(mapping, earlier: null);
  }

  /// Runs only [rows] of the last import again, through the same mapping
  /// and choices, and adds what they did to the summary. Rows already
  /// written are not run, so none is written twice.
  Future<void> retry(Set<int> rows) {
    final RecordMapping? last = _last;
    if (last == null || rows.isEmpty) {
      return Future<void>.value();
    }
    return _run((
      projectId: last.projectId,
      templateId: last.templateId,
      fields: last.fields,
      identityKeys: last.identityKeys,
      columnToField: last.columnToField,
      rows: last.rows,
      firstDataRow: last.firstDataRow,
      choices: last.choices,
      applyToAll: last.applyToAll,
      onlyRows: rows,
      batchSize: last.batchSize,
    ), earlier: state.result);
  }

  /// Saves the skipped and failed rows as a file to correct and import
  /// again. Succeeds with where the file went, null when the browser chose.
  Future<Result<String?>> exportProblems() async {
    final RecordImportResult? result = state.result;
    if (result == null) {
      return const FailureResult<String?>(CancelledFailure());
    }
    return ref
        .read(downloadServiceProvider)
        .save(
          fileName: Copy.importFixFileName,
          bytes: utf8.encode(
            RecordImport.correctiveList(result, headers: _headers),
          ),
          mimeType: _csvMime,
        );
  }

  /// The mapping [sheet]'s rows need to land on [template] in [projectId]
  /// through [columnToField] (header to field key), with the choices made
  /// for matching rows.
  static RecordMapping mappingOf({
    required String projectId,
    required TemplateDef template,
    required WorkbookSheet sheet,
    required Map<String, String> columnToField,
    Map<int, ImportDuplicateChoice> choices =
        const <int, ImportDuplicateChoice>{},
    ImportDuplicateChoice? applyToAll,
  }) {
    final List<String> headers = headersOf(sheet);
    final int headerRow = sheet.header.rowNumber;
    final List<List<String>> below = sheet.rows.length > headerRow
        ? sheet.rows.sublist(headerRow)
        : const <List<String>>[];
    return (
      projectId: projectId,
      templateId: template.id,
      fields: rulesOf(template),
      identityKeys: template.identityFieldKeys,
      columnToField: columnToField,
      rows: <Map<String, String>>[
        for (final List<String> cells in below)
          <String, String>{
            for (int index = 0; index < headers.length; index++)
              headers[index]: index < cells.length ? cells[index] : '',
          },
      ],
      firstDataRow: headerRow + 1,
      choices: choices,
      applyToAll: applyToAll,
      onlyRows: null,
      batchSize: RecordImport.batchRows,
    );
  }

  /// [sheet]'s column names: each detected header, or its column letter
  /// when blank, with a repeat told apart by its letter.
  static List<String> headersOf(WorkbookSheet sheet) {
    final List<String> labels = sheet.header.labels;
    final Set<String> taken = <String>{};
    return <String>[
      for (int index = 0; index < labels.length; index++)
        _unique(labels[index].trim(), XlsxSheet.columnName(index), taken),
    ];
  }

  /// The rules the validation engine reads for [template]'s visible fields.
  static List<FieldRule> rulesOf(TemplateDef template) {
    return <FieldRule>[
      for (final FieldDef field in template.fields)
        if (!field.hidden)
          RecordRules.ruleOf(
            field,
            identity: template.identityFieldKeys.contains(field.fieldKey),
          ),
    ];
  }

  Future<void> _run(
    RecordMapping mapping, {
    required RecordImportResult? earlier,
  }) async {
    if (state.running || state.checking) {
      return;
    }
    final CancellationToken token = CancellationToken();
    _token = token;
    _last = mapping;
    state = _next(
      running: true,
      done: 0,
      total: 0,
      clearResult: true,
      clearFailure: true,
    );
    RecordImportResult? result;
    try {
      await for (final ImportProgress step in RecordImport(
        ref.read(recordImportStoreProvider),
      ).run(mapping, token: token)) {
        if (!ref.mounted) {
          return;
        }
        result = step.result;
        state = _next(done: step.done, total: step.total);
      }
    } on Failure catch (failure) {
      if (ref.mounted) {
        state = _next(
          running: false,
          failure: failure is CancelledFailure ? null : failure,
        );
      }
      return;
    }
    if (!ref.mounted) {
      return;
    }
    state = _next(running: false, result: _joined(earlier, result));
  }

  RecordImportView _next({
    String? templateId,
    Map<String, String>? columnToField,
    bool resetMapping = false,
    bool? checking,
    bool? running,
    int? done,
    int? total,
    RecordImportResult? result,
    bool clearResult = false,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return (
      templateId: templateId ?? state.templateId,
      columnToField: resetMapping
          ? null
          : (columnToField ?? state.columnToField),
      checking: checking ?? state.checking,
      running: running ?? state.running,
      done: done ?? state.done,
      total: total ?? state.total,
      result: clearResult ? null : (result ?? state.result),
      failure: clearFailure ? null : (failure ?? state.failure),
    );
  }
}

/// The record import in progress: the template chosen (null until one is),
/// the column-to-field mapping once the operator has changed it (null while
/// it is the suggestion), whether matches are being looked up or rows
/// written and how far, and what the last run did or why it stopped.
typedef RecordImportView = ({
  String? templateId,
  Map<String, String>? columnToField,
  bool checking,
  bool running,
  int done,
  int total,
  RecordImportResult? result,
  Failure? failure,
});

/// One record import, from the mapping to the summary. Auto-dispose: it
/// ends when the mapping page closes (FE-STATE-09).
final recordImportControllerProvider =
    NotifierProvider.autoDispose<RecordImportController, RecordImportView>(
      RecordImportController.new,
    );

const RecordImportView _initial = (
  templateId: null,
  columnToField: null,
  checking: false,
  running: false,
  done: 0,
  total: 0,
  result: null,
  failure: null,
);

const String _csvMime = 'text/csv';

/// [earlier]'s written and skipped rows with [later]'s, and [later]'s
/// failures alone: a retry runs only the failed rows.
RecordImportResult? _joined(
  RecordImportResult? earlier,
  RecordImportResult? later,
) {
  if (earlier == null || later == null) {
    return later;
  }
  return (
    created: <ImportedRow>[...earlier.created, ...later.created],
    updated: <ImportedRow>[...earlier.updated, ...later.updated],
    skipped: <RowFailure>[...earlier.skipped, ...later.skipped],
    failures: later.failures,
  );
}

String _unique(String label, String letter, Set<String> taken) {
  final String base = label.isEmpty ? letter : label;
  final String name = taken.contains(base) ? '$base ($letter)' : base;
  taken.add(name);
  return name;
}
