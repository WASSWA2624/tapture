import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/template_capture_origins.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/export/export_record.dart';
import 'package:tapture/core/export/export_request.dart';
import 'package:tapture/core/files/photo_privacy_service.dart';
import 'package:tapture/core/security/coordinate_policy.dart';
import 'package:tapture/features/records/records.dart';
import 'package:tapture/features/templates/templates.dart';

import 'export_record_loader.dart';

/// Resolves current consent and photo protections for every export or replay.
final class ExportPrivacy {
  const ExportPrivacy({
    required this._db,
    required this._records,
    required this._templates,
    required this._photos,
    required this._excludeCoordinates,
    required this._blurFaces,
  });

  final AppDatabase _db;
  final RecordRepository _records;
  final TemplateRepository _templates;
  final PhotoPrivacyService _photos;
  final Future<bool> Function() _excludeCoordinates;
  final Future<bool> Function() _blurFaces;

  Future<ExportRequest> resolve(
    ExportRequest request,
    CancellationToken cancel,
  ) async {
    final bool exclude = await _excludeCoordinates();
    final bool blur = await _blurFaces();
    final List<ExportRecord> output = <ExportRecord>[];
    final Set<String> omitted = request.omittedRecordIds.toSet();
    final Map<String, int> counts = <String, int>{};
    final Map<String, TemplateDef?> templates = <String, TemplateDef?>{};
    final Map<String, Set<String>> currentFields = <String, Set<String>>{};
    final Map<String, Map<int, Set<String>>> fieldHistory =
        <String, Map<int, Set<String>>>{};
    final Map<String, Set<int>> priorVersions =
        await readTemplateCaptureOrigins(
          db: _db,
          projectId: request.projectId,
          recordIds: <String>[
            for (final ExportRecord row in request.records) row.id,
          ],
        );
    for (final ExportRecord row in request.records) {
      if (cancel.isCancelled) throw const CancelledFailure();
      final RecordEntry? live = _unwrap(await _records.byId(row.id));
      if (live == null) {
        throw StorageFailure(
          localizedMessage:
              Copy.messages.failureAnExportedRecordIsNoLongerAvailable,
        );
      }
      if (!templates.containsKey(live.templateId)) {
        templates[live.templateId] = _unwrap(
          await _templates.byId(live.templateId),
        );
        final TemplateDef? template = templates[live.templateId];
        currentFields[live.templateId] = <String>{
          for (final FieldDef field in template?.fields ?? const <FieldDef>[])
            if (CoordinatePolicy.isField(
              key: field.fieldKey,
              type: field.type.name,
              autoFill: field.autoFill?.name,
            ))
              field.fieldKey,
        };
        fieldHistory[live.templateId] =
            CoordinatePolicy.historicalFieldVersions(template?.detection);
        currentFields[live.templateId] = CoordinatePolicy.withRetiredFields(
          current: currentFields[live.templateId]!,
          defined: <String>{
            for (final FieldDef field in template?.fields ?? const <FieldDef>[])
              field.fieldKey,
          },
          history: fieldHistory[live.templateId]!,
        );
      }
      final TemplateDef? current = templates[live.templateId];
      final TemplateDef? shape = current == null
          ? null
          : TemplateVersioning.shapeFor(current, live.templateVersion);
      if (!ExportRecordLoader.hasConsent(live, shape ?? current)) {
        omitted.add(row.id);
        continue;
      }
      final List<Map<String, Object?>> photos = <Map<String, Object?>>[];
      final Map<String, String> sources = <String, String>{};
      for (final ExportPhoto photo in row.photos) {
        final RecordPhoto? currentPhoto = live.photos
            .where((RecordPhoto item) => item.id == photo.id)
            .firstOrNull;
        if (currentPhoto == null) {
          throw StorageFailure(
            localizedMessage:
                Copy.messages.failureAnExportedPhotoIsNoLongerAvailable,
          );
        }
        final PhotoPrivacyCopy safe = _unwrap(
          await _photos.prepare(
            photo.id,
            currentPhoto.storagePath,
            cancel: cancel,
            blurFaces: blur,
            stripLocation: exclude,
          ),
        );
        sources[photo.id] = safe.path;
        if (safe.faceCount case final int count) counts[photo.id] = count;
        photos.add(<String, Object?>{
          'id': photo.id,
          'recordId': photo.recordId,
          'type': photo.type,
          'caption': photo.caption,
          'originalName': photo.originalName,
          'sequence': photo.sequence,
          'storedPath': safe.path,
        });
      }
      final Set<String> locationKeys = <String>{
        for (final ExportValue value in row.values)
          if (CoordinatePolicy.isField(key: value.key, type: value.type))
            value.key,
        if (current != null)
          ...CoordinatePolicy.withMigrationHistory(
            current: CoordinatePolicy.forVersion(
              current: currentFields[live.templateId]!,
              history: fieldHistory[live.templateId]!,
              currentVersion: current.version,
              capturedVersion: live.templateVersion,
            ),
            history: fieldHistory[live.templateId]!,
            currentVersion: current.version,
            previousVersions: priorVersions[live.id] ?? const <int>{},
          ),
      };
      output.add(
        ExportRecord.fromJson(<String, Object?>{
          ...row.toJson(),
          'photos': photos,
          'photoSources': sources,
          if (exclude)
            'contextPath': live.context.entries
                .where(
                  (MapEntry<String, String> item) =>
                      !locationKeys.contains(item.key) &&
                      !CoordinatePolicy.isKey(item.key),
                )
                .map((MapEntry<String, String> item) => item.value)
                .where((String value) => value.trim().isNotEmpty)
                .join(' / '),
          if (exclude)
            'values': <Object?>[
              for (final Object? value
                  in row.toJson()['values']! as List<Object?>)
                if (value is Map && !locationKeys.contains(value['key'])) value,
            ],
          if (exclude)
            'definitions': row.definitions
                .where(
                  (Map<String, Object?> field) =>
                      !locationKeys.contains(field['key']),
                )
                .toList(),
          if (exclude)
            'provenance': <String, Object?>{
              for (final MapEntry<String, Object?> field
                  in row.provenance.entries)
                if (!locationKeys.contains(field.key)) field.key: field.value,
            },
        }),
      );
    }
    return request.copyWith(
      records: output,
      omittedRecordIds: omitted.toList(),
      photoFaceCounts: counts,
      privacyFingerprint: await fingerprint(request.projectId),
    );
  }

