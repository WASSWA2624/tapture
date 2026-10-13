import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/normalise/units.dart';
import 'package:tapture/features/templates/templates.dart'
    show FieldType, TemplateMapper;

import '../domain/ocr_field_value.dart';

/// One canonical value shared by proposal storage, review and final acceptance.
abstract final class ProcessingValueNormalisation {
  /// Keeps the photographed text beside the template's typed derivative.
  static ({String raw, String? normalised}) read(
    String raw,
    TemplateField field, {
    String locale = 'en',
  }) {
    final definition = TemplateMapper.fieldFromRow(field);
    final String? typed = OcrFieldValue.read(raw, definition, locale: locale);
    if (definition.type == FieldType.text ||
        definition.type == FieldType.longText) {
      final String? unit = field.unit;
      if (unit != null && unit.isNotEmpty) {
        final UnitValue? converted = Units.convert(raw, targetUnit: unit);
        if (converted != null) {
          return (raw: raw, normalised: converted.stored);
        }
      }
    }
    return (raw: raw, normalised: typed == raw ? null : typed);
  }
}
