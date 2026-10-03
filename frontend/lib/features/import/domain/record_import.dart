import 'dart:async';

import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/copy/domain_copy.g.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/export/csv_writer.dart';
import 'package:tapture/core/validation/validation.dart';
import 'package:tapture/features/quality/domain/domain.dart'
    show identityHash, normaliseIdentity;

import 'import_duplicates.dart';
import 'record_import_store.dart';

/// Turns mapped spreadsheet rows into records (task 020).
///
/// Each row is validated through the engine of 110 · Data quality on a
/// worker isolate, and a row that fails is kept aside with its number and
/// reason while the valid rows still import. A row matches a record already
/// here when their identity hashes agree, the same hash 110's duplicate
/// detection compares; this class declares only what an import does with a
/// match ([ImportDuplicateChoice]). Every write of a run goes to the
/// [RecordImportStore] in one transaction, with progress per batch, and
/// every record it creates carries source [importedSource].
final class RecordImport {
  /// Creates the runner over [_store].
  const RecordImport(this._store);

  final RecordImportStore _store;

  /// Source written on every record this import creates.
  static const String importedSource = 'IMPORTED_TABLE';

  /// Rows written between two progress reports.
  static const int batchRows = 500;

  /// Suggests a field for each header whose text matches a field's key or
  /// label, ignoring case and surrounding space. Each field is suggested
  /// for one header at most, the first that matches.
  static Map<String, String> suggest({
    required List<String> headers,
    required List<FieldRule> fields,
  }) {
    final Map<String, String> mapping = <String, String>{};
    final Set<String> taken = <String>{};
    for (final String header in headers) {
      final String folded = header.trim().toLowerCase();
      if (folded.isEmpty) {
        continue;
      }
      for (final FieldRule field in fields) {
        if (taken.contains(field.fieldKey)) {
          continue;
        }
        if (folded == field.fieldKey.toLowerCase() ||
            folded == field.label.trim().toLowerCase()) {
          mapping[header] = field.fieldKey;
          taken.add(field.fieldKey);
          break;
        }
      }
    }
    return mapping;
  }

  /// Labels of the identity fields [columnToField] leaves without a column.
  static List<String> missingIdentity({
    required List<FieldRule> fields,
    required Map<String, String> columnToField,
  }) {
    final Set<String> mapped = columnToField.values.toSet();
    return <String>[
      for (final FieldRule field in fields)
        if (field.identity && !mapped.contains(field.fieldKey)) field.label,
    ];
  }

  /// The rows of [mapping] that match a record already here and have no
  /// choice yet, so a person can settle each one before [run].
  Future<Result<List<ImportMatchRow>>> matches(
    RecordMapping mapping, {
    required CancellationToken token,
  }) async {
    final Result<_Settled> settled = await _settle(mapping, token);
    return settled.map((_Settled value) => value.asks);
  }

  /// Imports [mapping], reporting progress after each batch. The last event
  /// holds the whole result. A storage failure or a cancel through [token]
  /// ends the stream with that [Failure] as its error, and nothing of the
  /// run is kept.
  Stream<ImportProgress> run(
    RecordMapping mapping, {
    required CancellationToken token,
  }) {
    final StreamController<ImportProgress> out =
        StreamController<ImportProgress>();
    unawaited(_run(mapping, token, out));
    return out.stream;
  }

  /// The skipped and failed rows of [result] as a CSV to correct and import
  /// again: each row's number and reason, then its cells under [headers].
  static String correctiveList(
    RecordImportResult result, {
    required List<String> headers,
  }) {
    final List<RowFailure> rows = <RowFailure>[
      ...result.failures,
      ...result.skipped,
    ]..sort((RowFailure a, RowFailure b) => a.row.compareTo(b.row));
    return CsvWriter.table(
      <String>[
        DomainCopy.importFixRowColumn,
        DomainCopy.importFixReasonColumn,
        ...headers,
      ],
      <List<String>>[
        for (final RowFailure row in rows)
          <String>[
            '${row.row}',
            row.reason,
            for (final String header in headers) row.values[header] ?? '',
          ],
      ],
      delimiter: ',',
    );
  }

