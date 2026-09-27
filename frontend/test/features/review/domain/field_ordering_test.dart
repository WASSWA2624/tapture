import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/widgets/fields/field_value.dart';
import 'package:tapture/features/records/domain/record_entry.dart';
import 'package:tapture/features/records/domain/record_flag.dart';
import 'package:tapture/features/records/domain/record_value.dart';
import 'package:tapture/features/review/domain/field_ordering.dart';
import 'package:tapture/features/templates/domain/field_def.dart';
import 'package:tapture/features/templates/domain/template_def.dart';

import '../../../support/factories.dart';

void main() {
  final TemplateDef template = aTemplate(
    fields: const <FieldDef>[
      FieldDef(fieldKey: 'serial', label: 'Serial', type: FieldType.text),
      FieldDef(
        fieldKey: 'note',
        label: 'Note',
        type: FieldType.text,
        sortOrder: 1,
      ),
    ],
  );

  test('a low-confidence field comes before a confident one', () {
    final List<(FieldValue, ReviewGroup)> ordered = orderForReview(
      _record(<RecordValue>[
        _value('serial', 'A-1', band: 'reviewRequired'),
        _value('note', 'Fine', band: 'high'),
      ]),
      template,
    );
    expect(ordered.first.$1.fieldKey, 'serial');
    expect(ordered.first.$2, ReviewGroup.needsAttention);
    expect(ordered.last.$2, ReviewGroup.confident);
  });

  test('a missing field needs attention', () {
    final (FieldValue, ReviewGroup) row =
        orderForReview(
          _record(<RecordValue>[_value('serial', '')]),
          template,
        ).firstWhere(
          ((FieldValue, ReviewGroup) row) => row.$1.fieldKey == 'serial',
        );
    expect(row.$2, ReviewGroup.needsAttention);
  });

  test('a conflict flag lifts every field', () {
    final List<(FieldValue, ReviewGroup)> ordered = orderForReview(
      _record(
        <RecordValue>[_value('serial', 'A-1', band: 'high')],
        flags: <RecordFlag>{RecordFlag.hasConflict},
      ),
      template,
    );
    expect(
      ordered.every(
        ((FieldValue, ReviewGroup) row) => row.$2 == ReviewGroup.needsAttention,
      ),
      isTrue,
    );
  });

  test('a duplicate flag lifts every field', () {
    final (FieldValue, ReviewGroup) row = orderForReview(
      _record(
        <RecordValue>[_value('serial', 'A-1', band: 'high')],
        flags: <RecordFlag>{RecordFlag.hasDuplicate},
      ),
      template,
    ).first;
    expect(row.$2, ReviewGroup.needsAttention);
  });

  test('removed evidence needs attention even when the band is high', () {
    final (FieldValue, ReviewGroup) row =
        orderForReview(
          _record(<RecordValue>[
            _value('serial', 'A-1', band: 'high', evidenceRemoved: true),
          ]),
          template,
        ).firstWhere(
          ((FieldValue, ReviewGroup) row) => row.$1.fieldKey == 'serial',
        );
    expect(row.$2, ReviewGroup.needsAttention);
  });

  test('missing and low confidence together still need attention once', () {
    final List<(FieldValue, ReviewGroup)> matches =
        orderForReview(
              _record(<RecordValue>[_value('serial', '', band: 'medium')]),
              template,
            )
            .where(
              ((FieldValue, ReviewGroup) row) => row.$1.fieldKey == 'serial',
            )
            .toList();
    expect(matches, hasLength(1));
    expect(matches.single.$2, ReviewGroup.needsAttention);
  });
}

RecordEntry _record(
  List<RecordValue> values, {
  Set<RecordFlag> flags = const <RecordFlag>{},
}) {
  return aRecordEntry().copyWith(values: values, flags: flags);
}

RecordValue _value(
  String key,
  String raw, {
  String? band,
  bool evidenceRemoved = false,
}) {
  return RecordValue(
    fieldKey: key,
    raw: raw,
    band: band,
    evidenceRemoved: evidenceRemoved,
  );
}
