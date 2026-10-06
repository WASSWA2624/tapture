import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/export/export_output_template.dart';
import 'package:tapture/core/export/export_record.dart';
import 'package:tapture/core/export/export_request.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/quality/quality.dart';
import 'package:tapture/features/records/records.dart';
import 'package:tapture/features/templates/templates.dart';

import '../domain/deliverable_repository.dart';

/// Resolves export rows through the same filtered records and template stores
/// used by the app. A changed template never silently retypes an old record.
///
/// A record whose captured shape cannot be resolved (its template was
/// deleted, or its version predates the stored history) is still exported
/// from its own stored values and named in the incomplete list, so one such
/// record never blocks the rest of the export or the project package.
final class ExportRecordLoader {
  /// Uses existing stores rather than duplicating their query and mapping rules.
  const ExportRecordLoader({required this._records, required this._templates});

  final RecordRepository _records;
  final TemplateRepository _templates;

  /// The shared query for count and materialisation.
  static RecordFilter filterFor(ExportScope scope) {
    return switch (scope.kind) {
      ExportScopeKind.approved => RecordFilter.forStatus(RecordStatus.approved),
      ExportScopeKind.all => RecordFilter(
        statuses: RecordStatus.values.toSet()..remove(RecordStatus.deleted),
      ),
      ExportScopeKind.context || ExportScopeKind.filter =>
        RecordFilter.fromJson(scope.filter ?? const <String, Object?>{}),
      ExportScopeKind.dateRange => RecordFilter(
        capturedFrom: DateTime.tryParse(scope.from ?? ''),
        capturedTo: DateTime.tryParse(scope.to ?? ''),
      ),
    };
  }

  /// Count updates follow database changes without loading every field.
  Stream<int> watchCount(ExportRequest request) =>
      _records.watchCount(request.projectId, filterFor(request.scope));

