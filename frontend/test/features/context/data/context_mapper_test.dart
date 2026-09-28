import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/features/context/data/context_mapper.dart';
import 'package:tapture/features/context/domain/context_state.dart';

void main() {
  final DateTime at = DateTime.utc(2026, 9, 22, 8);
  const String projectId = 'proj-1';

  /// A stored definition row for [level], built through [ContextMapper].
  sqlite.ContextData definition(ContextLevel level, {String id = 'def'}) {
    final sqlite.ContextCompanion companion = ContextMapper.definitionToRow(
      projectId: projectId,
      level: level,
    );
    return sqlite.ContextData(
      id: '$id-${level.fieldKey}',
      createdAt: at,
      updatedAt: at,
      updatedByDevice: 'device-a',
      rev: 1,
      projectId: companion.projectId.value,
      level: companion.level.value,
      fieldKey: companion.fieldKey.value,
      label: companion.label.value,
    );
  }

  sqlite.ContextStateRow stateRow({
    required int level,
    required String fieldKey,
    required String value,
  }) {
    return sqlite.ContextStateRow(
      id: 'st-$level-$fieldKey',
      createdAt: at,
      updatedAt: at,
      updatedByDevice: 'device-a',
      rev: 1,
      projectId: projectId,
      level: level,
      fieldKey: fieldKey,
      value: value,
      setAt: at,
    );
  }

  sqlite.ContextStateRow pinRow(Map<String, String> pinned) {
    return stateRow(level: 0, fieldKey: '', value: jsonEncode(pinned));
  }

  sqlite.ContextPreset presetRow(String values, {String name = 'Theatre'}) {
    return sqlite.ContextPreset(
      id: 'pre-1',
      createdAt: at,
      updatedAt: at,
      updatedByDevice: 'device-a',
      rev: 1,
      name: name,
      projectId: projectId,
      values: values,
    );
  }

  group('ContextLevel', () {
    test('round-trips through its definition row with a dataset binding', () {
      const ContextLevel level = ContextLevel(
        fieldKey: 'facility',
        order: 1,
        label: 'Facility',
        datasetId: 'ds-1',
      );
      final ContextState state = ContextMapper.fromRows(
        definitions: <sqlite.ContextData>[definition(level)],
        states: const <sqlite.ContextStateRow>[],
        pinned: const <String, String>{},
      );
      expect(state.levels.single, equals(level));
    });

    test('round-trips without a dataset as a plain label', () {
      const ContextLevel level = ContextLevel(
        fieldKey: 'district',
        order: 0,
        label: 'District',
      );
      expect(ContextMapper.encodeLabel(level), 'District');
      final ContextState state = ContextMapper.fromRows(
        definitions: <sqlite.ContextData>[definition(level)],
        states: const <sqlite.ContextStateRow>[],
        pinned: const <String, String>{},
      );
      expect(state.levels.single, equals(level));
    });

    test('stores the drift level one above the zero-based order', () {
      final sqlite.ContextCompanion row = ContextMapper.definitionToRow(
        projectId: projectId,
        level: const ContextLevel(fieldKey: 'dept', order: 2),
      );
      expect(row.level.value, 3);
      expect(row.projectId.value, projectId);
      expect(row.fieldKey.value, 'dept');
    });

    test('an empty label comes back as the field key', () {
      const ContextLevel bare = ContextLevel(fieldKey: 'district', order: 0);
      final ContextState state = ContextMapper.fromRows(
        definitions: <sqlite.ContextData>[definition(bare)],
        states: const <sqlite.ContextStateRow>[],
        pinned: const <String, String>{},
      );
      expect(state.levels.single.label, 'district');
      expect(state.levels.single.datasetId, isNull);
    });

    test('a label that is not JSON is kept as written', () {
      final sqlite.ContextData odd = sqlite.ContextData(
        id: 'def-odd',
        createdAt: at,
        updatedAt: at,
        updatedByDevice: 'device-a',
        rev: 1,
        projectId: projectId,
        level: 1,
        fieldKey: 'district',
        label: '{not json',
      );
      final ContextState state = ContextMapper.fromRows(
        definitions: <sqlite.ContextData>[odd],
        states: const <sqlite.ContextStateRow>[],
        pinned: const <String, String>{},
      );
      expect(state.levels.single.label, '{not json');
      expect(state.levels.single.datasetId, isNull);
    });

    test(
      'definitions inserted into a database read back as the same levels',
      () async {
        final sqlite.AppDatabase db = sqlite.AppDatabase.memory();
        addTearDown(db.close);
        const List<ContextLevel> levels = <ContextLevel>[
          ContextLevel(fieldKey: 'district', order: 0, label: 'District'),
          ContextLevel(
            fieldKey: 'facility',
            order: 1,
            label: 'Facility',
            datasetId: 'ds-1',
          ),
          ContextLevel(fieldKey: 'dept', order: 2, label: 'Department'),
        ];
        for (final ContextLevel level in levels.reversed) {
          await db
              .into(db.context)
              .insert(
                ContextMapper.definitionToRow(
                  projectId: projectId,
                  level: level,
                ).copyWith(
                  createdAt: Value<DateTime>(at),
                  updatedAt: Value<DateTime>(at),
                  updatedByDevice: const Value<String>('device-a'),
                ),
              );
        }
        final List<sqlite.ContextData> rows =
            await (db.select(db.context)..where(
                  (sqlite.$ContextTable tbl) => tbl.projectId.equals(projectId),
                ))
                .get();
        final ContextState state = ContextMapper.fromRows(
          definitions: rows,
          states: const <sqlite.ContextStateRow>[],
          pinned: const <String, String>{},
        );
        expect(state.levels, levels);
      },
    );
  });

  group('ContextState', () {
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
      pinned: <String, String>{'surveyor': 'Sam', 'survey_date': '2026-09-22'},
    );

    test('round-trips through definition, value and pin rows', () {
      final List<sqlite.ContextStateRow> states = <sqlite.ContextStateRow>[
        pinRow(three.pinned),
        for (final ContextLevel level in three.levels)
          stateRow(
            level: level.order + 1,
            fieldKey: level.fieldKey,
            value: three.values[level.fieldKey]!,
          ),
      ];
      final ContextState back = ContextMapper.fromRows(
        definitions: <sqlite.ContextData>[
          for (final ContextLevel level in three.levels) definition(level),
        ],
        states: states,
        pinned: ContextMapper.pinsFromStateRows(states),
      );
      expect(back, equals(three));
    });

    test('levels come back in hierarchy order whatever the row order', () {
      final ContextState back = ContextMapper.fromRows(
        definitions: <sqlite.ContextData>[
          for (final ContextLevel level in three.levels.reversed)
            definition(level),
        ],
        states: const <sqlite.ContextStateRow>[],
        pinned: const <String, String>{},
      );
      expect(back.levels, three.levels);
    });

    test('the pin row is never read as a level value', () {
      final List<sqlite.ContextStateRow> states = <sqlite.ContextStateRow>[
        pinRow(<String, String>{'surveyor': 'Sam'}),
      ];
      final ContextState back = ContextMapper.fromRows(
        definitions: <sqlite.ContextData>[
          for (final ContextLevel level in three.levels) definition(level),
        ],
        states: states,
        pinned: ContextMapper.pinsFromStateRows(states),
      );
      expect(back.values, isEmpty);
      expect(back.pinned, <String, String>{'surveyor': 'Sam'});
    });

    test('a value row with no field key is matched by its level number', () {
      final List<sqlite.ContextStateRow> states = <sqlite.ContextStateRow>[
        stateRow(level: 2, fieldKey: '', value: 'Kasubi HC IV'),
      ];
      final ContextState back = ContextMapper.fromRows(
        definitions: <sqlite.ContextData>[
          for (final ContextLevel level in three.levels) definition(level),
        ],
        states: states,
        pinned: const <String, String>{},
      );
      expect(back.values, <String, String>{'facility': 'Kasubi HC IV'});
    });

    test('no pin row means no pins', () {
      expect(
        ContextMapper.pinsFromStateRows(<sqlite.ContextStateRow>[
          stateRow(level: 1, fieldKey: 'district', value: 'Kampala'),
        ]),
        isEmpty,
      );
    });

    test('a pin row that is not JSON yields no pins rather than throwing', () {
      expect(
        ContextMapper.pinsFromStateRows(<sqlite.ContextStateRow>[
          stateRow(level: 0, fieldKey: '', value: '{broken'),
        ]),
        isEmpty,
      );
    });

    test('no rows at all is the empty context', () {
      final ContextState back = ContextMapper.fromRows(
        definitions: const <sqlite.ContextData>[],
        states: const <sqlite.ContextStateRow>[],
        pinned: const <String, String>{},
      );
      expect(back, equals(const ContextState()));
      expect(back.isEmpty, isTrue);
    });
  });

  group('ContextPreset', () {
    const ContextPreset preset = ContextPreset(
      id: 'pre-1',
      name: 'Theatre',
      values: <String, String>{
        'district': 'Kampala',
        'facility': 'Kasubi HC IV',
      },
      pinned: <String, String>{'surveyor': 'Sam'},
    );

    test('round-trips through its values column', () {
      final ContextPreset back = ContextMapper.presetFromRow(
        presetRow(
          ContextMapper.encodePresetPayload(
            values: preset.values,
            pinned: preset.pinned,
          ),
        ),
      );
      expect(back, equals(preset));
      expect(back.values, preset.values);
      expect(back.pinned, preset.pinned);
      expect(back.lastUsedAt, at);
    });

    test('a legacy flat payload becomes values with no pins', () {
      final ContextPreset back = ContextMapper.presetFromRow(
        presetRow(jsonEncode(<String, String>{'district': 'Kampala'})),
      );
      expect(back.values, <String, String>{'district': 'Kampala'});
      expect(back.pinned, isEmpty);
    });

    test('a payload with pins only leaves the values empty', () {
      final ContextPreset back = ContextMapper.presetFromRow(
        presetRow(
          ContextMapper.encodePresetPayload(
            values: const <String, String>{},
            pinned: const <String, String>{'surveyor': 'Sam'},
          ),
        ),
      );
      expect(back.values, isEmpty);
      expect(back.pinned, <String, String>{'surveyor': 'Sam'});
    });

    test('a payload that is not JSON yields an empty preset', () {
      final ContextPreset back = ContextMapper.presetFromRow(
        presetRow('{broken', name: 'Odd'),
      );
      expect(back.name, 'Odd');
      expect(back.values, isEmpty);
      expect(back.pinned, isEmpty);
    });

    test('non-string entries are stringified and non-string keys dropped', () {
      final ContextPreset back = ContextMapper.presetFromRow(
        presetRow('{"values":{"count":3,"empty":null},"pinned":[]}'),
      );
      expect(back.values, <String, String>{'count': '3', 'empty': ''});
      expect(back.pinned, isEmpty);
    });
  });
}