  /// Removes coordinate-bearing scope metadata from the delivered manifest.
  /// The private local request retains the exact replay filter.
  Future<ExportRequest> publicSnapshot(ExportRequest request) async {
    if (!await _excludeCoordinates()) return request;
    final List<QueryRow> shapes = await _db
        .customSelect(
          'SELECT tf.template_id, tf.field_key, tf.type, tf.validation FROM template_fields tf '
          'WHERE EXISTS (SELECT 1 FROM records r WHERE r.project_id = ? '
          'AND r.template_id = tf.template_id) AND NOT EXISTS '
          "(SELECT 1 FROM tombstones d WHERE d.entity_type = 'template_fields' AND d.entity_id = tf.id)",
          variables: <Variable<Object>>[Variable<String>(request.projectId)],
        )
        .get();
    final Map<String, Set<String>> current = <String, Set<String>>{};
    final Map<String, Set<String>> defined = <String, Set<String>>{};
    for (final QueryRow row in shapes) {
      (defined[row.read<String>('template_id')] ??= <String>{}).add(
        row.read<String>('field_key'),
      );
      if (CoordinatePolicy.isField(
        key: row.read<String>('field_key'),
        type: row.read<String>('type'),
        validation: row.read<String?>('validation'),
      )) {
        (current[row.read<String>('template_id')] ??= <String>{}).add(
          row.read<String>('field_key'),
        );
      }
    }
    final List<QueryRow> templates = await _db
        .customSelect(
          'SELECT DISTINCT t.id, t.version, t.detection, r.template_version '
          'FROM templates t JOIN records r ON r.template_id = t.id '
          'WHERE r.project_id = ?',
          variables: <Variable<Object>>[Variable<String>(request.projectId)],
        )
        .get();
    final Map<String, Set<int>> origins = await readTemplateCaptureOrigins(
      db: _db,
      projectId: request.projectId,
      recordIds: <String>[
        for (final ExportRecord row in request.records) row.id,
      ],
    );
    final Map<String, Set<int>> templateOrigins = <String, Set<int>>{};
    for (final ExportRecord row in request.records) {
      (templateOrigins[row.templateId] ??= <int>{}).addAll(
        origins[row.id] ?? const <int>{},
      );
    }
    final Set<String> keys = <String>{
      for (final Set<String> fields in current.values) ...fields,
      for (final QueryRow row in templates)
        ...CoordinatePolicy.withMigrationHistory(
          current: CoordinatePolicy.forVersion(
            current: CoordinatePolicy.withRetiredFields(
              current: current[row.read<String>('id')] ?? const <String>{},
              defined: defined[row.read<String>('id')] ?? const <String>{},
              history: CoordinatePolicy.historicalFieldVersions(
                row.read<String>('detection'),
              ),
            ),
            history: CoordinatePolicy.historicalFieldVersions(
              row.read<String>('detection'),
            ),
            currentVersion: row.read<int>('version'),
            capturedVersion: row.read<int>('template_version'),
          ),
          history: CoordinatePolicy.historicalFieldVersions(
            row.read<String>('detection'),
          ),
          currentVersion: row.read<int>('version'),
          previousVersions:
              templateOrigins[row.read<String>('id')] ?? const <int>{},
        ),
    };
    final Map<String, Object?>? filter = request.scope.filter;
    return request.copyWith(
      scope: (
        kind: request.scope.kind,
        context: null,
        from: request.scope.from,
        to: request.scope.to,
        filter: filter == null
            ? null
            : _privateCoordinates(filter, keys) as Map<String, Object?>,
      ),
    );
  }

