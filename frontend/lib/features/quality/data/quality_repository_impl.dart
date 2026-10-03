import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/record_schema.dart';
import 'package:tapture/core/db/tables/duplicates.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/records/records.dart'
    show RecordEntry, RecordPhoto, RecordRepositoryImpl, RecordValue;
import 'package:tapture/features/templates/templates.dart'
    show FieldDef, TemplateDef, TemplateRepository, TemplateVersioning;

import '../domain/duplicate_candidate.dart';
import '../domain/duplicate_choice.dart';
import '../domain/duplicate_link.dart';
import '../domain/duplicate_override.dart';
import '../domain/duplicate_pair_view.dart';
import '../domain/duplicate_resolution.dart';
import '../domain/duplicate_side.dart';
import '../domain/duplicate_signal.dart';
import '../domain/field_variance.dart';
import '../domain/quality_counts.dart';
import '../domain/quality_repository.dart';
import '../domain/record_rules.dart';
import '../domain/record_variance.dart';
import '../domain/uncaptured_rows.dart';
import 'drift_duplicate_detection.dart';
import 'drift_duplicate_ledger.dart';
import 'variance_writer.dart';

/// The Drift quality store (task 015).
///
/// Records are read and changed through [RecordRepositoryImpl] over the same
/// database, so a resolution's value edits keep history exactly as a hand
/// edit does and a discarded record goes to the recycle bin like any other.
final class QualityRepositoryImpl implements QualityRepository {
  /// Opens the store against [db]. Writes are stamped with [clock] and
  /// [deviceId], new rows take ids from [ids], templates come from
  /// `templates`, and [operatorName], when given, names the person on
  /// every resolution in place of the device profile's operator.
  QualityRepositoryImpl({
    required AppDatabase db,
    required Clock clock,
    required String deviceId,
    required IdService ids,
    required this._templates,
    String Function()? operatorName,
  }) : _db = db,
       _clock = clock,
       _deviceId = deviceId,
       _ids = ids,
       _operatorName = operatorName,
       _records = RecordRepositoryImpl(
         db: db,
         clock: clock,
         deviceId: deviceId,
         ids: ids,
         operatorName: operatorName,
       ),
       _detection = DriftDuplicateDetection(db);

  final AppDatabase _db;
  final Clock _clock;
  final String _deviceId;
  final IdService _ids;
  final TemplateRepository _templates;
  final String Function()? _operatorName;
  final RecordRepositoryImpl _records;
  final DriftDuplicateDetection _detection;

