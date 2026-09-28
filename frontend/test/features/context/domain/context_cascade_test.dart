import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/context/domain/context_cascade.dart';
import 'package:tapture/features/context/domain/context_state.dart';

void main() {
  const ContextState three = ContextState(
    levels: <ContextLevel>[
      ContextLevel(fieldKey: 'district', order: 0, label: 'district'),
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

  group('a hierarchy with no levels', () {
    test('clears nothing', () {
      expect(
        ContextCascade.affected(
          state: const ContextState(),
          changedFieldKey: 'district',
        ),
        isEmpty,
      );
    });
  });

  group('a one-level hierarchy', () {
    const ContextState one = ContextState(
      levels: <ContextLevel>[
        ContextLevel(fieldKey: 'site', order: 0, label: 'Site'),
      ],
      values: <String, String>{'site': 'A'},
    );

    test('has nothing beneath the change', () {
      expect(
        ContextCascade.affected(state: one, changedFieldKey: 'site'),
        isEmpty,
      );
    });

    test('takes the new value without a confirmation list', () {
      final ContextState next = ContextCascade.apply(
        state: one,
        changedFieldKey: 'site',
        newValue: 'B',
      );
      expect(next.values, <String, String>{'site': 'B'});
    });
  });

  group('a three-level hierarchy', () {
    test('changing the root names facility and department and clears them', () {
      final List<({ContextLevel level, String value})> affected =
          ContextCascade.affected(state: three, changedFieldKey: 'district');
      expect(ContextCascade.named(affected), <String>[
        'Facility (Kasubi HC IV)',
        'Department (Theatre)',
      ]);
      final ContextState next = ContextCascade.apply(
        state: three,
        changedFieldKey: 'district',
        newValue: 'Wakiso',
      );
      expect(next.values, <String, String>{'district': 'Wakiso'});
    });

    test('changing the middle level clears only the level below it', () {
      final List<({ContextLevel level, String value})> affected =
          ContextCascade.affected(state: three, changedFieldKey: 'facility');
      expect(ContextCascade.named(affected), <String>['Department (Theatre)']);
      final ContextState next = ContextCascade.apply(
        state: three,
        changedFieldKey: 'facility',
        newValue: 'Mulago',
      );
      expect(next.values, <String, String>{
        'district': 'Kampala',
        'facility': 'Mulago',
      });
    });

    test('changing the lowest level clears nothing', () {
      expect(
        ContextCascade.affected(state: three, changedFieldKey: 'dept'),
        isEmpty,
      );
      final ContextState next = ContextCascade.apply(
        state: three,
        changedFieldKey: 'dept',
        newValue: 'Laboratory',
      );
      expect(next.values, <String, String>{
        'district': 'Kampala',
        'facility': 'Kasubi HC IV',
        'dept': 'Laboratory',
      });
    });

    test('pins survive every cascade', () {
      final ContextState next = ContextCascade.apply(
        state: three,
        changedFieldKey: 'district',
        newValue: 'Wakiso',
      );
      expect(next.pinned, <String, String>{'surveyor': 'Sam'});
      expect(next.levels, three.levels);
    });
  });

  test('levels are cleared by hierarchy order, not by list position', () {
    const ContextState shuffled = ContextState(
      levels: <ContextLevel>[
        ContextLevel(fieldKey: 'dept', order: 2, label: 'Department'),
        ContextLevel(fieldKey: 'district', order: 0, label: 'District'),
        ContextLevel(fieldKey: 'facility', order: 1, label: 'Facility'),
      ],
      values: <String, String>{
        'district': 'Kampala',
        'facility': 'Kasubi HC IV',
        'dept': 'Theatre',
      },
    );
    final List<({ContextLevel level, String value})> affected =
        ContextCascade.affected(state: shuffled, changedFieldKey: 'facility');
    expect(
      affected.map(
        (({ContextLevel level, String value}) item) => item.level.fieldKey,
      ),
      <String>['dept'],
    );
    expect(
      ContextCascade.affected(
        state: shuffled,
        changedFieldKey: 'district',
      ).map((({ContextLevel level, String value}) item) => item.level.fieldKey),
      <String>['facility', 'dept'],
    );
  });

  test('a key that is not a level affects no level', () {
    expect(
      ContextCascade.affected(state: three, changedFieldKey: 'surveyor'),
      isEmpty,
    );
  });

  test('the confirmation names only levels that hold a value', () {
    final ContextState partial = three.copyWith(
      values: <String, String>{'district': 'Kampala', 'dept': 'Theatre'},
    );
    final List<({ContextLevel level, String value})> affected =
        ContextCascade.affected(state: partial, changedFieldKey: 'district');
    expect(affected, hasLength(2));
    expect(ContextCascade.named(affected), <String>['Department (Theatre)']);
  });

  test(
    'the confirmation falls back to the field key when a label is empty',
    () {
      const ContextState unlabeled = ContextState(
        levels: <ContextLevel>[
          ContextLevel(fieldKey: 'district', order: 0),
          ContextLevel(fieldKey: 'facility', order: 1),
        ],
        values: <String, String>{'district': 'Kampala', 'facility': 'Kasubi'},
      );
      expect(
        ContextCascade.named(
          ContextCascade.affected(
            state: unlabeled,
            changedFieldKey: 'district',
          ),
        ),
        <String>['facility (Kasubi)'],
      );
    },
  );

  test('applying a change never mutates the state it was given', () {
    final Map<String, String> values = <String, String>{
      'district': 'Kampala',
      'facility': 'Kasubi HC IV',
    };
    final ContextState state = ContextState(
      levels: three.levels,
      values: values,
    );
    ContextCascade.apply(
      state: state,
      changedFieldKey: 'district',
      newValue: 'Wakiso',
    );
    expect(values, <String, String>{
      'district': 'Kampala',
      'facility': 'Kasubi HC IV',
    });
  });
}
