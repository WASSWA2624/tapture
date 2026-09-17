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
}