  @override
  Stream<List<DuplicatePairView>> watchUnresolvedPairs(String projectId) {
    return _db
        .customSelect(
          '$_pairColumns WHERE d.project_id = ? AND d.status = ? '
          '$_bothLive ORDER BY d.created_at, d.id',
          variables: <Variable<Object>>[
            Variable<String>(projectId),
            Variable<String>(DuplicatePairStatus.unresolved.name),
          ],
          readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
            _db.duplicates,
            _db.records,
            _db.recordFields,
            _db.photos,
            _db.tombstones,
          },
        )
        .watch()
        .asyncMap((List<QueryRow> rows) async {
          final Map<String, TemplateDef?> templates = <String, TemplateDef?>{};
          final List<DuplicatePairView> views = <DuplicatePairView>[];
          for (final QueryRow row in rows) {
            final DuplicatePairView? view = await _view(row, templates);
            if (view != null) {
              views.add(view);
            }
          }
          return views;
        });
  }

  @override
  Future<Result<DuplicatePairView?>> pair(String pairId) async {
    try {
      final QueryRow? row = await _db
          .customSelect(
            '$_pairColumns WHERE d.id = ? AND d.status = ? $_bothLive',
            variables: <Variable<Object>>[
              Variable<String>(pairId),
              Variable<String>(DuplicatePairStatus.unresolved.name),
            ],
          )
          .getSingleOrNull();
      if (row == null) {
        return const Success<DuplicatePairView?>(null);
      }
      return Success<DuplicatePairView?>(
        await _view(row, <String, TemplateDef?>{}),
      );
    } on Failure catch (readFailure) {
      return FailureResult<DuplicatePairView?>(readFailure);
    } on Object catch (error) {
      return FailureResult<DuplicatePairView?>(storageFailureFrom(error));
    }
  }

  @override
  Stream<List<DuplicateCounterpart>> watchCounterparts(String recordId) {
    return _db
        .customSelect(
          'SELECT d.id AS pair_id, d.status AS status, o.id AS other_id, '
          'o.record_number AS number, '
          "COALESCE(sd.sort_name, '') AS name FROM duplicates d "
          'JOIN records o ON o.id = CASE WHEN d.left_record_id = ? '
          'THEN d.right_record_id ELSE d.left_record_id END '
          'LEFT JOIN ${RecordSchema.searchDocsTable} sd '
          'ON sd.record_id = o.id '
          'WHERE (d.left_record_id = ? OR d.right_record_id = ?) '
          'AND (d.status = ? OR d.resolution = ?) AND o.status <> ? '
          'ORDER BY d.created_at, d.id',
          variables: <Variable<Object>>[
            Variable<String>(recordId),
            Variable<String>(recordId),
            Variable<String>(recordId),
            Variable<String>(DuplicatePairStatus.unresolved.name),
            Variable<String>(DuplicateChoice.keepBoth.name),
            Variable<String>(RecordStatus.deleted.stored),
          ],
          readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
            _db.duplicates,
            _db.records,
          },
        )
        .watch()
        .map(
          (List<QueryRow> rows) => <DuplicateCounterpart>[
            for (final QueryRow row in rows)
              (
                pairId: row.read<String>('pair_id'),
                recordId: row.read<String>('other_id'),
                name: row.read<String>('name'),
                number: row.read<int?>('number'),
                resolved:
                    row.read<String>('status') !=
                    DuplicatePairStatus.unresolved.name,
              ),
          ],
        );
  }

  @override
  Future<Result<int>> scanRecords(List<String> recordIds) async {
    try {
      var added = 0;
      for (final String id in recordIds) {
        final RecordEntry? entry = await _entry(id);
        if (entry == null || entry.isDeleted) {
          continue;
        }
        final List<DuplicateCandidate> candidates = await _detection
            .candidatesFor(entry);
        for (final DuplicateCandidate candidate in candidates) {
          final ({String left, String right}) ordered = DuplicateLink.pair(
            id,
            candidate.recordId,
          );
          final QueryRow? known = await _db
              .customSelect(
                'SELECT 1 AS found FROM duplicates WHERE left_record_id = ? '
                'AND right_record_id = ?',
                variables: <Variable<Object>>[
                  Variable<String>(ordered.left),
                  Variable<String>(ordered.right),
                ],
              )
              .getSingleOrNull();
          final DateTime now = _clock.nowUtc();
          final Result<DuplicatePair> stored = await upsertDetectedDuplicate(
            _db,
            row: DuplicatesCompanion.insert(
              projectId: entry.projectId,
              leftRecordId: ordered.left,
              rightRecordId: ordered.right,
              signal: _strongest(candidate.signals).name,
              score: candidate.score,
              status: DuplicatePairStatus.unresolved,
              createdAt: now,
              updatedAt: now,
              updatedByDevice: _deviceId,
            ),
            clock: _clock,
            deviceId: _deviceId,
            ids: _ids,
          );
          if (stored case FailureResult<DuplicatePair>(
            failure: final Failure storeFailure,
          )) {
            return FailureResult<int>(storeFailure);
          }
          if (known == null) {
            added += 1;
          }
        }
      }
      return Success<int>(added);
    } on Failure catch (scanFailure) {
      return FailureResult<int>(scanFailure);
    } on Object catch (error) {
      return FailureResult<int>(storageFailureFrom(error));
    }
  }

  @override
  Future<Result<int>> scanProject(String projectId) async {
    try {
      final List<QueryRow> rows = await _db
          .customSelect(
            'SELECT id FROM records WHERE project_id = ? AND status <> ? '
            'ORDER BY captured_at, id',
            variables: <Variable<Object>>[
              Variable<String>(projectId),
              Variable<String>(RecordStatus.deleted.stored),
            ],
          )
          .get();
      return scanRecords(<String>[
        for (final QueryRow row in rows) row.read<String>('id'),
      ]);
    } on Object catch (error) {
      return FailureResult<int>(storageFailureFrom(error));
    }
  }

  @override
  Future<Result<void>> resolve(
    String pairId,
    DuplicateResolution resolution,
  ) async {
    Failure? refusal;
    final String person = await _person();
    final Result<void> written = await runInTransaction<void>(_db, () async {
      final QueryRow? row = await _db
          .customSelect(
            '$_pairColumns WHERE d.id = ? AND d.status = ? $_bothLive',
            variables: <Variable<Object>>[
              Variable<String>(pairId),
              Variable<String>(DuplicatePairStatus.unresolved.name),
            ],
          )
          .getSingleOrNull();
      final DuplicatePairView? view = row == null
          ? null
          : await _view(row, <String, TemplateDef?>{});
      if (view == null) {
        refusal = _pairGoneFailure;
        throw _pairGoneFailure;
      }
      final String existing = view.existing.recordId;
      final String incoming = view.incoming.recordId;
      final DriftDuplicateLedger ledger = DriftDuplicateLedger(
        targetRecordId: existing,
        sourceRecordId: incoming,
      );
      switch (resolution.choice) {
        case DuplicateChoice.keepBoth:
          DuplicateLink.keepBoth(
            ledger: ledger,
            a: existing,
            b: incoming,
            person: person,
          );
        case DuplicateChoice.discardNew:
          ledger.addAudit(
            action: _discardAction,
            leftId: existing,
            rightId: incoming,
            person: person,
            detail: _discardAction,
          );
        case DuplicateChoice.overrideExisting:
          DuplicateOverride.apply(
            ledger: ledger,
            leftId: existing,
            rightId: incoming,
            person: person,
            previous: <String, String>{
              for (final DuplicateDifference difference in view.differences)
                difference.fieldKey: difference.existing,
            },
            next: <String, String>{
              for (final DuplicateDifference difference in view.differences)
                if (difference.incoming.isNotEmpty)
                  difference.fieldKey: difference.incoming,
            },
            photoHashes: <String>[
              for (final RecordPhoto photo in view.incoming.photos)
                photo.sha256,
            ],
          );
        case DuplicateChoice.mergeFields:
          _merge(ledger, view, resolution, person);
      }
      await ledger.commit(
        db: _db,
        records: _records,
        projectId: view.projectId,
        clock: _clock,
        deviceId: _deviceId,
        ids: _ids,
      );
      final String? binReason = switch (resolution.choice) {
        DuplicateChoice.keepBoth => null,
        DuplicateChoice.discardNew => Copy.duplicateDiscardedReason,
        DuplicateChoice.overrideExisting => Copy.duplicateOverriddenReason,
        DuplicateChoice.mergeFields => Copy.duplicateMergedReason,
      };
      if (binReason != null) {
        final Result<void> binned = await _moveToBin(
          incoming,
          reason: binReason,
        );
        if (binned case FailureResult<void>(
          failure: final Failure binFailure,
        )) {
          refusal = binFailure;
          throw binFailure;
        }
      }
      final Result<DuplicatePair> settled = await resolveDuplicate(
        _db,
        id: pairId,
        resolution: resolution.choice.name,
        resolvedBy: person,
        clock: _clock,
        deviceId: _deviceId,
        ids: _ids,
      );
      if (settled case FailureResult<DuplicatePair>(
        failure: final Failure settleFailure,
      )) {
        refusal = settleFailure;
        throw settleFailure;
      }
    });
    final Failure? refused = refusal;
    if (refused != null) {
      return FailureResult<void>(refused);
    }
    return written;
  }

  @override
  Stream<List<RecordVariance>> watchVariances(String projectId) {
    return _db
        .customSelect(
          'SELECT v.id AS id, v.record_id AS record_id, '
          'v.field_key AS field_key, v.register_value AS recorded, '
          'v.found_value AS found, v.status AS status, '
          'r.record_number AS number, r.context_json AS context_json, '
          "COALESCE(sd.sort_name, '') AS name, "
          'COALESCE((SELECT tf.label FROM template_fields tf WHERE '
          'tf.template_id = r.template_id AND tf.field_key = v.field_key '
          'LIMIT 1), v.field_key) AS label '
          'FROM variances v JOIN records r ON r.id = v.record_id '
          'LEFT JOIN ${RecordSchema.searchDocsTable} sd '
          'ON sd.record_id = r.id '
          'WHERE v.project_id = ? AND r.status <> ? '
          "AND NOT EXISTS (SELECT 1 FROM tombstones t WHERE t.entity_type = "
          "'variances' AND t.entity_id = v.id) "
          'ORDER BY r.record_number, r.id, v.rowid',
          variables: <Variable<Object>>[
            Variable<String>(projectId),
            Variable<String>(RecordStatus.deleted.stored),
          ],
          readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
            _db.variances,
            _db.records,
            _db.tombstones,
          },
        )
        .watch()
        .map(
          (List<QueryRow> rows) => <RecordVariance>[
            for (final QueryRow row in rows)
              RecordVariance(
                id: row.read<String>('id'),
                recordId: row.read<String>('record_id'),
                recordName: row.read<String>('name'),
                recordNumber: row.read<int?>('number'),
                fieldKey: row.read<String>('field_key'),
                label: row.read<String>('label'),
                context: _deepest(row.read<String>('context_json')),
                recorded: row.read<String?>('recorded') ?? '',
                found: row.read<String?>('found') ?? '',
                status: _varianceStatus(row.read<String>('status')),
              ),
          ],
        );
  }

  @override
  Future<Result<UncapturedRows>> missingItems(String projectId) async {
    try {
      // Register rows: every row of a dataset this project's records were
      // captured against, and the rows those records name.
      final List<QueryRow> register = await _db
          .customSelect(
            'SELECT rr.id AS id, rr.key_value AS label FROM reference_rows rr '
            'WHERE rr.dataset_id IN (SELECT DISTINCT ur.dataset_id FROM '
            'reference_rows ur JOIN record_fields uf ON uf.method = '
            "'${VarianceWriter.registerMethod}' || ur.id "
            'JOIN records ux ON ux.id = uf.record_id '
            'WHERE ux.project_id = ? AND ux.status <> ?) '
            "AND NOT EXISTS (SELECT 1 FROM tombstones t WHERE t.entity_type = "
            "'reference_rows' AND t.entity_id = rr.id) "
            'ORDER BY rr.key_value, rr.id',
            variables: <Variable<Object>>[
              Variable<String>(projectId),
              Variable<String>(RecordStatus.deleted.stored),
            ],
          )
          .get();
      final List<QueryRow> captured = await _db
          .customSelect(
            'SELECT DISTINCT substr(f.method, ?) AS id FROM record_fields f '
            'JOIN records x ON x.id = f.record_id WHERE f.method LIKE ? '
            'AND x.project_id = ? AND x.status <> ?',
            variables: <Variable<Object>>[
              const Variable<int>(VarianceWriter.registerMethod.length + 1),
              const Variable<String>('${VarianceWriter.registerMethod}%'),
              Variable<String>(projectId),
              Variable<String>(RecordStatus.deleted.stored),
            ],
          )
          .get();
      // Checklist rows of the project's templates, and the rows its records
      // were captured from.
      final List<QueryRow> checklist = await _db
          .customSelect(
            'SELECT tr.id AS id, tr.label AS label FROM template_rows tr '
            'JOIN templates t ON t.id = tr.template_id '
            'WHERE (t.project_id = ? OR t.id IN (SELECT template_id FROM '
            'records WHERE project_id = ?)) '
            "AND NOT EXISTS (SELECT 1 FROM tombstones tt WHERE "
            "tt.entity_type = 'templates' AND tt.entity_id = t.id) "
            "AND NOT EXISTS (SELECT 1 FROM tombstones rt WHERE "
            "rt.entity_type = 'template_rows' AND rt.entity_id = tr.id) "
            'ORDER BY t.name, tr.output_row_number, tr.id',
            variables: <Variable<Object>>[
              Variable<String>(projectId),
              Variable<String>(projectId),
            ],
          )
          .get();
      final List<QueryRow> visited = await _db
          .customSelect(
            'SELECT DISTINCT template_row_id AS id FROM records '
            'WHERE project_id = ? AND status <> ? '
            'AND template_row_id IS NOT NULL',
            variables: <Variable<Object>>[
              Variable<String>(projectId),
              Variable<String>(RecordStatus.deleted.stored),
            ],
          )
          .get();
      final Map<String, String> labels = <String, String>{
        for (final QueryRow row in <QueryRow>[...register, ...checklist])
          row.read<String>('id'): row.read<String>('label'),
      };
      final UncapturedRows missing = UncapturedRows.compute(
        registerIds: <String>[
          for (final QueryRow row in register) row.read<String>('id'),
        ],
        capturedRegisterIds: <String>{
          for (final QueryRow row in captured) row.read<String>('id'),
        },
        checklistIds: <String>[
          for (final QueryRow row in checklist) row.read<String>('id'),
        ],
        capturedChecklistIds: <String>{
          for (final QueryRow row in visited) row.read<String>('id'),
        },
      );
      return Success<UncapturedRows>(
        UncapturedRows(
          <String>[
            for (final String id in missing.registerNotFound) labels[id] ?? id,
          ],
          <String>[
            for (final String id in missing.checklistNotCaptured)
              labels[id] ?? id,
          ],
        ),
      );
    } on Object catch (error) {
      return FailureResult<UncapturedRows>(storageFailureFrom(error));
    }
  }

  @override
  Stream<QualityCounts> watchCounts(String projectId) {
    return _db
        .customSelect(
          'SELECT COUNT(*) AS n FROM records WHERE project_id = ?',
          variables: <Variable<Object>>[Variable<String>(projectId)],
          readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
            _db.records,
            _db.recordFields,
            _db.photos,
            _db.duplicates,
            _db.mergeConflicts,
            _db.templates,
            _db.templateFields,
            _db.tombstones,
          },
        )
        .watch()
        .asyncMap((List<QueryRow> _) => _counts(projectId));
  }

  // --------------------------------------------------------------- plumbing

  /// The four counts of [projectId], read once.
  Future<QualityCounts> _counts(String projectId) async {
    final List<QueryRow> live = await _db
        .customSelect(
          'SELECT r.id AS id, r.template_id AS template_id, '
          'r.template_version AS template_version, r.status AS status '
          'FROM records r WHERE r.project_id = ? AND r.status NOT IN (?, ?)',
          variables: <Variable<Object>>[
            Variable<String>(projectId),
            Variable<String>(RecordStatus.deleted.stored),
            Variable<String>(RecordStatus.archived.stored),
          ],
        )
        .get();
    final Map<String, Map<String, Object?>> values = await _valuesOf(projectId);
    final Set<String> evidenced = await _evidenced(projectId);
    final Map<String, TemplateDef?> templates = <String, TemplateDef?>{};
    var invalid = 0;
    var unreviewed = 0;
    for (final QueryRow row in live) {
      final String id = row.read<String>('id');
      if (row.read<String>('status') != RecordStatus.approved.stored) {
        unreviewed += 1;
      }
      final TemplateDef? current = await _template(
        row.read<String>('template_id'),
        templates,
      );
      final TemplateDef? shape = current == null
          ? null
          : TemplateVersioning.shapeFor(
              current,
              row.read<int>('template_version'),
            );
      if (shape == null ||
          RecordRules.blocks(
            RecordRules.validateRecord(
              template: shape,
              values: values[id] ?? const <String, Object?>{},
              hasEvidence: evidenced.contains(id),
            ),
          )) {
        invalid += 1;
      }
    }
    final QueryRow pairs = await _db
        .customSelect(
          'SELECT COUNT(*) AS n FROM duplicates d '
          'WHERE d.project_id = ? AND d.status = ? $_bothLive',
          variables: <Variable<Object>>[
            Variable<String>(projectId),
            Variable<String>(DuplicatePairStatus.unresolved.name),
          ],
        )
        .getSingle();
    final QueryRow conflicts = await _db
        .customSelect(
          'SELECT COUNT(*) AS n FROM records r WHERE r.project_id = ? '
          'AND r.status NOT IN (?, ?) AND (r.id IN (SELECT mc.entity_id '
          'FROM merge_conflicts mc WHERE mc.resolution IS NULL AND '
          "mc.entity_type = 'records') OR r.id IN (SELECT mf.record_id "
          'FROM merge_conflicts mc JOIN record_fields mf ON '
          'mf.id = mc.entity_id WHERE mc.resolution IS NULL AND '
          "mc.entity_type = 'record_fields') OR r.id IN (SELECT "
          'mp.record_id FROM merge_conflicts mc JOIN photos mp ON '
          'mp.id = mc.entity_id WHERE mc.resolution IS NULL AND '
          "mc.entity_type = 'photos'))",
          variables: <Variable<Object>>[
            Variable<String>(projectId),
            Variable<String>(RecordStatus.deleted.stored),
            Variable<String>(RecordStatus.archived.stored),
          ],
        )
        .getSingle();
    return (
      invalid: invalid,
      duplicates: pairs.read<int>('n'),
      conflicts: conflicts.read<int>('n'),
      unreviewed: unreviewed,
    );
  }

  /// Every live value of [projectId]'s records, record to field to the
  /// value it displays.
  Future<Map<String, Map<String, Object?>>> _valuesOf(String projectId) async {
    final List<QueryRow> rows = await _db
        .customSelect(
          'SELECT f.record_id AS record_id, f.field_key AS field_key, '
          'COALESCE(f.value_final, f.value_refined, f.value_raw) AS value '
          'FROM record_fields f JOIN records r ON r.id = f.record_id '
          'WHERE r.project_id = ? AND f.retired_at IS NULL '
          "AND NOT EXISTS (SELECT 1 FROM tombstones t WHERE t.entity_type = "
          "'record_fields' AND t.entity_id = f.id)",
          variables: <Variable<Object>>[Variable<String>(projectId)],
        )
        .get();
    final Map<String, Map<String, Object?>> byRecord =
        <String, Map<String, Object?>>{};
    for (final QueryRow row in rows) {
      byRecord.putIfAbsent(
        row.read<String>('record_id'),
        () => <String, Object?>{},
      )[row.read<String>('field_key')] = row.read<String?>(
        'value',
      );
    }
    return byRecord;
  }

  /// Records of [projectId] holding a live photo or an audio clip.
  Future<Set<String>> _evidenced(String projectId) async {
    final List<QueryRow> rows = await _db
        .customSelect(
          'SELECT DISTINCT p.record_id AS record_id FROM photos p '
          'WHERE p.project_id = ? AND p.record_id IS NOT NULL '
          "AND NOT EXISTS (SELECT 1 FROM tombstones t WHERE t.entity_type = "
          "'photos' AND t.entity_id = p.id) "
          'UNION SELECT o.owner_id FROM attachment_owners o '
          'JOIN attachments a ON a.id = o.attachment_id '
          'JOIN records r ON r.id = o.owner_id '
          "WHERE o.owner_type = 'record' AND a.kind = 'audio' "
          'AND r.project_id = ?',
          variables: <Variable<Object>>[
            Variable<String>(projectId),
            Variable<String>(projectId),
          ],
        )
        .get();
    return <String>{
      for (final QueryRow row in rows) row.read<String>('record_id'),
    };
  }

  /// The pair [row] read whole, or null when either record is gone.
  Future<DuplicatePairView?> _view(
    QueryRow row,
    Map<String, TemplateDef?> templates,
  ) async {
    final RecordEntry? left = await _entry(row.read<String>('left_record_id'));
    final RecordEntry? right = await _entry(
      row.read<String>('right_record_id'),
    );
    if (left == null || right == null || left.isDeleted || right.isDeleted) {
      return null;
    }
    final bool leftFirst = !left.capturedAt.isAfter(right.capturedAt);
    final RecordEntry existing = leftFirst ? left : right;
    final RecordEntry incoming = leftFirst ? right : left;
    final TemplateDef? template = await _template(
      incoming.templateId,
      templates,
    );
    return DuplicatePairView(
      id: row.read<String>('id'),
      projectId: row.read<String>('project_id'),
      signal: _signal(row.read<String>('signal')),
      score: row.read<double>('score'),
      templateId: incoming.templateId,
      templateName: template?.name ?? '',
      existing: await _side(existing),
      incoming: await _side(incoming),
      differences: _differences(existing, incoming, template),
    );
  }

  /// [entry] as one side of a pair.
  Future<DuplicateSide> _side(RecordEntry entry) async {
    final QueryRow? created = await _db
        .customSelect(
          'SELECT operator FROM audit_log WHERE entity_type = ? '
          "AND entity_id = ? AND action = 'created' AND field_key IS NULL "
          'ORDER BY at, rowid LIMIT 1',
          variables: <Variable<Object>>[
            const Variable<String>(_recordsEntity),
            Variable<String>(entry.id),
          ],
        )
        .getSingleOrNull();
    final String operator = created?.read<String>('operator').trim() ?? '';
    return DuplicateSide(
      recordId: entry.id,
      name: entry.name,
      number: entry.number,
      capturedAt: entry.capturedAt,
      capturedBy: operator.isEmpty ? entry.capturedBy : operator,
      contextLabel: entry.contextLabel,
      photos: entry.photos,
    );
  }

  /// Fields whose displayed values differ, in [template]'s order, then any
  /// the template does not declare. Values filled automatically (dates,
  /// the operator, the record number) differ between any two captures and
  /// are left out.
  List<DuplicateDifference> _differences(
    RecordEntry existing,
    RecordEntry incoming,
    TemplateDef? template,
  ) {
    final Map<String, String> before = _shown(existing);
    final Map<String, String> after = _shown(incoming);
    final Map<String, String> labels = <String, String>{
      for (final FieldDef field in template?.fields ?? const <FieldDef>[])
        if (!field.hidden) field.fieldKey: field.label,
    };
    final List<String> keys = <String>[
      ...labels.keys,
      for (final String key in <String>{...before.keys, ...after.keys})
        if (!labels.containsKey(key)) key,
    ];
    return <DuplicateDifference>[
      for (final String key in keys)
        if ((before.containsKey(key) || after.containsKey(key)) &&
            (before[key] ?? '') != (after[key] ?? ''))
          (
            fieldKey: key,
            label: labels[key] ?? key,
            existing: before[key] ?? '',
            incoming: after[key] ?? '',
          ),
    ];
  }

  /// The merge's writes: each picked field, the photos when carried, and
  /// the audit row.
  void _merge(
    DriftDuplicateLedger ledger,
    DuplicatePairView view,
    DuplicateResolution resolution,
    String person,
  ) {
    for (final DuplicateDifference difference in view.differences) {
      final MergePick pick =
          resolution.picks[difference.fieldKey] ?? MergePick.theirs;
      final String? next = switch (pick) {
        MergePick.theirs => null,
        MergePick.mine => difference.incoming,
        MergePick.both => Copy.duplicateBothValues(
          difference.existing,
          difference.incoming,
        ),
      };
      if (next == null || next == difference.existing) {
        continue;
      }
      ledger.replaceValue(
        fieldKey: difference.fieldKey,
        previous: difference.existing,
        next: next,
      );
    }
    if (resolution.carryPhotos) {
      for (final RecordPhoto photo in view.incoming.photos) {
        ledger.attachPhoto(photo.sha256);
      }
    }
    ledger.addAudit(
      action: _mergeAction,
      leftId: view.existing.recordId,
      rightId: view.incoming.recordId,
      person: person,
      detail: _mergeAction,
    );
  }

  /// Moves record [id] to the recycle bin through the record store: a
  /// tombstone and status deleted, restorable, never a row delete.
  Future<Result<void>> Function(String id, {required String reason})
  get _moveToBin => _records.delete;

  /// Record [id] read whole, or null when it is not on this device. A read
  /// failure throws so the caller's result carries it.
  Future<RecordEntry?> _entry(String id) async {
    final Result<RecordEntry?> read = await _records.byId(id);
    return switch (read) {
      Success<RecordEntry?>(:final RecordEntry? value) => value,
      FailureResult<RecordEntry?>(failure: final Failure readFailure) =>
        throw readFailure,
    };
  }

  /// Template [id] from [cache], read once per call.
  Future<TemplateDef?> _template(
    String id,
    Map<String, TemplateDef?> cache,
  ) async {
    if (cache.containsKey(id)) {
      return cache[id];
    }
    final Result<TemplateDef?> read = await _templates.byId(id);
    final TemplateDef? template = switch (read) {
      Success<TemplateDef?>(:final TemplateDef? value) => value,
      FailureResult<TemplateDef?>() => null,
    };
    cache[id] = template;
    return template;
  }

  /// The person a resolution names: [_operatorName] when given, else the
  /// device profile's operator, else this device.
  Future<String> _person() async {
    final String Function()? named = _operatorName;
    String name;
    if (named != null) {
      name = named();
    } else {
      final QueryRow? profile = await _db
          .customSelect('SELECT operator_name FROM device_profile LIMIT 1')
          .getSingleOrNull();
      name = profile?.read<String?>('operator_name') ?? '';
    }
    name = name.trim();
    return name.isEmpty ? _deviceId : name;
  }
}

