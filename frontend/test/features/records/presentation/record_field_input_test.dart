import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';
import 'package:tapture/core/widgets/fields/field_editor.dart';
import 'package:tapture/core/widgets/fields/field_value.dart';
import 'package:tapture/features/records/domain/domain.dart';
import 'package:tapture/features/records/presentation/record_field_input.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';

const List<FieldDef> _fields = <FieldDef>[
  FieldDef(
    fieldKey: 'notes',
    label: 'Notes',
    type: FieldType.longText,
    sortOrder: 3,
  ),
  FieldDef(
    fieldKey: 'asset_tag',
    label: 'Asset tag',
    type: FieldType.text,
    sortOrder: 1,
  ),
  FieldDef(fieldKey: 'unlabelled', label: '', type: FieldType.text),
  FieldDef(
    fieldKey: 'record_uid',
    label: 'Record id',
    type: FieldType.text,
    inputMode: InputMode.auto,
  ),
  FieldDef(
    fieldKey: 'secret',
    label: 'Hidden',
    type: FieldType.text,
    hidden: true,
  ),
  FieldDef(fieldKey: 'total', label: 'Total', type: FieldType.computed),
  FieldDef(
    fieldKey: 'model',
    label: 'Model',
    type: FieldType.text,
    sortOrder: 1,
  ),
];

final TemplateDef _template = aTemplate(fields: _fields);

RecordEntry _record(List<RecordValue> values) {
  return aRecordEntry(id: 'r1').copyWith(values: values);
}

