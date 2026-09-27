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
import 'bundle_tables.dart';
import 'bundle_zip_job.dart';
import 'bundle_zip_stub.dart'
    if (dart.library.io) 'bundle_zip_io.dart'
    if (dart.library.js_interop) 'bundle_zip_web.dart'
    as platform;

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
  Future<Result<int>> estimate(String projectId);

  /// Writes the package of [projectId], adding [extras] (such as the
  /// workbook) as entries. A package estimated above [ceiling] is refused
  /// before anything is written; a cancel or a failure leaves no file.
  Future<Result<BundleOutput>> write({
    required String projectId,
    required CancellationToken cancel,
    void Function(double)? onProgress,
    Map<String, List<int>> extras,
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
  Future<Result<int>> estimate(String projectId) {
    return Result.captureAsync(() async {
      final BundleTables tables = await _read(projectId);
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
  }) async {
    if (cancel.isCancelled) {
      return const FailureResult<BundleOutput>(CancelledFailure());
    }
    final Result<({BundleTables tables, Map<String, List<int>> entries})>
    prepared = await Result.captureAsync(() async {
      final BundleTables tables = await _read(projectId);
      final Map<String, List<int>> json = _unwrap(await _encode(tables));
      return (tables: tables, entries: <String, List<int>>{...json, ...extras});
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
    final int expected = ready.tables.recordedFileBytes + _size(ready.entries);
    if (expected > ceiling) {
      return FailureResult<BundleOutput>(
        StorageFailure(
          message: Copy.packageTooLarge(expected, ceiling),
          recoveryAction: Copy.packageTooLargeRecovery,
        ),
      );
    }
    final String bundleId = _ids.newId();
    final BundleManifest manifest = await _manifest(
      ready.tables,
      bundleId: bundleId,
      projectId: projectId,
    );
    return platform.zipBundle(
      BundleZipJob(
        storageRoot: _storageRoot,
        files: _files,
        folderName: ready.tables.folderName,
        targetPath:
            'projects/${ready.tables.folderName}/exports/$bundleId.'
            '${BundleFormat.extension}',
        entries: ready.entries,
        projectFiles: ready.tables.filePaths,
        manifest: manifest,
        ceiling: ceiling,
        cancel: cancel,
        onProgress: onProgress,
      ),
    );
  }

  Future<BundleTables> _read(String projectId) async {
    final BundleTables? tables = await BundleTables.read(_db, projectId);
    if (tables == null) {
      throw const StorageFailure(
        message: Copy.packageProjectMissing,
        recoveryAction: Copy.tryAgain,
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
          'ORDER BY imported_at',
        )
        .get();
    return <({String device, DateTime at})>[
      for (final QueryRow session in sessions)
        if (_sessionProject(session.data['counts']) == projectId)
          (
            device: session.data['source_device']! as String,
            at: session.read<DateTime>('imported_at'),
          ),
    ];
  }
}

/// A template row's stable key, which lives in its detection JSON; empty
/// when the template has none.
String templateKeyOf(Map<String, Object?> template) {
  final Object? detection = template['detection'];
  if (detection is! String || detection.isEmpty) {
    return '';
  }
  try {
    final Object? decoded = jsonDecode(detection);
    if (decoded is Map<String, Object?>) {
      final Object? key = decoded['template_key'];
      return key is String ? key : '';
    }
  } on FormatException {
    return '';
  }
  return '';
}

String? _sessionProject(Object? counts) {
  if (counts is! String) {
    return null;
  }
  try {
    final Object? decoded = jsonDecode(counts);
    if (decoded is Map<String, Object?>) {
      final Object? project = decoded['project_id'];
      return project is String ? project : null;
    }
  } on FormatException {
    return null;
  }
  return null;
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
  return BundleTables(rows).encode();
}