  Future<void> _run(
    RecordMapping mapping,
    CancellationToken token,
    StreamController<ImportProgress> out,
  ) async {
    try {
      final _Settled settled;
      switch (await _settle(mapping, token)) {
        case FailureResult<_Settled>(:final Failure failure):
          out.addError(failure);
          return;
        case Success<_Settled>(:final _Settled value):
          settled = value;
      }
      final int settledAside = settled.failures.length + settled.skipped.length;
      final int total = settledAside + settled.writes.length;
      ImportProgress progress(int written, {bool finished = false}) {
        return (
          done: settledAside + written,
          total: total,
          result: (
            created: finished ? settled.created : const <ImportedRow>[],
            updated: finished ? settled.updated : const <ImportedRow>[],
            skipped: settled.skipped,
            failures: settled.failures,
          ),
        );
      }

      out.add(progress(0));
      final Result<void> written = await _store.write(
        projectId: mapping.projectId,
        templateId: mapping.templateId,
        rows: settled.writes,
        batchSize: mapping.batchSize,
        onBatch: (int count) => out.add(progress(count)),
        token: token,
      );
      if (written case FailureResult<void>(:final Failure failure)) {
        out.addError(failure);
        return;
      }
      out.add(progress(settled.writes.length, finished: true));
    } finally {
      await out.close();
    }
  }

  /// Validates and hashes the rows off the UI thread, then settles each
  /// valid one against the records already here. A sheet shorter than one
  /// batch is planned in place: starting a worker would cost more than the
  /// work (FE-PERF-02 moves heavy work, not every loop).
  Future<Result<_Settled>> _settle(
    RecordMapping mapping,
    CancellationToken token,
  ) async {
    final _PlanInput input = (
      fields: mapping.fields,
      identityKeys: mapping.identityKeys,
      columnToField: mapping.columnToField,
      rows: mapping.rows,
      firstDataRow: mapping.firstDataRow,
      onlyRows: mapping.onlyRows,
    );
    final Result<_Plan> planned = mapping.rows.length < batchRows
        ? Result.capture(() => _planRows(input))
        : await runIsolate(_planRows, input, cancel: token);
    if (token.isCancelled) {
      return const FailureResult<_Settled>(CancelledFailure());
    }
    final _Plan plan;
    switch (planned) {
      case FailureResult<_Plan>(:final Failure failure):
        return FailureResult<_Settled>(failure);
      case Success<_Plan>(:final _Plan value):
        plan = value;
    }
    final Map<String, String> known;
    switch (await _store.identities(
      projectId: mapping.projectId,
      templateId: mapping.templateId,
    )) {
      case FailureResult<Map<String, String>>(:final Failure failure):
        return FailureResult<_Settled>(failure);
      case Success<Map<String, String>>(:final Map<String, String> value):
        known = value;
    }
    final _Settled settled = (
      writes: <ImportWrite>[],
      created: <ImportedRow>[],
      updated: <ImportedRow>[],
      skipped: <RowFailure>[],
      failures: plan.failures,
      asks: <ImportMatchRow>[],
    );
    for (final _PlannedRow row in plan.valid) {
      final String? existing = row.identity.isEmpty
          ? null
          : known[row.identity];
      final ImportMatch match = ImportDuplicates.apply(
        matched: existing != null,
        choice: mapping.choices[row.row],
        applyToAll: mapping.applyToAll,
      );
      switch (match) {
        case ImportMatch.create || ImportMatch.replace || ImportMatch.merge:
          settled.writes.add((
            row: row.row,
            match: match,
            existingId: existing,
            values: row.values,
          ));
          final ImportedRow written = (
            row: row.row,
            source: importedSource,
            values: row.values,
            existingId: existing,
          );
          (match == ImportMatch.create ? settled.created : settled.updated).add(
            written,
          );
        case ImportMatch.keep:
          settled.skipped.add((
            row: row.row,
            reason: DomainCopy.importKeptExisting,
            values: row.cells,
          ));
        case ImportMatch.ask:
          settled.asks.add((
            row: row.row,
            existingId: existing!,
            values: row.values,
          ));
          settled.skipped.add((
            row: row.row,
            reason: DomainCopy.importMatchUnsettled,
            values: row.cells,
          ));
      }
    }
    return Success<_Settled>(settled);
  }
}

