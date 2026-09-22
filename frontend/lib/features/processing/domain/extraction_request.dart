import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/constants/app_constants.dart';

/// One extraction call for a record, shaped as the specification example.
///
/// OCR text, captions and field names are fields on the payload. They are
/// never interpolated into an instruction string.
final class ExtractionRequest {
  /// Creates a request. [images] are compressed copies, never originals.
  const ExtractionRequest({
    required this.template,
    required this.fields,
    required this.context,
    required this.predefinedRows,
    required this.caption,
    required this.ocrText,
    required this.images,
    this.rules = defaultRules,
  });

  /// Rules quoted as data on every request.
  static const List<String> defaultRules = <String>[
    'Return only values supported by the supplied evidence.',
    'Use null when a value is not present. Never guess.',
    'Return valid JSON matching the schema.',
  ];

  /// Template display name.
  final String template;

  /// Field list the response must follow.
  final List<ExtractionField> fields;

  /// Context values that apply to the record.
  final Map<String, String> context;

  /// Predefined row labels already known locally.
  final List<String> predefinedRows;

  /// Record caption, quoted as data.
  final String caption;

  /// On-device text, quoted as data.
  final String ocrText;

  /// Compressed image references, in capture order.
  final List<String> images;

  /// Explicit rules, quoted as data.
  final List<String> rules;

  /// Wire shape from the specification.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'template': template,
      'fields': <Object?>[
        for (final ExtractionField field in fields) field.toJson(),
      ],
      'context': context,
      'predefined_rows': predefinedRows,
      'caption': caption,
      'ocr_text': ocrText,
      'images': images,
      'rules': rules,
    };
  }

  /// The service request. Labels travel as data on [ExtractFieldsRequest].
  ExtractFieldsRequest toService() {
    return ExtractFieldsRequest(
      templateLabel: template,
      fieldLabels: <String>[
        for (final ExtractionField field in fields) field.key,
      ],
      ocrText: ocrText,
      transcripts: const <String>[],
      captions: caption.isEmpty ? const <String>[] : <String>[caption],
      imagePaths: images,
      context: context,
    );
  }

  /// How many images one call may carry.
  static int get imageCap => AppConstants.processing.extractionImageCap;
}

/// One field on an [ExtractionRequest].
typedef ExtractionField = ({
  String key,
  String type,
  bool requiredField,
  String? pattern,
  List<String>? options,
  List<String>? optionsHint,
});

/// JSON for one [ExtractionField], omitting empty hints.
extension ExtractionFieldJson on ExtractionField {
  /// Wire object for this field.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'key': key,
      'type': type,
      'required': requiredField,
      'pattern': ?pattern,
      'options': ?options,
      'options_hint': ?optionsHint,
    };
  }
}
