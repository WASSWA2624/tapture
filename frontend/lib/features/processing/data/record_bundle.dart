import 'package:tapture/core/db/app_database.dart';

/// Everything one processing stage reads about a record, loaded in one pass.
///
/// Rows are Drift types, so the bundle never leaves the data layer.
final class RecordBundle {
  /// Creates a bundle from rows already read.
  const RecordBundle({
    required this.record,
    required this.project,
    required this.template,
    required this.fields,
    required this.rows,
    required this.photos,
    required this.captions,
    required this.audio,
    required this.existing,
  });

  /// The record being processed.
  final RecordRow record;

  /// The project the record belongs to.
  final Project project;

  /// The template the record was captured against.
  final Template template;

  /// The template's fields, in sort order.
  final List<TemplateField> fields;

  /// The template's predefined rows.
  final List<TemplateRow> rows;

  /// The record's photos, in capture order.
  final List<Photo> photos;

  /// Captions on the record and on its photos.
  final List<Caption> captions;

  /// Audio clips attached to the record.
  final List<Attachment> audio;

  /// Field values already stored on the record.
  final List<RecordField> existing;
}
