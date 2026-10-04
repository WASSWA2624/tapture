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
import 'package:tapture/core/export/pdf/transcript_report.dart';
import 'package:tapture/core/export/value_formatter.dart';
import 'package:tapture/core/export/xlsx_encoder.dart';
import 'package:tapture/core/export/xlsx_writer.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/image_resize.dart';

import 'deliverable_reports.dart';
import 'export_pdf.dart';

/// Reuses the pure format writers; no UI builds a workbook or lays out a
/// page. Tables, report aggregation and every PDF render run on the isolate
/// runner; only reduced photo bytes are read here.
final class DeliverableRenderer {
  /// Reads only when a report needs a reduced photo.
  DeliverableRenderer({required this._files, this._font, PdfEngine? engine})
    : _engine = engine ?? exportPdfEngine();

  final FileReader _files;
  final Future<Uint8List> Function()? _font;
  final PdfEngine _engine;

  /// Encodes the chosen formats. [reports] feeds the PDF reports; without it
  /// they carry the records alone. [onStage] reports the `photos` and
  /// `reports` stages from zero to one as each photo and each file is done.
  Future<Result<Map<String, Uint8List>>> render(
    ExportRequest request, {
    required DateTime createdAt,
    required CancellationToken cancel,
    DeliverableReportInputs? reports,
    bool includeText = true,
    void Function(String stage, double fraction)? onStage,
  }) async {
    try {
      final bool pdf = request.formats.contains(ExportFormat.pdf);
      final Map<String, Uint8List> images = pdf
          ? await _reducedPhotos(request, cancel, onStage)
          : const <String, Uint8List>{};
      onStage?.call(_photos, 1);
      final Result<_Rendered> tables = await runIsolate<_Job, _Rendered>(
        _tables,
        (
          request: request,
          includeText: includeText,
          createdAt: createdAt,
          reports: reports ?? _recordsOnly(request),
          engine: _engine,
        ),
        cancel: cancel,
        onProgress: (double fraction) =>
            onStage?.call(_reports, pdf ? fraction / 2 : fraction),
      );
      if (tables case FailureResult<_Rendered>(:final Failure failure)) {
        return FailureResult<Map<String, Uint8List>>(failure);
      }
      final _Rendered rendered = (tables as Success<_Rendered>).value;
      final Map<String, Uint8List> outputs = rendered.outputs;
      final Uint8List? font = rendered.documents.isEmpty
          ? null
          : await _font?.call();
      var done = 0;
      for (final MapEntry<String, PdfDocument> document
          in rendered.documents.entries) {
        await for (final double _ in _engine.render(
          document: document.value,
          token: cancel,
          images: images,
          font: font,
          emit: (Uint8List bytes) => outputs[document.key] = bytes,
          discard: () => outputs.remove(document.key),
        )) {}
        if (cancel.isCancelled) {
          return const FailureResult<Map<String, Uint8List>>(
            CancelledFailure(),
          );
        }
        done += 1;
        onStage?.call(_reports, 0.5 + 0.5 * done / rendered.documents.length);
      }
      onStage?.call(_reports, 1);
      return Success<Map<String, Uint8List>>(outputs);
    } on Failure catch (failure) {
      return FailureResult<Map<String, Uint8List>>(failure);
    } on Object catch (error) {
      return FailureResult<Map<String, Uint8List>>(Failure.from(error));
    }
  }

  /// Every photo of [request] read from its source and reduced, keyed by
  /// its exported name. Originals are only read, never changed.
  Future<Map<String, Uint8List>> _reducedPhotos(
    ExportRequest request,
    CancellationToken cancel,
    void Function(String stage, double fraction)? onStage,
  ) async {
    final List<(ExportRecord, ExportPhoto)> photos =
        <(ExportRecord, ExportPhoto)>[
          for (final ExportRecord record in request.records)
            for (final ExportPhoto photo in record.photos) (record, photo),
        ];
    final Map<String, Uint8List> images = <String, Uint8List>{};
    for (int index = 0; index < photos.length; index++) {
      if (cancel.isCancelled) {
        throw const CancelledFailure();
      }
      final (ExportRecord record, ExportPhoto photo) = photos[index];
      final Result<Uint8List> original = await _files.read(
        record.photoSources[photo.id] ?? photo.storedPath,
      );
      if (original case FailureResult<Uint8List>(
        failure: final Failure photoFailure,
      )) {
        throw photoFailure;
      }
      final Result<Uint8List> small = await ImageResize.fit(
        (original as Success<Uint8List>).value,
        longEdge: 1200,
        quality: 80,
        cancel: cancel,
      );
      if (small case FailureResult<Uint8List>(
        failure: final Failure resizeFailure,
      )) {
        throw resizeFailure;
      }
      images[photo.storedPath] = (small as Success<Uint8List>).value;
      onStage?.call(_photos, (index + 1) / photos.length);
    }
    return images;
  }
}

const String _photos = 'photos';
const String _reports = 'reports';

/// Inputs for reports of the records alone: no checklist, meeting or
/// register data, and the project id as the heading.
DeliverableReportInputs _recordsOnly(ExportRequest request) => (
  projectName: request.projectId,
  cover: const <String>[],
  checklists: const <DeliverableChecklist>[],
  meetings: const <DeliverableMeeting>[],
  transcripts: const <TranscriptContent>[],
  variance: null,
  actionRegister: const <List<String>>[],
);

typedef _Job = ({
  ExportRequest request,
  bool includeText,
  DateTime createdAt,
  DeliverableReportInputs reports,
  PdfEngine engine,
});

typedef _Rendered = ({
  Map<String, Uint8List> outputs,
  Map<String, PdfDocument> documents,
});

_Rendered _tables(_Job job) {
  final ExportRequest request = job.request;
  final Map<String, Uint8List> output = <String, Uint8List>{};
  if (request.formats.contains(ExportFormat.xlsx)) {
    output['records.xlsx'] = XlsxEncoder.encode(
      XlsxWriter.build(request, createdUtc: job.createdAt),
    );
  }
  if (job.includeText && request.formats.contains(ExportFormat.csv)) {
    for (final MapEntry<String, String> file in CsvWriter.write(
      request,
    ).entries) {
      output[file.key] = Uint8List.fromList(utf8.encode(file.value));
    }
  }
  if (job.includeText && request.formats.contains(ExportFormat.json)) {
    output['records.json'] = Uint8List.fromList(
      utf8.encode(JsonWriter.write(request)),
    );
  }
  final List<List<String>> register = job.reports.actionRegister;
  if (register.isNotEmpty &&
      (request.formats.contains(ExportFormat.csv) ||
          request.formats.contains(ExportFormat.xlsx))) {
    output['action_register.csv'] = Uint8List.fromList(
      utf8.encode(
        CsvWriter.table(
          register.first,
          register.sublist(1),
          delimiter: request.extras.delimiter,
        ),
      ),
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
  return (
    outputs: output,
    documents: request.formats.contains(ExportFormat.pdf)
        ? DeliverableReports.documents(request, job.reports, job.engine)
        : const <String, PdfDocument>{},
  );
}