/// Stands in until `main` supplies the Drift store: no pairs, no variances,
/// nothing to count, and every write refused. Tests override it with a fake
/// or an in-memory store.
final class _EmptyQualityRepository implements QualityRepository {
  const _EmptyQualityRepository();

  @override
  Stream<List<DuplicatePairView>> watchUnresolvedPairs(String projectId) =>
      Stream<List<DuplicatePairView>>.value(const <DuplicatePairView>[]);

  @override
  Future<Result<DuplicatePairView?>> pair(String pairId) async =>
      const Success<DuplicatePairView?>(null);

  @override
  Stream<List<DuplicateCounterpart>> watchCounterparts(String recordId) =>
      Stream<List<DuplicateCounterpart>>.value(const <DuplicateCounterpart>[]);

  @override
  Future<Result<int>> scanRecords(List<String> recordIds) async =>
      const Success<int>(0);

  @override
  Future<Result<int>> scanProject(String projectId) async =>
      const Success<int>(0);

  @override
  Future<Result<void>> resolve(
    String pairId,
    DuplicateResolution resolution,
  ) async => FailureResult<void>(_pairGoneFailure);

  @override
  Stream<List<RecordVariance>> watchVariances(String projectId) =>
      Stream<List<RecordVariance>>.value(const <RecordVariance>[]);