  /// Reads in bounded query pages and retains captured schema and provenance.
  Future<Result<PreparedDeliverable>> load(
    ExportRequest request, {
    required CancellationToken cancel,
  }) async {
    try {
      final List<ExportRecord> output = <ExportRecord>[];
      final List<String> incomplete = <String>[];
      final List<String> omitted = <String>[];
      final Map<String, ExportOutputTemplate> outputTemplates =
          <String, ExportOutputTemplate>{};
      final Map<String, TemplateDef?> templates = <String, TemplateDef?>{};
      final Map<String, Map<int, TemplateDef>> shapes =
          <String, Map<int, TemplateDef>>{};
      final Map<String, Map<String, FieldDef>> definitions =
          <String, Map<String, FieldDef>>{};
      int offset = 0;
      while (true) {
        if (cancel.isCancelled) {
          return const FailureResult<PreparedDeliverable>(CancelledFailure());
        }
        final List<RecordSummary> page = await _records
            .watchPage(
              request.projectId,
              filter: filterFor(request.scope),
              sort: const RecordSort(ascending: true),
              offset: offset,
              limit: _pageSize,
            )
            .first;
        for (final RecordSummary summary in page) {
          if (cancel.isCancelled) {
            return const FailureResult<PreparedDeliverable>(CancelledFailure());
          }
          final Result<RecordEntry?> read = await _records.byId(summary.id);
          if (read case FailureResult<RecordEntry?>(:final Failure failure)) {
            return FailureResult<PreparedDeliverable>(failure);
          }
          final RecordEntry? record = (read as Success<RecordEntry?>).value;
          if (record == null) {
            throw StorageFailure(
              localizedMessage:
                  Copy.messages.failureASelectedRecordIsMissingRefreshThe,
            );
          }
          if (!templates.containsKey(record.templateId)) {
            final Result<TemplateDef?> template = await _templates.byId(
              record.templateId,
            );
            if (template case FailureResult<TemplateDef?>(
              :final Failure failure,
            )) {
              return FailureResult<PreparedDeliverable>(failure);
            }
            // A deleted template is remembered as null, so it is read once.
            templates[record.templateId] =
                (template as Success<TemplateDef?>).value;
            final TemplateDef? loaded = templates[record.templateId];
            final Map<int, TemplateDef> versions = loaded == null
                ? const <int, TemplateDef>{}
                : TemplateVersioning.shapesOf(loaded);
            shapes[record.templateId] = versions;
            definitions[record.templateId] = TemplateVersioning.latestFields(
              versions.values,
            );
          }
          final TemplateDef? current = templates[record.templateId];
          final TemplateDef? captured =
              shapes[record.templateId]![record.templateVersion];
          if (!hasConsent(record, captured ?? current)) {
            omitted.add(record.id);
            continue;
          }
          if (captured == null || _blocks(record, captured)) {
            // Without its captured shape a record cannot be checked, so the
            // operator decides whether it goes out; it never stops the rest.
            incomplete.add(record.id);
          }
          output.add(
            _row(
              record,
              captured ?? _storedShape(record, current),
              definitions[record.templateId]!,
            ),
          );
          final String? sourcePath = captured?.sourceFilePath;
          if (captured != null && sourcePath != null) {
            final String kind = sourcePath.split('.').last.toLowerCase();
            if (const <String>{'xlsx', 'docx', 'txt'}.contains(kind)) {
              final ExportOutputTemplate snapshot = ExportOutputTemplate(
                templateId: captured.id,
                templateVersion: '${captured.version}',
                sourcePath: sourcePath,
                sourceHash: captured.detection['sourceSha256'] as String? ?? '',
                kind: kind,
                sheetName: captured.sheetName,
                headerRow: captured.headerRow ?? 1,
                columns: <String, String>{
                  for (final FieldDef field in captured.fields)
                    if (!field.hidden)
                      if (field.outputColumn case final String column)
                        field.fieldKey: column,
                },
                rows: <String, int>{
                  for (final TemplateRow row in captured.rows)
                    row.id: row.outputRowNumber,
                },
              );
              outputTemplates.putIfAbsent(snapshot.key, () => snapshot);
            }
          }
        }
        if (page.length < _pageSize) {
          break;
        }
        offset += page.length;
      }
      return Success<PreparedDeliverable>((
        request: request.copyWith(
          records: output,
          omittedRecordIds: omitted,
          outputTemplates: outputTemplates.values.toList(),
        ),
        validation: (
          incomplete: incomplete,
          unapproved: <String>[
            for (final ExportRecord record in output)
              if (!record.approved) record.id,
          ],
          blocked: const <String>[],
        ),
      ));
    } on Failure catch (failure) {
      return FailureResult<PreparedDeliverable>(failure);
    } on Object catch (error) {
      return FailureResult<PreparedDeliverable>(Failure.from(error));
    }
  }

  /// Required consent accepts attributable capture or an operator correction.
  static bool hasConsent(RecordEntry record, TemplateDef? shape) {
    for (final FieldDef field in shape?.fields ?? const <FieldDef>[]) {
      if (field.type != FieldType.consent ||
          field.requiredness != Requiredness.required) {
        continue;
      }
      final RecordValue? value = record.values
          .where(
            (RecordValue value) =>
                value.fieldKey == field.fieldKey && !value.retired,
          )
          .firstOrNull;
      if (value == null ||
          ConsentField.authorized(
                raw: value.raw,
                refined: value.refined,
                approved: value.approved,
                source: value.source,
                verified: value.verified,
              ) ==
              null) {
        return false;
      }
    }
    return true;
  }

  /// Whether [record] fails a blocking check of its captured [shape].
  static bool _blocks(RecordEntry record, TemplateDef shape) {
    return RecordRules.blocks(
      RecordRules.validateRecord(
        template: shape,
        values: <String, Object?>{
          for (final RecordValue value in record.values)
            if (!value.retired) value.fieldKey: value.display,
        },
        hasEvidence: record.photos.isNotEmpty || record.audioClips > 0,
      ),
    );
  }

