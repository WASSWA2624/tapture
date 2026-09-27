import '../export_record.dart';
import '../export_request.dart';
import 'pdf_engine.dart';

/// One record per block, through [PdfEngine] (task 018).
final class RecordReport {
  /// Body lines: fields, context, operator and photos.
  static PdfDocument build(
    ExportRequest request, {
    required PdfEngine engine,
    required int photoColumns,
  }) {
    final List<String> lines = <String>[];
    final List<({String caption, String path})> photos =
        <({String caption, String path})>[];
    for (final ExportRecord record in request.records) {
      lines.add(record.number);
      lines.add(record.contextPath);
      lines.add(record.operatorName);
      for (final ExportValue value in record.values) {
        lines.add('${value.label} ${value.finalText ?? value.raw ?? ''}');
        if (request.columns.refined && value.refined != null) {
          lines.add('Refined ${value.label} ${value.refined}');
        }
      }
      for (final ExportPhoto photo in record.photos) {
        photos.add((caption: photo.caption, path: photo.storedPath));
      }
    }
    return engine.document(
      title: 'Record report',
      project: request.projectId,
      coverLines: <String>['records ${request.records.length}'],
      bodyLines: lines,
      photos: engine.photoBlock(photos, columns: photoColumns),
    );
  }
}
