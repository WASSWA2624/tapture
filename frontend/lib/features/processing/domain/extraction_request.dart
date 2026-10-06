import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/security/untrusted_text.dart';

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
    this.transcripts = const <UntrustedText>[],
    this.rules = defaultRules,
    this.basis = '',
    this.sources = const <Map<String, Object?>>[],
  });

  /// Rules quoted as data on every request.
  static const List<String> defaultRules = <String>[
    'Return only values supported by the supplied evidence.',
    'Use null when a value is not present. Never guess.',
    'Return valid JSON matching the schema.',
    'Every non-null value must cite the supplied source IDs in evidence.',
    'Flag conflicting values, missing requirements and uncertain item grouping for review.',
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
  final UntrustedText caption;

  /// On-device text, quoted as data.
  final UntrustedText ocrText;

  /// Compressed image references, in capture order.
  final List<String> images;

  /// Raw provider transcripts, stored and quoted as evidence.
  final List<UntrustedText> transcripts;

  /// Why the values look the way they do. Set when images stay on device.
  final String basis;

  /// Explicit rules, quoted as data.
  final List<String> rules;

  /// Source identities and ownership remain structured rather than flattened.
  final List<Map<String, Object?>> sources;

  /// Wire shape from the specification.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'template': template,
      'fields': <Object?>[
        for (final ExtractionField field in fields) field.toJson(),
      ],
      'context': context,
      'predefined_rows': predefinedRows,
      'caption': caption.asDataBlock('caption'),
      'ocr_text': ocrText.asDataBlock('ocr'),
      'images': images,
      'transcripts': <String>[
        for (final UntrustedText text in transcripts)
          text.asDataBlock('transcript'),
      ],
      'rules': rules,
      if (basis.isNotEmpty) 'basis': basis,
      if (sources.isNotEmpty) 'sources': sources,
    };
  }

  /// The service request. Labels travel as data on [ExtractFieldsRequest].
  ExtractFieldsRequest toService() {
    return ExtractFieldsRequest(
      templateLabel: template,
      fieldLabels: <String>[
        for (final ExtractionField field in fields) field.key,
      ],
      ocrText: ocrText.asDataBlock('ocr'),
      transcripts: <String>[
        for (final UntrustedText text in transcripts)
          text.asDataBlock('transcript'),
      ],
      captions: caption.raw.isEmpty
          ? const <String>[]
          : <String>[caption.asDataBlock('caption')],
      imagePaths: images,
      context: context,
      fieldSchema: <Map<String, Object?>>[
        for (final ExtractionField field in fields) field.toJson(),
      ],
      predefinedRows: predefinedRows,
      rules: rules,
      sources: sources,
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
