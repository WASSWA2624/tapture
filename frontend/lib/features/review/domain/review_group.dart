import 'package:tapture/core/widgets/fields/field_value.dart';
import 'package:tapture/features/processing/domain/domain.dart'
    show ConfidenceBand;
import 'package:tapture/features/records/domain/domain.dart';
import 'package:tapture/features/templates/domain/domain.dart';

/// Which review group a field belongs to (task 016).
enum ReviewGroup {
  /// A person should look before approving.
  needsAttention,

  /// High confidence and unflagged. Shown collapsed.
  confident,
}

/// [record]'s fields, attention first, in template order within each group.
///
/// Low-confidence, missing, conflicting and duplicate-flagged fields, and a
/// value whose photo evidence was removed, come first. Confident fields
/// follow, for a group the screen starts collapsed. Hidden template fields
/// are left out; a value no template field declares is kept, after them.
List<(FieldValue, ReviewGroup)> orderForReview(
  RecordEntry record,
  TemplateDef template,
) {
  final List<FieldDef> fields = List<FieldDef>.of(template.fields)
    ..sort((FieldDef a, FieldDef b) => a.sortOrder.compareTo(b.sortOrder));
  final List<(FieldValue, ReviewGroup)> attention =
      <(FieldValue, ReviewGroup)>[];
  final List<(FieldValue, ReviewGroup)> confident =
      <(FieldValue, ReviewGroup)>[];
  final Set<String> seen = <String>{};
  void place(String fieldKey, RecordValue? value) {
    final ReviewGroup group = _group(record, value);
    (group == ReviewGroup.needsAttention ? attention : confident).add((
      _asField(fieldKey, value),
      group,
    ));
  }

  for (final FieldDef field in fields) {
    seen.add(field.fieldKey);
    if (!field.hidden) {
      place(field.fieldKey, record.valueOf(field.fieldKey));
    }
  }
  for (final RecordValue value in record.values) {
    if (value.retired || seen.contains(value.fieldKey)) {
      continue;
    }
    place(value.fieldKey, value);
  }
  return <(FieldValue, ReviewGroup)>[...attention, ...confident];
}

ReviewGroup _group(RecordEntry record, RecordValue? value) {
  if (value == null || !value.hasValue || value.evidenceRemoved) {
    return ReviewGroup.needsAttention;
  }
  if (record.flags.contains(RecordFlag.hasConflict) ||
      record.flags.contains(RecordFlag.hasDuplicate)) {
    return ReviewGroup.needsAttention;
  }
  if (value.verified) {
    return ReviewGroup.confident;
  }
  final ConfidenceBand? band = ConfidenceBand.fromStored(value.band);
  return band == null || band == ConfidenceBand.high
      ? ReviewGroup.confident
      : ReviewGroup.needsAttention;
}

FieldValue _asField(String fieldKey, RecordValue? value) {
  return FieldValue(
    fieldKey: fieldKey,
    value: value == null || !value.hasValue ? null : value.display,
    source: value?.valueSource ?? ValueSource.manual,
    verified: value?.verified ?? false,
  );
}