  /// The shape [record]'s own live values imply when its captured version is
  /// gone: one text column per stored field key, labelled as [current] labels
  /// it, so no value is retyped or dropped. A field [current] hides stays out,
  /// as it would from a resolved shape.
  static TemplateDef _storedShape(RecordEntry record, TemplateDef? current) {
    final Map<String, FieldDef> known = <String, FieldDef>{
      for (final FieldDef field in current?.fields ?? const <FieldDef>[])
        field.fieldKey: field,
    };
    final Set<String> keys = <String>{
      for (final RecordValue value in record.values)
        if (!value.retired && known[value.fieldKey]?.hidden != true)
          value.fieldKey,
    };
    return TemplateDef(
      id: record.templateId,
      templateKey: current?.templateKey ?? record.templateId,
      name: current?.name ?? _removedTemplateName,
      version: record.templateVersion,
      fields: <FieldDef>[
        for (final String key in keys)
          FieldDef(
            fieldKey: key,
            label: known[key]?.label ?? key,
            type: FieldType.text,
          ),
      ],
      identityFieldKeys: const <String>[],
      rows: const <TemplateRow>[],
      projectId: record.projectId,
    );
  }

  ExportRecord _row(
    RecordEntry record,
    TemplateDef shape,
    Map<String, FieldDef> historical,
  ) {
    final Map<String, RecordValue> values = <String, RecordValue>{
      for (final RecordValue value in record.values) value.fieldKey: value,
    };
    final Set<String> declared = shape.fields
        .map((field) => field.fieldKey)
        .toSet();
    final List<FieldDef> exportedFields = <FieldDef>[
      for (final FieldDef field in shape.fields)
        if (!field.hidden) field,
      for (final RecordValue value in record.values)
        if (value.retired &&
            !declared.contains(value.fieldKey) &&
            historical[value.fieldKey]?.hidden != true)
          historical[value.fieldKey] ??
              FieldDef(
                fieldKey: value.fieldKey,
                label: value.fieldKey,
                type: FieldType.text,
              ),
    ];
    return ExportRecord(
      id: record.id,
      number: '${record.number ?? record.id}',
      templateId: record.templateId,
      templateName: shape.name,
      templateVersion: '${record.templateVersion}',
      status: record.status.stored,
      approved: record.status == RecordStatus.approved,
      contextPath: record.context.values
          .where((String value) => value.isNotEmpty)
          .join(' / '),
      operatorName: record.capturedBy,
      templateRowId: record.templateRowId,
      capturedAt: record.capturedAt.toUtc().toIso8601String(),
      photoSources: <String, String>{
        for (final RecordPhoto photo in record.photos)
          photo.id: photo.storagePath,
      },
      values: <ExportValue>[
        for (final FieldDef field in exportedFields)
          if (!field.hidden)
            (
              key: field.fieldKey,
              label: field.label,
              type: field.type.name,
              raw: values[field.fieldKey]?.raw,
              refined: values[field.fieldKey]?.refined,
              finalText: values[field.fieldKey]?.display,
              unit: field.unit,
              code: null,
              confidence: values[field.fieldKey]?.confidence,
              evidence: values[field.fieldKey]?.evidenceRemoved == true
                  ? 'Removed'
                  : null,
            ),
      ],
      definitions: <Map<String, Object?>>[
        for (final FieldDef field in exportedFields)
          if (!field.hidden)
            <String, Object?>{
              'key': field.fieldKey,
              'label': field.label,
              'type': field.type.name,
              'unit': field.unit,
              'options': field.options,
              'required': field.requiredness == Requiredness.required,
              'description': field.helpText ?? '',
            },
      ],
      provenance: <String, Object?>{
        for (final RecordValue value in record.values)
          value.fieldKey: <String, Object?>{
            'source': value.source,
            'provider': value.provider,
            'model': value.model,
            'method': value.method,
            'verified': value.verified,
            'retired': value.retired,
          },
      },
      photos: <ExportPhoto>[
        for (final RecordPhoto photo in record.photos)
          (
            id: photo.id,
            recordId: record.id,
            type: photo.photoType,
            caption: photo.caption,
            storedPath: photo.storagePath,
            originalName: photo.storagePath.split('/').last,
            sequence: photo.sortOrder + 1,
          ),
      ],
    );
  }
}

const int _pageSize = 250;

/// Sheet and dictionary name for records whose template no longer exists.
const String _removedTemplateName = 'Removed template';