  @override
  Future<Result<UncapturedRows>> missingItems(String projectId) async =>
      const Success<UncapturedRows>(UncapturedRows(<String>[], <String>[]));

  @override
  Stream<QualityCounts> watchCounts(String projectId) =>
      Stream<QualityCounts>.value((
        invalid: 0,
        duplicates: 0,
        conflicts: 0,
        unreviewed: 0,
      ));
}

/// The quality store. `main` overrides it with [QualityRepositoryImpl] over
/// the open database; tests override it with a fake or an in-memory store.
final Provider<QualityRepository> qualityRepositoryProvider =
    Provider<QualityRepository>((Ref _) {
      return const _EmptyQualityRepository();
    });

/// The pair row every pair read starts from, on `duplicates d`.
const String _pairColumns =
    'SELECT d.id AS id, d.project_id AS project_id, '
    'd.left_record_id AS left_record_id, '
    'd.right_record_id AS right_record_id, d.signal AS signal, '
    'd.score AS score FROM duplicates d';

/// Keeps pairs whose two records are both live.
const String _bothLive =
    'AND NOT EXISTS (SELECT 1 FROM records gone WHERE gone.id IN '
    "(d.left_record_id, d.right_record_id) AND gone.status = 'deleted') "
    'AND EXISTS (SELECT 1 FROM records l WHERE l.id = d.left_record_id) '
    'AND EXISTS (SELECT 1 FROM records r WHERE r.id = d.right_record_id)';

