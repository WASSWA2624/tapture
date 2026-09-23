part of 'ai_service.dart';

/// Evidence and template labels for one extraction call.
///
/// OCR text, transcripts, captions and field labels sit on this type as
/// quoted data. An implementation must send them as fields, never interpolate
/// them into an instruction string (FE-SEC-05).
final class ExtractFieldsRequest {
  /// Creates an extraction request.
  const ExtractFieldsRequest({
    required this.templateLabel,
    required this.fieldLabels,
    required this.ocrText,
    required this.transcripts,
    required this.captions,
    required this.imagePaths,
    this.context = const <String, String>{},
    this.fieldSchema = const <Map<String, Object?>>[],
    this.predefinedRows = const <String>[],
    this.rules = const <String>[],
    this.repairError,
  });

  /// The template's display name, quoted as data.
  final String templateLabel;

  /// Field names from the template, quoted as data.
  final List<String> fieldLabels;

  /// On-device OCR text, quoted as data.
  final String ocrText;

  /// Spoken notes on the record, quoted as data.
  final List<String> transcripts;

  /// Record and photo captions, quoted as data.
  final List<String> captions;

  /// Compressed copies attached to the call. Originals stay on the device.
  final List<String> imagePaths;

  /// Context values that apply to the record (district, facility, …).
  final Map<String, String> context;

  /// Template field definitions, kept as structured data.
  final List<Map<String, Object?>> fieldSchema;

  /// Locally known row labels the provider may select from.
  final List<String> predefinedRows;

  /// Evidence and JSON constraints, carried as data rather than interpolated.
  final List<String> rules;

  /// Parse failure from the one permitted repair call, quoted as data.
  final String? repairError;
}
