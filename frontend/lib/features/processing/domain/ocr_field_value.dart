import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/normalise/choices.dart';
import 'package:tapture/core/normalise/dates.dart';
import 'package:tapture/core/normalise/units.dart';
import 'package:tapture/features/templates/domain/domain.dart'
    show FieldDef, FieldType, FieldTypeRegistry;

import 'no_invention_guard.dart';

/// Reads a photographed value with the same type and validation as its form.
abstract final class OcrFieldValue {
  /// A comparable stored value, or null when the evidence is ambiguous/invalid.
  /// The caller retains [raw] beside this derivative.
  static String? read(String raw, FieldDef field, {String locale = 'en'}) {
    final String text = raw.trim();
    if (text.isEmpty) return null;
    final Object? pattern = field.validation['pattern'];
    if (NoInventionGuard.check(
          fieldKey: field.fieldKey,
          value: text,
          evidence: const <String>[],
          evidenceRequired: false,
          pattern: pattern is String ? pattern : null,
        ).value ==
        null) {
      return null;
    }
    Object value = text;
    if (field.type == FieldType.date) {
      final DateValue? date =
          Dates.parse(text, locale: locale) ??
          Dates.parse(text, locale: 'en_US');
      if (date == null || date.ambiguous) return null;
      value = date.stored;
    }
    if (field.type == FieldType.dateTime) {
      final RegExpMatch? stamp = _dateTime.firstMatch(text);
      if (stamp == null ||
          Dates.parse(stamp.group(1)!, locale: 'en') == null ||
          FieldTypeRegistry.validate(
                type: FieldType.time,
                value: stamp.group(2),
                field: field.copyWith(type: FieldType.time),
              )
              is FailureResult<void>) {
        return null;
      }
      final String? offset = stamp.group(3);
      if (offset != null &&
          FieldTypeRegistry.validate(
                type: FieldType.time,
                value: offset.substring(1),
                field: field.copyWith(type: FieldType.time),
              )
              is FailureResult<void>) {
        return null;
      }
    }
    if (field.type == FieldType.choice || field.type == FieldType.lookup) {
      final List<ChoiceOption> options = Choices.options(field.options);
      if (options.isNotEmpty) {
        // Phrase containment can reverse a negation ("not working"). Only an
        // exact label, code or alias supports a local mapped choice.
        final Set<String> labels = <String>{
          for (final ChoiceOption option in options)
            if (<String>[
              option.label,
              if (option.code case final String code) code,
              ...option.aliases,
            ].any(
              (String token) =>
                  token.trim().toLowerCase() == text.toLowerCase(),
            ))
              option.label,
        };
        if (labels.length != 1) return null;
        value = Choices.match(labels.single, options: options)!.label;
      }
    }
    if (_numeric.contains(field.type)) {
      final RegExpMatch? quantity = _quantity.firstMatch(text);
      if (quantity == null) return null;
      final String? unit = field.unit;
      final String? sourceUnit = quantity.group(2);
      if (sourceUnit != null) {
        if (field.type == FieldType.percentage && sourceUnit == '%') {
          value = quantity.group(1)!;
        } else if (unit == null || unit.isEmpty) {
          return null;
        } else if (_foldUnit(unit) == _foldUnit(sourceUnit)) {
          value = quantity.group(1)!;
        } else {
          if (!RegExp(r'^[A-Za-z]+$').hasMatch(sourceUnit)) return null;
          final UnitValue? converted = Units.convert(text, targetUnit: unit);
          if (converted == null) return null;
          value = converted.stored.split(' ').first;
        }
      }
      final num? amount = num.tryParse(value.toString());
      if (amount == null || !amount.isFinite) return null;
    }
    if (!_supported.contains(field.type) ||
        FieldTypeRegistry.validate(type: field.type, value: value, field: field)
            is FailureResult<void>) {
      return null;
    }
    final Object? normalised = FieldTypeRegistry.normalise(
      type: field.type,
      value: value,
      field: field,
    );
    if (normalised is DateTime && field.type == FieldType.date) {
      return value.toString();
    }
    if (normalised is double && normalised == normalised.roundToDouble()) {
      return normalised.toInt().toString();
    }
    return normalised?.toString();
  }
}

const Set<FieldType> _numeric = <FieldType>{
  FieldType.number,
  FieldType.decimal,
  FieldType.currency,
  FieldType.percentage,
};

const Set<FieldType> _supported = <FieldType>{
  FieldType.text,
  FieldType.longText,
  FieldType.barcode,
  FieldType.number,
  FieldType.decimal,
  FieldType.currency,
  FieldType.percentage,
  FieldType.date,
  FieldType.time,
  FieldType.dateTime,
  FieldType.boolean,
  FieldType.choice,
  FieldType.lookup,
};

String _foldUnit(String unit) =>
    unit.replaceAll(RegExp(r'\s+'), '').toLowerCase();

final RegExp _quantity = RegExp(r'^([+-]?\d+(?:\.\d+)?)(?:\s*([^\d\s].*?))?$');
final RegExp _dateTime = RegExp(
  r'^(\d{4}-\d{2}-\d{2})[T ](\d{2}:\d{2}(?::\d{2})?)(?:\.\d+)?(?:Z|([+-]\d{2}:\d{2}))?$',
);
