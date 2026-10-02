import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/db/app_database.dart' show kSchemaVersion;
import 'package:tapture/core/device/device_identity.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/ids/ids.dart';
import 'package:tapture/core/time/clock.dart';

import 'bundle_format.dart';
import 'bundle_manifest.dart';
import 'bundle_output.dart';
import 'bundle_privacy.dart';
import 'bundle_redaction.dart';
import 'bundle_tables.dart';
import 'bundle_zip_job.dart';
import 'bundle_zip_stub.dart'
    if (dart.library.io) 'bundle_zip_io.dart'
    if (dart.library.js_interop) 'bundle_zip_web.dart'
    as platform;
import 'bundle_zip_web.dart' as browser;
import 'template_key.dart';

/// Writes a project package: every table and file another Tapture app
/// needs to open the project (specification §45, task 076). On a device the
/// package streams to the project's `exports/` folder; in a browser it is
/// built in memory under a smaller ceiling (D6). Nothing secret is read:
/// no device profile preference, setting or key (FE-SEC-01, FE-SEC-02).
abstract interface class BundleWriter {
  /// Creates the writer over [db] and the files under [storageRoot].
  /// [device] is the test seam for the app version.
  factory BundleWriter({
    required GeneratedDatabase db,
    required StorageRoot storageRoot,
    required FileReader files,
    required Clock clock,
    required IdService ids,
    required String deviceId,
    Future<DeviceDescriptor> Function()? device,
    bool? inBrowser,
  }) = _BundleWriter;

  /// The largest package this platform writes.
  int get ceiling;

  /// Bytes the package of [projectId] is expected to take: the file sizes
  /// its rows record, plus its tables.
  Future<Result<int>> estimate(String projectId, {BundlePrivacy? privacy});

  /// Writes the package of [projectId], adding [extras] (such as the
  /// workbook) as entries. A package estimated above [ceiling] is refused
  /// before anything is written; a cancel or a failure leaves no file.
  Future<Result<BundleOutput>> write({
    required String projectId,
    required CancellationToken cancel,
    void Function(double)? onProgress,
    Map<String, List<int>> extras,
    BundlePrivacy? privacy,
    String? password,
  });
}

final class _BundleWriter implements BundleWriter {
  _BundleWriter({
    required this._db,
    required this._storageRoot,
    required this._files,
    required this._clock,
    required this._ids,
    required this._deviceId,
    Future<DeviceDescriptor> Function()? device,
    bool? inBrowser,
  }) : _device = device ?? deviceDescriptor,
       _inBrowser = inBrowser ?? kIsWeb;

  final GeneratedDatabase _db;
  final StorageRoot _storageRoot;
  final FileReader _files;
  final Clock _clock;
  final IdService _ids;
  final String _deviceId;
  final Future<DeviceDescriptor> Function() _device;
  final bool _inBrowser;

  @override
  int get ceiling => _inBrowser
      ? AppConstants.imports.bundleMaxBytes
      : AppConstants.bundles.nativeMaxBytes;

  @override
  Future<Result<int>> estimate(String projectId, {BundlePrivacy? privacy}) {
    return Result.captureAsync(() async {
      final BundleTables original = await _read(projectId);
      final BundleTables tables = privacy?.apply(original) ?? original;
      final Result<Map<String, List<int>>> encoded = await _encode(tables);
      return tables.recordedFileBytes + _size(_unwrap(encoded));
    });
  }

  @override
  Future<Result<BundleOutput>> write({
    required String projectId,
    required CancellationToken cancel,
    void Function(double)? onProgress,
    Map<String, List<int>> extras = const <String, List<int>>{},
    BundlePrivacy? privacy,
    String? password,
  }) async {
    try {
      if (cancel.isCancelled) {
        return const FailureResult<BundleOutput>(CancelledFailure());
      }
      final Result<({BundleTables tables, Map<String, List<int>> entries})>
      prepared = await Result.captureAsync(() async {
        final BundleTables original = await _read(projectId);
        final BundleTables tables = privacy?.apply(original) ?? original;
        final Map<String, List<int>> json = _unwrap(await _encode(tables));
        return (
          tables: tables,
          entries: <String, List<int>>{...json, ...extras},
        );
      });
      if (prepared case FailureResult<
        ({BundleTables tables, Map<String, List<int>> entries})
      >(
        :final Failure failure,
      )) {
        return FailureResult<BundleOutput>(failure);
      }
      final ({BundleTables tables, Map<String, List<int>> entries}) ready =
          (prepared
                  as Success<
                    ({BundleTables tables, Map<String, List<int>> entries})
                  >)
              .value;
      final int expected =
          ready.tables.recordedFileBytes + _size(ready.entries);
      if (ready.entries.entries
              .where(
                (MapEntry<String, List<int>> entry) =>
                    BundleFormat.isMetadataEntry(entry.key),
              )
              .fold<int>(
                0,
                (int size, MapEntry<String, List<int>> entry) =>
                    size + entry.value.length,
              ) >
          AppConstants.bundles.metadataMaxBytes) {
        return FailureResult<BundleOutput>(
          ValidationFailure(
            localizedMessage:
                Copy.messages.failureTheProjectMetadataIsTooLargeFor,
            localizedRecovery: Copy.messages.failureChooseASmallerPackageScope,
          ),
        );
      }
      if (expected > ceiling) {
        return FailureResult<BundleOutput>(
          StorageFailure(
            localizedMessage: Copy.messages.packageTooLarge(expected, ceiling),
            localizedRecovery: Copy.messages.packageTooLargeRecovery,
          ),
        );
      }
      final String bundleId = _ids.newId();
      final BundleManifest manifest = await _manifest(
        ready.tables,
        bundleId: bundleId,
        projectId: projectId,
      );
      final BundleZipJob job = BundleZipJob(
        storageRoot: _storageRoot,
        files: _files,
        folderName: ready.tables.folderName,
        targetPath:
            'projects/${ready.tables.folderName}/exports/$bundleId.'
            '${BundleFormat.extension}',
        entries: ready.entries,
        projectFiles: ready.tables.filePaths,
        fileSources: privacy?.fileSources ?? const <String, String>{},
        manifest: manifest,
        ceiling: ceiling,
        cancel: cancel,
        onProgress: onProgress,
        password: password,
        patternsYaml: await BundleRedaction.loadPatterns(),
      );
      return await (_inBrowser
          ? browser.zipBundle(job)
          : platform.zipBundle(job));
    } on Object catch (error) {
      return FailureResult<BundleOutput>(Failure.from(error));
    }
  }

