import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/context/domain/context_application.dart';
import 'package:tapture/features/context/domain/context_state.dart';

/// What [ContextApplication.apply] hands back for one record.
typedef _Applied = ({
  List<({String fieldKey, String value, String source})> fields,
  Map<String, Object?> snapshot,
});

void main() {
  const ContextState three = ContextState(
    levels: <ContextLevel>[
      ContextLevel(fieldKey: 'district', order: 0, label: 'District'),
      ContextLevel(
        fieldKey: 'facility',
        order: 1,
        label: 'Facility',
        datasetId: 'ds-1',
      ),
      ContextLevel(fieldKey: 'dept', order: 2, label: 'Department'),
    ],
    values: <String, String>{
      'district': 'Kampala',
      'facility': 'Kasubi HC IV',
      'dept': 'Theatre',
    },
    pinned: <String, String>{'surveyor': 'Sam'},
  );

  List<(String, String)> pairs(_Applied applied) {
    return <(String, String)>[
      for (final ({String fieldKey, String value, String source}) field
          in applied.fields)
        (field.fieldKey, field.value),
    ];
  }

  test('a new record carries each level and pin with source CONTEXT', () {
    final _Applied applied = ContextApplication.apply(three);
    expect(
      applied.fields.map(
        (({String fieldKey, String value, String source}) field) =>
            field.source,
      ),
      everyElement('CONTEXT'),
    );
    expect(pairs(applied), <(String, String)>[
      ('district', 'Kampala'),
      ('facility', 'Kasubi HC IV'),
      ('dept', 'Theatre'),
      ('surveyor', 'Sam'),
    ]);
  });

  test('a level without a value writes no field', () {
    final ContextState partial = three.copyWith(
      values: <String, String>{'district': 'Kampala', 'facility': ''},
    );
    expect(pairs(ContextApplication.apply(partial)), <(String, String)>[
      ('district', 'Kampala'),
      ('surveyor', 'Sam'),
    ]);
  });

  test('a project with no levels and no pins writes no fields', () {
    final _Applied applied = ContextApplication.apply(const ContextState());
    expect(applied.fields, isEmpty);
    expect(applied.snapshot['levels'], isEmpty);
    expect(applied.snapshot['values'], isEmpty);
    expect(applied.snapshot['pinned'], isEmpty);
  });

  test('the snapshot keeps every level in order with its value', () {
    final _Applied applied = ContextApplication.apply(three);
    expect(applied.snapshot['levels'], <Map<String, Object?>>[
      <String, Object?>{
        'fieldKey': 'district',
        'order': 0,
        'datasetId': null,
        'label': 'District',
        'value': 'Kampala',
      },
      <String, Object?>{
        'fieldKey': 'facility',
        'order': 1,
        'datasetId': 'ds-1',
        'label': 'Facility',
        'value': 'Kasubi HC IV',
      },
      <String, Object?>{
        'fieldKey': 'dept',
        'order': 2,
        'datasetId': null,
        'label': 'Department',
        'value': 'Theatre',
      },
    ]);
    expect(applied.snapshot['values'], three.values);
    expect(applied.snapshot['pinned'], three.pinned);
  });

  test('a later context change cannot rewrite an earlier snapshot', () {
    final Map<String, String> values = <String, String>{'district': 'Kampala'};
    final Map<String, String> pinned = <String, String>{'surveyor': 'Sam'};
    final ContextState live = ContextState(
      levels: three.levels,
      values: values,
      pinned: pinned,
    );
    final _Applied applied = ContextApplication.apply(live);

    values['district'] = 'Wakiso';
    pinned['surveyor'] = 'Ada';

    expect(applied.snapshot['values'], <String, String>{'district': 'Kampala'});
    expect(applied.snapshot['pinned'], <String, String>{'surveyor': 'Sam'});
    expect(pairs(applied), <(String, String)>[
      ('district', 'Kampala'),
      ('surveyor', 'Sam'),
    ]);
  });

  test('ten records captured in one room all carry the same values', () {
    final _Applied first = ContextApplication.apply(three);
    for (int i = 1; i < 10; i++) {
      final _Applied next = ContextApplication.apply(three);
      expect(pairs(next), pairs(first));
      expect(next.snapshot, first.snapshot);
    }
  });
}
