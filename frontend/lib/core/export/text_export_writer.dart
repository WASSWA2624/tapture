import 'dart:convert';

import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';

import 'csv_writer.dart';
import 'export_manifest.dart';
import 'export_request.dart';
import 'json_writer.dart';
import 'text_export_writer_stub.dart'
    if (dart.library.io) 'text_export_writer_io.dart'
    as platform;
import 'value_formatter.dart';

/// Streams native text deliverables on a worker, retaining at most one row.
final class TextExportWriter {
  /// Uses the same root and atomic file writer as captured project files.
  const TextExportWriter(this.root);

  /// The project files' configured storage root.
  final StorageRoot root;

  /// Every selected text file, keyed by its exported file name.
  static Map<String, Iterable<String>> chunks(
    ExportRequest request,
  ) => <String, Iterable<String>>{
    if (request.formats.contains(ExportFormat.csv)) ...CsvWriter.files(request),
    if (request.formats.contains(ExportFormat.json))
      'records.json': JsonWriter.chunks(request),
  };

  /// Snapshot and manifest streams used by native export publication.
  static Map<String, Iterable<String>> snapshots(
    ExportRequest request,
    ExportManifest manifest,
  ) => <String, Iterable<String>>{
    'request.json': request.chunks(),
    'manifest.json': manifest.chunks(),
  };

  /// Writes replay metadata with the same bounded worker and atomic writer.
  Future<Result<Map<String, WrittenFile>>> writeSnapshots(
    ExportRequest request,
    ExportManifest manifest,
    String folder, {
    required CancellationToken cancel,
  }) => platform.writeText(
    root,
    request,
    folder,
    cancel,
    null,
    manifest: manifest,
  );

  /// Writes [request]'s text formats into [folder], reporting per-file progress.
  /// Cancellation removes each partial or completed file from this attempt.
  Future<Result<Map<String, WrittenFile>>> write(
    ExportRequest request,
    String folder, {
    required CancellationToken cancel,
    void Function(double)? onProgress,
  }) => platform.writeText(root, request, folder, cancel, onProgress);

  /// One UTF-8 row per stream event, without collecting the document.
  static Stream<List<int>> bytes(Iterable<String> chunks) =>
      Stream<String>.fromIterable(chunks).transform(utf8.encoder);
}