/// One mapped import: the rows of a sheet ([rows], keyed by header, the
/// first of them spreadsheet row [firstDataRow]), where each goes
/// ([columnToField], header to field key) on template [templateId] of
/// [projectId], that template's [fields] and [identityKeys], the choice
/// per matching row number ([choices]) or for every match ([applyToAll]),
/// and when set the only row numbers to run ([onlyRows], for a retry).
typedef RecordMapping = ({
  String projectId,
  String templateId,
  List<FieldRule> fields,
  List<String> identityKeys,
  Map<String, String> columnToField,
  List<Map<String, String>> rows,
  int firstDataRow,
  Map<int, ImportDuplicateChoice> choices,
  ImportDuplicateChoice? applyToAll,
  Set<int>? onlyRows,
  int batchSize,
});

/// A row that was written: created, or onto [existingId].
typedef ImportedRow = ({
  int row,
  String source,
  Map<String, String> values,
  String? existingId,
});

/// A row that was not written, with the reason and its cells by header.
typedef RowFailure = ({int row, String reason, Map<String, String> values});

/// A row that matches record [existingId] and waits on a person's choice.
typedef ImportMatchRow = ({
  int row,
  String existingId,
  Map<String, String> values,
});

/// What an import did, row by row.
typedef RecordImportResult = ({
  List<ImportedRow> created,
  List<ImportedRow> updated,
  List<RowFailure> skipped,
  List<RowFailure> failures,
});

/// Progress through one import: rows settled of [total], and the result so
/// far. Created and updated rows appear once the transaction has committed.
typedef ImportProgress = ({int done, int total, RecordImportResult result});

/// What the worker isolate is handed.
typedef _PlanInput = ({
  List<FieldRule> fields,
  List<String> identityKeys,
  Map<String, String> columnToField,
  List<Map<String, String>> rows,
  int firstDataRow,
  Set<int>? onlyRows,
});

/// A valid row: its field [values], its original [cells] and its identity
/// hash, empty when it names no identity.
typedef _PlannedRow = ({
  int row,
  Map<String, String> values,
  Map<String, String> cells,
  String identity,
});

typedef _Plan = ({List<_PlannedRow> valid, List<RowFailure> failures});

typedef _Settled = ({
  List<ImportWrite> writes,
  List<ImportedRow> created,
  List<ImportedRow> updated,
  List<RowFailure> skipped,
  List<RowFailure> failures,
  List<ImportMatchRow> asks,
});

/// Isolate entry: validates, maps and hashes every row of [input].
_Plan _planRows(_PlanInput input) {
  final List<_PlannedRow> valid = <_PlannedRow>[];
  final List<RowFailure> failures = <RowFailure>[];
  final Map<String, int> seen = <String, int>{};
  final int total = input.rows.length;
  for (int index = 0; index < total; index++) {
    final int rowNumber = input.firstDataRow + index;
    final Set<int>? only = input.onlyRows;
    if (only != null && !only.contains(rowNumber)) {
      continue;
    }
    final Map<String, String> cells = input.rows[index];
    final Map<String, String> values = <String, String>{
      for (final MapEntry<String, String> entry in input.columnToField.entries)
        entry.value: (cells[entry.key] ?? '').trim(),
    };
    if (values.values.every((String value) => value.isEmpty)) {
      continue;
    }
    final ValidationIssue? block = validationEngine
        .validateRecord(
          fields: input.fields,
          values: values,
          // Evidence is asked for at approval; an imported row has none yet.
          hasEvidence: true,
        )
        .where((ValidationIssue issue) => issue.blocks)
        .firstOrNull;
    if (block != null) {
      failures.add((row: rowNumber, reason: block.message, values: cells));
      continue;
    }
    final bool named = input.identityKeys.any(
      (String key) => normaliseIdentity(values[key] ?? '').isNotEmpty,
    );
    final String identity = named
        ? identityHash(values, input.identityKeys)
        : '';
    final int? first = identity.isEmpty ? null : seen[identity];
    if (first != null) {
      failures.add((
        row: rowNumber,
        reason: DomainCopy.importRepeatsRow(first),
        values: cells,
      ));
      continue;
    }
    if (identity.isNotEmpty) {
      seen[identity] = rowNumber;
    }
    valid.add((
      row: rowNumber,
      values: values,
      cells: cells,
      identity: identity,
    ));
    if ((index + 1) % RecordImport.batchRows == 0) {
      IsolateRunner.reportProgress((index + 1) / total);
    }
  }
  return (valid: valid, failures: failures);
}