  /// An append-only privacy change or consent edit invalidates old artifacts.
  Future<String> fingerprint(String projectId) async {
    final List<QueryRow> rows = await _db
        .customSelect(
          'SELECT id, entity_id, previous_value, new_value, at, rev, rowid FROM audit_log WHERE '
          "(field_key = 'privacy' AND entity_id IN "
          '(SELECT id FROM photos WHERE project_id = ?)) OR '
          "(field_key IN ('location', 'template_version') AND ("
          "(entity_type = 'records' AND entity_id IN (SELECT id FROM records WHERE project_id = ?)) OR "
          "(entity_type = 'record_fields' AND entity_id IN (SELECT f.id FROM record_fields f JOIN records r ON r.id = f.record_id WHERE r.project_id = ?)) OR "
          "(entity_type = 'photos' AND entity_id IN (SELECT id FROM photos WHERE project_id = ?)))) "
          'ORDER BY rowid',
          variables: <Variable<Object>>[
            for (int index = 0; index < 4; index++) Variable<String>(projectId),
          ],
        )
        .get();
    final List<QueryRow> consent = await _db
        .customSelect(
          'SELECT rf.id, rf.value_raw, rf.value_refined, rf.value_final, '
          'rf.source, rf.verified, tf.required FROM record_fields rf '
          'JOIN records r ON r.id = rf.record_id JOIN template_fields tf '
          'ON tf.template_id = r.template_id AND tf.field_key = rf.field_key '
          "WHERE r.project_id = ? AND tf.type = 'consent' ORDER BY rf.id",
          variables: <Variable<Object>>[Variable<String>(projectId)],
        )
        .get();
    final List<QueryRow> coordinateFields = await _db
        .customSelect(
          'SELECT tf.template_id, tf.field_key, tf.type, tf.validation '
          'FROM template_fields tf WHERE EXISTS (SELECT 1 FROM records r '
          'WHERE r.project_id = ? AND r.template_id = tf.template_id) '
          'ORDER BY tf.template_id, tf.field_key',
          variables: <Variable<Object>>[Variable<String>(projectId)],
        )
        .get();
    final List<QueryRow> photoState = await _db
        .customSelect(
          'SELECT id, record_id, sha256, relative_path, derived_from, gps_lat, gps_lon '
          'FROM photos WHERE project_id = ? ORDER BY id',
          variables: <Variable<Object>>[Variable<String>(projectId)],
        )
        .get();
    final List<QueryRow> templateState = await _db
        .customSelect(
          'SELECT t.id, t.version, t.detection FROM templates t WHERE EXISTS '
          '(SELECT 1 FROM records r WHERE r.project_id = ? AND r.template_id = t.id) '
          'ORDER BY t.id',
          variables: <Variable<Object>>[Variable<String>(projectId)],
        )
        .get();
    return sha256
        .convert(
          utf8.encode(
            jsonEncode(<Object?>[
              await _excludeCoordinates(),
              await _blurFaces(),
              rows.map((QueryRow row) => row.data).toList(),
              consent.map((QueryRow row) => row.data).toList(),
              coordinateFields.map((QueryRow row) => row.data).toList(),
              templateState.map((QueryRow row) => row.data).toList(),
              photoState.map((QueryRow row) => row.data).toList(),
            ]),
          ),
        )
        .toString();
  }
}

T _unwrap<T>(Result<T> result) => result.getOrThrow();

Object? _privateCoordinates(Object? value, Set<String> keys) {
  if (value is List) {
    return value
        .map((Object? item) => _privateCoordinates(item, keys))
        .toList();
  }
  if (value is! Map) return value;
  return <String, Object?>{
    for (final MapEntry<Object?, Object?> entry in value.entries)
      if (entry.key is String &&
          !keys.contains(entry.key) &&
          !CoordinatePolicy.isKey(entry.key! as String))
        entry.key! as String: _privateCoordinates(entry.value, keys),
  };
}