  Future<BundleTables> _read(String projectId) async {
    final BundleTables? tables = await BundleTables.read(_db, projectId);
    if (tables == null) {
      throw StorageFailure(
        localizedMessage: Copy.messages.packageProjectMissing,
        localizedRecovery: Copy.messages.tryAgain,
      );
    }
    return tables;
  }

  /// Encodes the tables off the UI thread (FE-PERF-02).
  Future<Result<Map<String, List<int>>>> _encode(BundleTables tables) {
    return runIsolate<
      Map<String, List<Map<String, Object?>>>,
      Map<String, List<int>>
    >(_encodeTables, tables.rows);
  }

  Future<BundleManifest> _manifest(
    BundleTables tables, {
    required String bundleId,
    required String projectId,
  }) async {
    final Map<String, Object?> project = tables.rows['projects']!.single;
    final List<QueryRow> operator = await _db
        .customSelect('SELECT operator_name FROM device_profile LIMIT 1')
        .get();
    final String? operatorName = operator.isEmpty
        ? null
        : operator.single.data['operator_name'] as String?;
    final DateTime now = _clock.nowUtc();
    return BundleManifest(
      formatVersion: BundleFormat.version,
      appVersion: (await _device()).appVersion,
      schemaVersion: kSchemaVersion,
      bundleId: bundleId,
      projectId: projectId,
      projectName: project['name']! as String,
      folderName: tables.folderName,
      exportedAt: now,
      sourceDeviceId: _deviceId,
      operatorName: operatorName == null || operatorName.isEmpty
          ? null
          : operatorName,
      counts: <String, int>{...tables.counts, 'files': tables.filePaths.length},
      versionVectors: tables.versionVectors,
      lineage: <({String device, DateTime at})>[
        ...await _lineage(projectId),
        (device: _deviceId, at: now),
      ],
      templates: <BundleTemplateSummary>[
        for (final Map<String, Object?> template in tables.rows['templates']!)
          (
            id: template['id']! as String,
            templateKey: templateKeyOf(template),
            version: (template['version'] as int?) ?? 1,
            fields: <String, String>{
              for (final Map<String, Object?> field
                  in tables.rows['template_fields']!)
                if (field['template_id'] == template['id'])
                  field['field_key']! as String: field['type']! as String,
            },
          ),
      ],
      entries: const [],
    );
  }

  /// Devices this project arrived from, oldest first, as imports and
  /// merges recorded them.
  Future<List<({String device, DateTime at})>> _lineage(
    String projectId,
  ) async {
    final List<QueryRow> sessions = await _db
        .customSelect(
          'SELECT source_device, imported_at, counts FROM merge_sessions '
          'WHERE json_valid(counts) AND json_extract(counts, '
          "'\$.project_id') = ? ORDER BY imported_at",
          variables: <Variable<Object>>[Variable<String>(projectId)],
        )
        .get();
    final Map<String, ({String device, DateTime at})> steps =
        <String, ({String device, DateTime at})>{};
    void add(String device, DateTime at) {
      steps['$device/${at.toUtc().toIso8601String()}'] = (
        device: device,
        at: at,
      );
    }

    for (final QueryRow session in sessions) {
      final Object? decoded = jsonDecode(session.data['counts']! as String);
      if (decoded is Map<String, Object?> &&
          decoded['lineage'] is List<Object?>) {
        for (final Object? step in decoded['lineage']! as List<Object?>) {
          if (step is Map<String, Object?> &&
              step['device'] is String &&
              step['at'] is String) {
            final DateTime? at = DateTime.tryParse(step['at']! as String);
            if (at != null) add(step['device']! as String, at.toUtc());
          }
        }
      }
      add(
        session.data['source_device']! as String,
        session.read<DateTime>('imported_at'),
      );
    }
    return steps.values.toList()..sort((a, b) => a.at.compareTo(b.at));
  }
}

Map<String, List<int>> _unwrap(Result<Map<String, List<int>>> result) {
  return switch (result) {
    Success<Map<String, List<int>>>(:final Map<String, List<int>> value) =>
      value,
    FailureResult<Map<String, List<int>>>(:final Failure failure) =>
      throw failure,
  };
}

int _size(Map<String, List<int>> entries) {
  var total = 0;
  for (final List<int> bytes in entries.values) {
    total += bytes.length;
  }
  return total;
}

Map<String, List<int>> _encodeTables(
  Map<String, List<Map<String, Object?>>> rows,
) {
  // The table selector omits device credentials entirely; the final encoder
  // also strips secret keys nested in project settings before serialisation.
  return BundleTables(<String, List<Map<String, Object?>>>{
    for (final MapEntry<String, List<Map<String, Object?>>> table
        in rows.entries)
      table.key: table.value.map(BundleRedaction.redact).toList(),
  }).encode();
}
