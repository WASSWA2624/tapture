import 'dart:convert';
import 'dart:typed_data';

import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/export/csv_writer.dart';
import 'package:tapture/core/export/export_record.dart';
import 'package:tapture/core/export/export_request.dart';
import 'package:tapture/core/export/json_writer.dart';
import 'package:tapture/core/export/pdf/pdf_engine.dart';
import 'package:tapture/core/export/pdf/record_report.dart';
import 'package:tapture/core/export/value_formatter.dart';
import 'package:tapture/core/export/xlsx_encoder.dart';
import 'package:tapture/core/export/xlsx_writer.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/image_resize.dart';

/// Reuses the pure format writers; no UI builds a workbook or lays out a page.
final class DeliverableRenderer {
  /// Reads only when a report needs a reduced photo.
  const DeliverableRenderer({required this._files, this._font});

  final FileReader _files;
  final Future<Uint8List> Function()? _font;

  /// Encodes chosen formats with progress at each record/report boundary.
  Future<Result<Map<String, Uint8List>>> render(
    ExportRequest request, {
    required DateTime createdAt,
    required CancellationToken cancel,
    void Function(double)? onProgress,
  }) async {
    final Result<Map<String, Uint8List>> tables =
        await runIsolate<
          ({ExportRequest request, DateTime createdAt}),
          Map<String, Uint8List>
        >(
          _tables,
          (request: request, createdAt: createdAt),
          cancel: cancel,
          onProgress: onProgress,
        );
    if (tables is FailureResult<Map<String, Uint8List>>) return tables;
    final Map<String, Uint8List> outputs =
        (tables as Success<Map<String, Uint8List>>).value;
    if (!request.formats.contains(ExportFormat.pdf)) {
      return Success<Map<String, Uint8List>>(outputs);
    }
    try {
      final Map<String, Uint8List> images = <String, Uint8List>{};
      for (final ExportRecord record in request.records) {
        for (final ExportPhoto photo in record.photos) {
          if (cancel.isCancelled) {
            return const FailureResult<Map<String, Uint8List>>(
              CancelledFailure(),
            );
          }
          final Result<Uint8List> original = await _files.read(
            record.photoSources[photo.id] ?? photo.storedPath,
          );
          if (original case FailureResult<Uint8List>(:final Failure failure)) {
            return FailureResult<Map<String, Uint8List>>(failure);
          }
          final Result<Uint8List> small = await ImageResize.fit(
            (original as Success<Uint8List>).value,
            longEdge: 1200,
            quality: 80,
            cancel: cancel,
          );
          if (small case FailureResult<Uint8List>(:final Failure failure)) {
            return FailureResult<Map<String, Uint8List>>(failure);
          }
          images[photo.storedPath] = (small as Success<Uint8List>).value;
        }
      }
      const PdfEngine engine = PdfEngine();
      await for (final double progress in engine.render(
        document: RecordReport.build(
          request,
          engine: engine,
          photoColumns: request.extras.photoMode == 'full' ? 1 : 3,
        ),
        token: cancel,
        images: images,
        font: await _font?.call(),
        emit: (Uint8List bytes) => outputs['records.pdf'] = bytes,
        discard: () => outputs.remove('records.pdf'),
      )) {
        onProgress?.call(progress);
      }
      if (cancel.isCancelled) {
        return const FailureResult<Map<String, Uint8List>>(CancelledFailure());
      }
      return Success<Map<String, Uint8List>>(outputs);
    } on Object catch (error) {
      return FailureResult<Map<String, Uint8List>>(Failure.from(error));
    }
  }
}

Map<String, Uint8List> _tables(
  ({ExportRequest request, DateTime createdAt}) job,
) {
  final ExportRequest request = job.request;
  final Map<String, Uint8List> output = <String, Uint8List>{};
  if (request.formats.contains(ExportFormat.xlsx)) {
    output['records.xlsx'] = XlsxEncoder.encode(
      XlsxWriter.build(request, createdUtc: job.createdAt),
    );
  }
  if (request.formats.contains(ExportFormat.csv)) {
    for (final MapEntry<String, String> file in CsvWriter.write(
      request,
    ).entries) {
      output[file.key] = Uint8List.fromList(utf8.encode(file.value));
    }
  }
  if (request.formats.contains(ExportFormat.json)) {
    output['records.json'] = Uint8List.fromList(
      utf8.encode(JsonWriter.write(request)),
    );
  }
  if (request.extras.dictionary) {
    final Map<String, Object?> definitions = <String, Object?>{};
    for (final ExportRecord record in request.records) {
      definitions.putIfAbsent(
        '${record.templateId}@${record.templateVersion}',
        () => <String, Object?>{
          'templateId': record.templateId,
          'templateName': record.templateName,
          'templateVersion': record.templateVersion,
          'fields': record.definitions,
        },
      );
    }
    output['dictionary.json'] = Uint8List.fromList(
      utf8.encode(jsonEncode(definitions.values.toList())),
    );
  }
  IsolateRunner.reportProgress(1);
  return output;
}
