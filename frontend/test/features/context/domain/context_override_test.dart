import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/context/domain/context_application.dart';
import 'package:tapture/features/context/domain/context_override.dart';
import 'package:tapture/features/context/domain/context_state.dart';

/// The plan [ContextOverride.plan] returns for one field.
typedef _Plan = ({
  String fieldKey,
  String rawValue,
  String refinedValue,
  bool overridden,
});

void main() {
  const ContextState three = ContextState(
    levels: <ContextLevel>[
      ContextLevel(fieldKey: 'district', order: 0, label: 'District'),
      ContextLevel(fieldKey: 'facility', order: 1, label: 'Facility'),
      ContextLevel(fieldKey: 'dept', order: 2, label: 'Department'),
    ],
    values: <String, String>{
      'district': 'Kampala',
      'facility': 'Kasubi HC IV',
      'dept': 'Theatre',
    },
    pinned: <String, String>{'surveyor': 'Sam'},
  );

  test('an override keeps the raw value and writes the correction beside it', () {
    final _Plan planned = ContextOverride.plan(
      fieldKey: 'dept',
      rawValue: 'Theatre',
      newValue: 'Laboratory',
    );
    expect(planned.fieldKey, 'dept');
    expect(planned.rawValue, 'Theatre');
    expect(planned.refinedValue, 'Laboratory');
    expect(planned.overridden, isTrue);
    expect(
      ContextOverride.isOverridden(
        rawValue: planned.rawValue,
        refinedValue: planned.refinedValue,
      ),
      isTrue,
    );
  });

  test('entering the prefilled value again is not an override', () {
    final _Plan planned = ContextOverride.plan(
      fieldKey: 'dept',
      rawValue: 'Theatre',
      newValue: 'Theatre',
    );
    expect(planned.overridden, isFalse);
    expect(
      ContextOverride.isOverridden(rawValue: 'Theatre', refinedValue: 'Theatre'),
      isFalse,
    );
  });

  test('a field with no refined value beside it is not overridden', () {
    expect(ContextOverride.isOverridden(rawValue: 'Theatre'), isFalse);
    expect(
      ContextOverride.isOverridden(rawValue: null, refinedValue: 'Theatre'),
      isTrue,
    );
  });

  test(
    'correcting one record moves neither the project context nor a sibling',
    () {
      final ({
        List<({String fieldKey, String value, String source})> fields,
        Map<String, Object?> snapshot,
      })
      first = ContextApplication.apply(three);
      final ({
        List<({String fieldKey, String value, String source})> fields,
        Map<String, Object?> snapshot,
      })
      sibling = ContextApplication.apply(three);
      final ({String fieldKey, String value, String source}) dept = first.fields
          .singleWhere(
            (({String fieldKey, String value, String source}) field) =>
                field.fieldKey == 'dept',
          );

      final _Plan planned = ContextOverride.plan(
        fieldKey: dept.fieldKey,
        rawValue: dept.value,
        newValue: 'Laboratory',
      );

      expect(planned.refinedValue, 'Laboratory');
      expect(dept.value, 'Theatre');
      expect(dept.source, ContextApplication.source);
      expect(three.values['dept'], 'Theatre');
      expect(
        sibling.fields
            .singleWhere(
              (({String fieldKey, String value, String source}) field) =>
                  field.fieldKey == 'dept',
            )
            .value,
        'Theatre',
      );
      expect(sibling.snapshot, first.snapshot);
    },
  );
}