const String _recordsEntity = 'records';

const String _discardAction = 'discard';

const String _mergeAction = 'merge';

final StorageFailure _pairGoneFailure = StorageFailure(
  localizedMessage: Copy.messages.duplicatePairGone,
  localizedRecovery: Copy.messages.duplicatePairGoneRecovery,
);

/// What [entry] displays per live field, trimmed, leaving out values filled
/// automatically at capture.
Map<String, String> _shown(RecordEntry entry) {
  return <String, String>{
    for (final RecordValue value in entry.liveValues)
      if (value.source.toUpperCase() != _autoSource)
        value.fieldKey: value.display.trim(),
  };
}

const String _autoSource = 'AUTO';

/// The signal the stored pair names, or identity for one this app does not
/// know.
DuplicateSignal _signal(String stored) {
  for (final DuplicateSignal signal in DuplicateSignal.values) {
    if (signal.name == stored) {
      return signal;
    }
  }
  return DuplicateSignal.identity;
}

/// The strongest of [signals], the one a pair is filed under.
DuplicateSignal _strongest(Set<DuplicateSignal> signals) {
  for (final DuplicateSignal signal in _strength) {
    if (signals.contains(signal)) {
      return signal;
    }
  }
  return signals.first;
}

const List<DuplicateSignal> _strength = <DuplicateSignal>[
  DuplicateSignal.identity,
  DuplicateSignal.samePhoto,
  DuplicateSignal.photo,
  DuplicateSignal.nearPhoto,
  DuplicateSignal.predefinedRow,
  DuplicateSignal.nameContextTime,
  DuplicateSignal.caption,
];

VarianceStatus _varianceStatus(String stored) {
  for (final VarianceStatus status in VarianceStatus.values) {
    if (status.name == stored) {
      return status;
    }
  }
  return VarianceStatus.changed;
}

/// The deepest non-empty value of the context snapshot [json].
String _deepest(String json) {
  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException {
    return '';
  }
  if (decoded is! Map<String, Object?>) {
    return '';
  }
  String label = '';
  for (final Object? value in decoded.values) {
    final String text = '${value ?? ''}'.trim();
    if (text.isNotEmpty) {
      label = text;
    }
  }
  return label;
}