void main() {
  group('editorValueOf and storedTextOf', () {
    test('empty text is no value, and no value is empty text', () {
      for (final FieldType type in FieldType.values) {
        expect(editorValueOf(type, ''), isNull, reason: type.name);
        expect(storedTextOf(type, null), '', reason: type.name);
      }
    });

    test('numbers read as numbers, and unreadable text stays text', () {
      expect(editorValueOf(FieldType.number, '2'), 2);
      expect(editorValueOf(FieldType.decimal, '2.5'), 2.5);
      expect(editorValueOf(FieldType.currency, '10.25'), 10.25);
      expect(editorValueOf(FieldType.percentage, '40'), 40);
      expect(editorValueOf(FieldType.number, 'many'), 'many');
      expect(storedTextOf(FieldType.number, 3), '3');
      expect(storedTextOf(FieldType.decimal, 2.5), '2.5');
    });

    test('dates are stored as yyyy-MM-dd and times as HH:mm', () {
      expect(
        editorValueOf(FieldType.date, '2026-09-20'),
        DateTime(2026, 9, 20),
      );
      expect(
        editorValueOf(FieldType.time, '09:30'),
        DateTime(2000, 1, 1, 9, 30),
      );
      expect(editorValueOf(FieldType.time, 'soon'), 'soon');
      expect(editorValueOf(FieldType.date, 'someday'), 'someday');
      expect(
        storedTextOf(FieldType.date, DateTime(2026, 9, 20, 14)),
        '2026-09-20',
      );
      expect(
        storedTextOf(FieldType.time, DateTime(2026, 9, 20, 9, 5)),
        '09:05',
      );
      expect(
        storedTextOf(FieldType.dateTime, DateTime(2026, 9, 20, 9, 5)),
        DateTime(2026, 9, 20, 9, 5).toIso8601String(),
      );
    });

    test('a toggle is true only for the text true', () {
      expect(editorValueOf(FieldType.boolean, 'true'), isTrue);
      expect(editorValueOf(FieldType.boolean, 'false'), isFalse);
      expect(editorValueOf(FieldType.boolean, 'yes'), isFalse);
      expect(storedTextOf(FieldType.boolean, true), 'true');
    });

    test('several choices are joined by commas and read back apart', () {
      expect(
        editorValueOf(FieldType.multiChoice, 'Red, Blue, , Green'),
        <String>['Red', 'Blue', 'Green'],
      );
      expect(
        storedTextOf(FieldType.multiChoice, <String>['Red', 'Blue']),
        'Red, Blue',
      );
    });

    test('every type round-trips its stored text', () {
      const Map<FieldType, String> samples = <FieldType, String>{
        FieldType.text: 'A-17',
        FieldType.longText: 'Leaking at the valve',
        FieldType.number: '3',
        FieldType.decimal: '2.5',
        FieldType.date: '2026-09-20',
        FieldType.time: '09:30',
        FieldType.boolean: 'true',
        FieldType.choice: 'Good',
        FieldType.multiChoice: 'Red, Blue',
        FieldType.barcode: '5012345678900',
      };
      for (final MapEntry<FieldType, String> sample in samples.entries) {
        expect(
          storedTextOf(sample.key, editorValueOf(sample.key, sample.value)),
          sample.value,
          reason: sample.key.name,
        );
      }
    });
  });

  group('recordEditEntries', () {
    test('lists the live, person-entered fields in template order', () {
      final List<RecordEditEntry> entries = recordEditEntries(
        template: _template,
        record: _record(const <RecordValue>[]),
      );

      expect(
        <String>[for (final RecordEditEntry entry in entries) entry.fieldKey],
        <String>['unlabelled', 'asset_tag', 'model', 'notes'],
      );
      expect(entries.first.label, 'unlabelled');
      expect(entries[1].label, 'Asset tag');
      expect(entries.every((RecordEditEntry entry) => !entry.stored), isTrue);
      expect(
        entries.every((RecordEditEntry entry) => entry.initial.isEmpty),
        isTrue,
      );
    });

    test('starts each field from what the record displays for it', () {
      final List<RecordEditEntry> entries = recordEditEntries(
        template: _template,
        record: _record(const <RecordValue>[
          RecordValue(fieldKey: 'asset_tag', raw: 'A-17', refined: 'A-18'),
          RecordValue(fieldKey: 'model', raw: 'X', refined: 'Y', approved: 'Z'),
          RecordValue(fieldKey: 'notes', raw: 'Kept'),
        ]),
      );
      final Map<String, RecordEditEntry> byKey = <String, RecordEditEntry>{
        for (final RecordEditEntry entry in entries) entry.fieldKey: entry,
      };

      expect(byKey['asset_tag']!.initial, 'A-18');
      expect(byKey['model']!.initial, 'Z');
      expect(byKey['notes']!.initial, 'Kept');
      expect(byKey['notes']!.stored, isTrue);
      expect(byKey['notes']!.value?.raw, 'Kept');
      expect(byKey['unlabelled']!.stored, isFalse);
    });

    test('leaves out a retired value and every field without a template', () {
      final RecordEntry record = _record(const <RecordValue>[
        RecordValue(fieldKey: 'notes', raw: 'Old', retired: true),
      ]);

      expect(<String>[
        for (final RecordEditEntry entry in recordEditEntries(
          template: _template,
          record: record,
        ))
          entry.fieldKey,
      ], isNot(contains('notes')));
      expect(recordEditEntries(template: null, record: record), isEmpty);
    });
  });

  group('recordRetiredValues', () {
    test('keeps flagged values and those the template does not declare', () {
      final RecordEntry record = _record(const <RecordValue>[
        RecordValue(fieldKey: 'asset_tag', raw: 'A-17'),
        RecordValue(fieldKey: 'notes', raw: 'Old', retired: true),
        RecordValue(fieldKey: 'legacy', raw: 'Kept'),
      ]);

      expect(
        <String>[
          for (final RecordValue value in recordRetiredValues(
            template: _template,
            record: record,
          ))
            value.fieldKey,
        ],
        <String>['notes', 'legacy'],
      );
      expect(
        recordRetiredValues(template: null, record: record),
        record.values,
      );
    });
  });

  group('recordFieldChanged', () {
    final RecordEditEntry empty = recordEditEntries(
      template: _template,
      record: _record(const <RecordValue>[]),
    ).firstWhere((RecordEditEntry entry) => entry.fieldKey == 'asset_tag');
    final RecordEditEntry stored = recordEditEntries(
      template: _template,
      record: _record(const <RecordValue>[
        RecordValue(fieldKey: 'asset_tag', raw: 'A-17'),
      ]),
    ).firstWhere((RecordEditEntry entry) => entry.fieldKey == 'asset_tag');

    test('blank text on an empty field is no change', () {
      expect(recordFieldChanged(empty, '   '), isFalse);
      expect(recordFieldChanged(empty, 'A-1'), isTrue);
    });

    test('a stored value changes only when the text differs', () {
      expect(recordFieldChanged(stored, 'A-17'), isFalse);
      expect(recordFieldChanged(stored, 'A-18'), isTrue);
      expect(recordFieldChanged(stored, ''), isTrue);
    });
  });

  group('RecordFieldInput', () {
    testWidgets('a context-sourced business value requires explicit correction '
        'even when its template mode permits ordinary manual input', (
      WidgetTester tester,
    ) async {
      final RecordEditEntry entry = recordEditEntries(
        template: aTemplate(
          fields: const <FieldDef>[
            FieldDef(
              fieldKey: 'room',
              label: 'Room',
              type: FieldType.text,
              stickable: true,
            ),
          ],
        ),
        record: _record(const <RecordValue>[
          RecordValue(fieldKey: 'room', raw: 'Workshop', source: 'CONTEXT'),
        ]),
      ).single;
      final List<String> typed = <String>[];
      await _pumpInput(tester, entry, text: 'Workshop', typed: typed);
      expect(find.byType(FieldEditor), findsNothing);
      await tester.tap(
        find.byKey(const ValueKey<String>('record-field-correct-room')),
      );
      await tester.pump();
      expect(_valueShown(tester, 'room').source, ValueSource.context);
      expect(typed, isEmpty);
    });

    for (final ({FieldDef field, String raw}) sample
        in <({FieldDef field, String raw})>[
          (
            field: const FieldDef(
              fieldKey: 'model',
              label: 'Model',
              type: FieldType.text,
              inputMode: InputMode.auto,
              autoFill: AutoFill.context,
            ),
            raw: 'Pump',
          ),
          (
            field: const FieldDef(
              fieldKey: 'captured_date',
              label: 'Captured date',
              type: FieldType.date,
              inputMode: InputMode.auto,
              autoFill: AutoFill.today,
            ),
            raw: '2026-09-20',
          ),
          (
            field: const FieldDef(
              fieldKey: 'captured_time',
              label: 'Captured time',
              type: FieldType.time,
              inputMode: InputMode.auto,
              autoFill: AutoFill.time,
            ),
            raw: '09:30',
          ),
        ]) {
      testWidgets('${sample.field.fieldKey} requires explicit correction and '
          'opening the editor does not change its automatic source', (
        WidgetTester tester,
      ) async {
        final RecordEditEntry entry = recordEditEntries(
          template: aTemplate(fields: <FieldDef>[sample.field]),
          record: _record(<RecordValue>[
            RecordValue(
              fieldKey: sample.field.fieldKey,
              raw: sample.raw,
              source: 'AUTO',
            ),
          ]),
        ).single;
        final List<String> typed = <String>[];
        await _pumpInput(tester, entry, text: sample.raw, typed: typed);
        expect(find.byType(FieldEditor), findsNothing);
        final Finder correct = find.byKey(
          ValueKey<String>('record-field-correct-${sample.field.fieldKey}'),
        );
        expect(correct, findsOneWidget);
        expect(find.text(Copy.recordCorrectAutomaticValue), findsOneWidget);
        await tester.tap(correct);
        await tester.pump();
        expect(
          _valueShown(tester, sample.field.fieldKey).source,
          ValueSource.auto,
        );
        expect(typed, isEmpty);
        expect(entry.value!.raw, sample.raw);
        if (sample.field.type == FieldType.text) {
          await tester.enterText(find.byType(TextField), 'Boiler');
          await tester.pump();
          expect(typed, <String>['Boiler']);
          await _pumpInput(tester, entry, text: 'Boiler', typed: typed);
          expect(
            _valueShown(tester, sample.field.fieldKey).source,
            ValueSource.manual,
          );
          expect(entry.value!.raw, 'Pump');
        }
      });
    }

    testWidgets('an untouched value keeps its own source; a typed one is '
        'manual', (WidgetTester tester) async {
      final RecordEditEntry entry = recordEditEntries(
        template: _template,
        record: _record(const <RecordValue>[
          RecordValue(
            fieldKey: 'asset_tag',
            raw: 'A-17',
            source: 'ocr',
            verified: true,
          ),
        ]),
      ).firstWhere((RecordEditEntry entry) => entry.fieldKey == 'asset_tag');
      final List<String> typed = <String>[];

      await _pumpInput(tester, entry, text: 'A-17', typed: typed);
      FieldValue shown = _valueShown(tester, 'asset_tag');
      expect(shown.source, ValueSource.ocr);
      expect(shown.verified, isTrue);
      expect(shown.value, 'A-17');

      await tester.enterText(find.byType(TextField), 'A-18');
      await tester.pump();
      expect(typed, <String>['A-18']);

      await _pumpInput(tester, entry, text: 'A-18', typed: typed);
      shown = _valueShown(tester, 'asset_tag');
      expect(shown.source, ValueSource.manual);
      expect(shown.verified, isFalse);
    });

    testWidgets('a field with no label is named by its key', (
      WidgetTester tester,
    ) async {
      final RecordEditEntry entry = recordEditEntries(
        template: _template,
        record: _record(const <RecordValue>[]),
      ).firstWhere((RecordEditEntry entry) => entry.fieldKey == 'unlabelled');

      await _pumpInput(tester, entry, text: '', typed: <String>[]);

      expect(find.text('unlabelled'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey<String>('record-evidence-removed-unlabelled'),
        ),
        findsNothing,
      );
    });

    testWidgets('a value whose evidence was removed carries the mark', (
      WidgetTester tester,
    ) async {
      final RecordEditEntry entry = recordEditEntries(
        template: _template,
        record: _record(const <RecordValue>[
          RecordValue(fieldKey: 'notes', raw: 'Kept', evidenceRemoved: true),
        ]),
      ).firstWhere((RecordEditEntry entry) => entry.fieldKey == 'notes');

      await _pumpInput(tester, entry, text: 'Kept', typed: <String>[]);

      expect(
        find.byKey(const ValueKey<String>('record-evidence-removed-notes')),
        findsOneWidget,
      );
      expect(find.text(Copy.recordValueEvidenceRemoved), findsOneWidget);
      expect(find.byType(FieldEditor), findsOneWidget);
    });

    testWidgets('a retired value is a read-only row with a Retired pill', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(brightness: Brightness.light),
          home: Scaffold(
            body: Column(
              children: <Widget>[
                recordRetiredValueTile(
                  const RecordValue(
                    fieldKey: 'notes',
                    raw: 'Old',
                    retired: true,
                  ),
                  template: _template,
                ),
                recordRetiredValueTile(
                  const RecordValue(fieldKey: 'legacy', raw: ''),
                ),
              ],
            ),
          ),
        ),
      );

      final AppListTile notes = tester.widget<AppListTile>(
        find.byKey(const ValueKey<String>('record-retired-notes')),
      );
      expect(notes.title, 'Notes');
      expect(notes.subtitle, 'Old');
      expect(notes.onTap, isNull);
      expect(notes.onLongPress, isNull);
      expect(notes.status?.label, Copy.recordValueRetired);
      final AppListTile legacy = tester.widget<AppListTile>(
        find.byKey(const ValueKey<String>('record-retired-legacy')),
      );
      expect(legacy.title, 'legacy');
      expect(legacy.subtitle, Copy.recordFieldEmpty);
      expect(find.byType(AppStatusPill), findsNWidgets(2));
    });
  });
}

FieldValue _valueShown(WidgetTester tester, String fieldKey) {
  return tester
      .widget<FieldEditor>(
        find.byKey(ValueKey<String>('record-field-input-$fieldKey')),
      )
      .value;
}

Future<void> _pumpInput(
  WidgetTester tester,
  RecordEditEntry entry, {
  required String text,
  required List<String> typed,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        fieldEditorBindingsProvider.overrideWithValue(
          templateFieldEditorBindings,
        ),
      ],
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: Scaffold(
          body: RecordFieldInput(
            entry: entry,
            text: text,
            onChanged: typed.add,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
