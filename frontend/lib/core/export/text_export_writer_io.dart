import 'dart:io';
import 'dart:isolate';

import 'package:tapture/core/concurrency/cooperative_cancellation.dart';
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/concurrency/worker_cancellation.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/path_sanitizer.dart';
import 'package:tapture/core/files/storage_root.dart';

import 'export_manifest.dart';
import 'export_request.dart';
import 'text_export_writer.dart';

/// Produces rows and encodes UTF-8 inside the worker before atomic publication.
Future<Result<Map<String, WrittenFile>>> writeText(
  StorageRoot root,
  ExportRequest request,
  String folder,
  CancellationToken cancel,
  void Function(double)? onProgress, {
  ExportManifest? manifest,
}) async {
  try {
    final String relative = safeRelativePath(folder);
    final Result<Directory> resolved = await root.resolve();
    if (resolved case FailureResult<Directory>(:final Failure failure)) {
      return FailureResult<Map<String, WrittenFile>>(failure);
    }
    final String base = (resolved as Success<Directory>).value.path;
    return await root.withWriteLock('$base/$relative', () async {
      final List<String> names =
          (manifest == null
                  ? TextExportWriter.chunks(request)
                  : TextExportWriter.snapshots(request, manifest))
              .keys
              .toList();
      // Version folders are append-only. Refuse a reused destination before
      // cancellation cleanup could mistake an earlier export for this run.
      for (final String name in names) {
        if (await File('$base/$relative/$name').exists()) {
          return FailureResult<Map<String, WrittenFile>>(
            StorageFailure(
              localizedMessage: Copy
                  .messages
                  .failureThisExportFolderAlreadyContainsCompletedFiles,
              localizedRecovery:
                  Copy.messages.failureCreateTheExportInANewVersion,
            ),
          );
        }
      }
      if (cancel.isCancelled) {
        return const FailureResult<Map<String, WrittenFile>>(
          CancelledFailure(),
        );
      }
      final CooperativeCancellation bridge = CooperativeCancellation(cancel);
      final Result<Map<String, WrittenFile>> result = await _runWorker(
        base,
        relative,
        request,
        manifest,
        bridge,
        onProgress,
      );
      final Result<Map<String, WrittenFile>> completed = cancel.isCancelled
          ? const FailureResult<Map<String, WrittenFile>>(CancelledFailure())
          : result;
      if (completed is FailureResult<Map<String, WrittenFile>>) {
        for (final String name in names) {
          for (final String suffix in const <String>['', '.part']) {
            final File file = File('$base/$relative/$name$suffix');
            if (await file.exists()) {
              await file.delete();
            }
          }
        }
      }
      return completed;
    });
  } on Object catch (error) {
    return FailureResult<Map<String, WrittenFile>>(Failure.from(error));
  }
}

Future<Result<Map<String, WrittenFile>>> _runWorker(
  String base,
  String relative,
  ExportRequest request,
  ExportManifest? manifest,
  CooperativeCancellation bridge,
  void Function(double)? onProgress,
) async {
  try {
    return await runIsolate<
      ({
        String root,
        String folder,
        ExportRequest request,
        ExportManifest? manifest,
        SendPort cancellation,
      }),
      Map<String, WrittenFile>
    >(_write, (
      root: base,
      folder: relative,
      request: request,
      manifest: manifest,
      cancellation: bridge.handshake,
    ), onProgress: onProgress);
  } finally {
    bridge.close();
  }
}

Future<Map<String, WrittenFile>> _write(
  ({
    String root,
    String folder,
    ExportRequest request,
    ExportManifest? manifest,
    SendPort cancellation,
  })
  job,
) async {
  final WorkerCancellation cancellation = WorkerCancellation(job.cancellation);
  try {
    final FileWriter writer = FileWriter(
      storageRoot: StorageRoot.fake(
        documentsDirectory: Directory(job.root).parent,
        preferredPath: job.root,
      ),
    );
    final Map<String, Iterable<String>> files = job.manifest == null
        ? TextExportWriter.chunks(job.request)
        : TextExportWriter.snapshots(job.request, job.manifest!);
    final Map<String, WrittenFile> written = <String, WrittenFile>{};
    for (final MapEntry<String, Iterable<String>> file in files.entries) {
      await cancellation.checkpoint();
      final Result<WrittenFile> result = await writer.write(
        TextExportWriter.bytes(file.value).map((List<int> bytes) {
          cancellation.check();
          return bytes;
        }),
        '${job.folder}/${file.key}',
      );
      switch (result) {
        case Success<WrittenFile>(:final WrittenFile value):
          written[file.key] = value;
        case FailureResult<WrittenFile>(:final Failure failure):
          throw failure;
      }
      IsolateRunner.reportProgress(written.length / files.length);
    }
    await cancellation.checkpoint();
    return written;
  } finally {
    cancellation.close();
  }
}
