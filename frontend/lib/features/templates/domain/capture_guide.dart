import 'package:tapture/core/constants/app_constants.dart';

import 'field_def.dart';
import 'template_def.dart';

/// What a template asks a person to capture, built from the template itself
/// (FBK0000157): the fields the photos should show, and the fields to say
/// or type in the caption. Labels are template data, never translated
/// (FE-L10N-07).
final class CaptureGuide {
  /// Creates a guide.
  const CaptureGuide({required this.photoFields, required this.captionFields});

  /// Builds the guide of [template].
  ///
  /// The photos should show its identity fields and its barcodes, in field
  /// order. The caption should cover its required then recommended fields
  /// that a person describes: never a photo field, a hidden or automatic
  /// field, one filled by the system, by context or kept sticky, a file or
  /// signature, nor one of the record-keeping, location, evidence, review or
  /// context groups every template inherits. Each list holds at most
  /// `AppConstants.capture.guideMaxFields` labels.
  factory CaptureGuide.of(TemplateDef template) {
    final int cap = AppConstants.capture.guideMaxFields;
    final List<FieldDef> ordered = List<FieldDef>.of(template.fields)
      ..sort((FieldDef a, FieldDef b) => a.sortOrder.compareTo(b.sortOrder));
    final Set<String> identity = <String>{...template.identityFieldKeys};
    bool isPhoto(FieldDef field) =>
        field.identity ||
        identity.contains(field.fieldKey) ||
        field.type == FieldType.barcode;
    final List<FieldDef> photos = <FieldDef>[
      for (final FieldDef field in ordered)
        if (!field.hidden && isPhoto(field)) field,
    ];
    bool describable(FieldDef field) =>
        !field.hidden &&
        !isPhoto(field) &&
        field.inputMode != InputMode.auto &&
        field.autoFill == null &&
        field.contextLevel == null &&
        !field.stickable &&
        !_notSaid.contains(field.type) &&
        !_inherited.contains(field.group);
    final List<FieldDef> caption = <FieldDef>[
      for (final Requiredness level in const <Requiredness>[
        Requiredness.required,
        Requiredness.recommended,
      ])
        for (final FieldDef field in ordered)
          if (field.requiredness == level && describable(field)) field,
    ];
    return CaptureGuide(
      photoFields: <String>[
        for (final FieldDef field in photos) _label(field),
      ].take(cap).toList(),
      captionFields: <String>[
        for (final FieldDef field in caption) _label(field),
      ].take(cap).toList(),
    );
  }

  /// Labels of what the photos should show.
  final List<String> photoFields;

  /// Labels of what to say or type in the caption.
  final List<String> captionFields;

  /// Whether there is nothing to guide.
  bool get isEmpty => photoFields.isEmpty && captionFields.isEmpty;
}

String _label(FieldDef field) =>
    field.label.trim().isEmpty ? field.fieldKey : field.label.trim();

/// The field groups every catalogue template inherits, which capture fills
/// or which describe where and when rather than what.
const Set<String> _inherited = <String>{
  'record_admin',
  'location',
  'evidence',
  'review',
  'context',
};

/// Types a person does not say in a caption.
const Set<FieldType> _notSaid = <FieldType>{
  FieldType.photoReference,
  FieldType.documentReference,
  FieldType.signature,
  FieldType.gpsLocation,
  FieldType.computed,
};
