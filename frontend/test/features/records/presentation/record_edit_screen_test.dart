import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/fields/field_editor.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/records/domain/domain.dart';
import 'package:tapture/features/records/presentation/record_edit_controller.dart';
import 'package:tapture/features/records/presentation/record_edit_screen.dart';
import 'package:tapture/features/records/presentation/record_providers.dart';
import 'package:tapture/features/records/records.dart'
    show recordRepositoryProvider;
import 'package:tapture/features/templates/templates.dart';

import '../../../support/a11y_matchers.dart';
import '../../../support/factories.dart';
import '../../templates/fakes/fake_template_repository.dart';
import '../fakes/fake_record_repository.dart';

const List<FieldDef> _fields = <FieldDef>[
  FieldDef(
    fieldKey: 'record_uid',
    label: 'Record id',
    type: FieldType.text,
    inputMode: InputMode.auto,
  ),
  FieldDef(
    fieldKey: 'asset_tag',
    label: 'Asset tag',
    type: FieldType.text,
    sortOrder: 1,
  ),
  FieldDef(
    fieldKey: 'secret',
    label: 'Hidden field',
    type: FieldType.text,
    hidden: true,
    sortOrder: 2,
  ),
  FieldDef(
    fieldKey: 'total',
    label: 'Total',
    type: FieldType.computed,
    sortOrder: 3,
  ),
  FieldDef(
    fieldKey: 'quantity',
    label: 'Quantity',
    type: FieldType.number,
    sortOrder: 4,
  ),
  FieldDef(
    fieldKey: 'visited_on',
    label: 'Visited on',
    type: FieldType.date,
    sortOrder: 5,
  ),
  FieldDef(
    fieldKey: 'condition',
    label: 'Condition',
    type: FieldType.choice,
    options: <Object>['Good', 'Faulty'],
    sortOrder: 6,
  ),
  FieldDef(
    fieldKey: 'working',
    label: 'Working',
    type: FieldType.boolean,
    sortOrder: 7,
  ),
  FieldDef(
    fieldKey: 'notes',
    label: 'Notes',
    type: FieldType.longText,
    sortOrder: 8,
  ),
  FieldDef(
    fieldKey: 'serial',
    label: 'Serial',
    type: FieldType.text,
    validation: <String, Object?>{'maxLength': 6},
    sortOrder: 9,
  ),
];

const StorageFailure _full = StorageFailure(
  message: 'The device storage is full.',
  recoveryAction: 'Free some space and try again.',
);

/// A record named apart from its values, so a value is found once.
RecordEntry _record({
  RecordStatus status = RecordStatus.captured,
  Map<String, String>? fields,
  String templateId = 'template-1',
}) {
  return aRecordEntry(
    id: 'r1',
    name: 'Boiler 3',
    status: status,
    templateId: templateId,
    fields:
        fields ??
        const <String, String>{
          'asset_tag': 'A-17',
          'quantity': '2',
          'visited_on': '2026-09-20',
          'condition': 'Faulty',
        },
  );
}

void main() {
  group('states', () {
    testWidgets('while the record loads the page shows a skeleton', (
      WidgetTester tester,
    ) async {
      final StreamController<RecordEntry?> pending =
          StreamController<RecordEntry?>();
      addTearDown(pending.close);
      await _pump(
        tester,
        record: null,
        overrides: <Override>[
          recordEntryProvider.overrideWith((Ref _, String _) => pending.stream),
        ],
      );

      expect(find.byType(AppSkeleton), findsOneWidget);
      expect(find.byType(AppPrimaryAction), findsNothing);
    });

    testWidgets('while the template loads the page shows a skeleton', (
      WidgetTester tester,
    ) async {
      final Completer<TemplateDef?> pending = Completer<TemplateDef?>();
      await _pump(
        tester,
        record: _record(),
        overrides: <Override>[
          recordEditTemplateProvider.overrideWith(
            (Ref _, String _) => pending.future,
          ),
        ],
      );

      expect(find.byType(AppSkeleton), findsOneWidget);
      expect(find.byType(AppPrimaryAction), findsNothing);
      pending.complete(aTemplate(fields: _fields));
      await tester.pumpAndSettle();
      expect(find.byType(AppPrimaryAction), findsOneWidget);
    });

    testWidgets('a record that is not on this device says so', (
      WidgetTester tester,
    ) async {
      await _pump(tester, record: null);

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text(Copy.recordGoneHeadline), findsOneWidget);
      expect(find.byType(AppPrimaryAction), findsNothing);
    });

    testWidgets('a record in the recycle bin cannot be edited', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _pump(tester, record: null);
      harness.records.seedDeleted(_record());
      await tester.pumpAndSettle();

      expect(find.text(Copy.recordEditDeletedHeadline), findsOneWidget);
      expect(find.text(Copy.recordEditDeletedMessage), findsOneWidget);
      expect(find.byType(FieldEditor), findsNothing);
      expect(find.byType(AppPrimaryAction), findsNothing);
    });

    testWidgets('a record with nothing to edit says so', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        record: _record(fields: const <String, String>{}),
        fields: const <FieldDef>[],
      );

      expect(find.text(Copy.recordEditNoFieldsHeadline), findsOneWidget);
      expect(find.text(Copy.recordEditNoFieldsMessage), findsOneWidget);
      expect(find.byType(AppPrimaryAction), findsNothing);
    });

    testWidgets('a store that cannot read the record shows why, and retries', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _pump(
        tester,
        record: _record(),
        readFailure: _full,
      );

      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.text(_full.message), findsOneWidget);
      expect(find.byType(AppPrimaryAction), findsNothing);

      harness.records.readFailure = null;
      await tester.tap(find.text(Copy.tryAgain));
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorState), findsNothing);
      expect(_textOf(tester, 'Asset tag'), 'A-17');
    });

    testWidgets('a template that cannot be read shows why', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        record: _record(),
        overrides: <Override>[
          recordEditTemplateProvider.overrideWith(
            (Ref _, String _) async => throw _full,
          ),
        ],
      );

      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.text(_full.message), findsOneWidget);
      expect(find.byType(AppPrimaryAction), findsNothing);
    });

    testWidgets('a record whose template is gone keeps its values read-only', (
      WidgetTester tester,
    ) async {
      await _pump(tester, record: _record(templateId: 'removed-template'));

      expect(
        find.byKey(const ValueKey<String>('record-edit-template-missing')),
        findsOneWidget,
      );
      expect(find.byType(FieldEditor), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('record-retired-asset_tag')),
        findsOneWidget,
      );
      expect(find.text('A-17'), findsOneWidget);
    });
  });

  group('typed inputs', () {
    testWidgets('each live field gets the input its type names, holding its '
        'value', (WidgetTester tester) async {
      await _pump(tester, record: _record());

      for (final String key in <String>[
        'field-editor-text-asset_tag',
        'field-editor-number-quantity',
        'field-editor-date-visited_on',
        'field-editor-choice-condition',
        'field-editor-toggle-working',
        'field-editor-text-notes',
        'field-editor-text-serial',
      ]) {
        expect(find.byKey(ValueKey<String>(key)), findsOneWidget, reason: key);
      }
      expect(_textOf(tester, 'Asset tag'), 'A-17');
      expect(_textOf(tester, 'Quantity'), '2');
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('field-editor-choice-condition'),
          ),
          matching: find.text('Faulty'),
        ),
        findsOneWidget,
      );
      final double tag = tester
          .getTopLeft(
            find.byKey(const ValueKey<String>('record-field-input-asset_tag')),
          )
          .dy;
      final double quantity = tester
          .getTopLeft(
            find.byKey(const ValueKey<String>('record-field-input-quantity')),
          )
          .dy;
      expect(tag, lessThan(quantity));
    });

    testWidgets('automatic, hidden and computed fields are not offered', (
      WidgetTester tester,
    ) async {
      await _pump(tester, record: _record());

      expect(find.text('Record id'), findsNothing);
      expect(find.text('Hidden field'), findsNothing);
      expect(find.text('Total'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('record-field-input-record_uid')),
        findsNothing,
      );
    });

    testWidgets('a picked choice and a switched toggle are saved as text', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _pump(tester, record: _record());

      final Finder choice = find.byKey(
        const ValueKey<String>('field-editor-choice-condition'),
      );
      await tester.ensureVisible(choice);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: choice, matching: find.text('Good')),
      );
      await tester.pumpAndSettle();
      final Finder toggle = find.byKey(
        const ValueKey<String>('field-editor-toggle-working'),
      );
      await tester.ensureVisible(toggle);
      await tester.pumpAndSettle();
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      await _saveAndSettle(tester);

      final RecordEntry saved = harness.records.entryOf('r1')!;
      expect(saved.valueOf('condition')!.display, 'Good');
      expect(saved.valueOf('condition')!.raw, 'Faulty');
      expect(saved.valueOf('working')!.display, 'true');
    });
  });

  group('save', () {
    testWidgets('sends only the fields that changed, in one write', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _pump(tester, record: _record());

      await tester.enterText(_field('Asset tag'), 'A-18');
      await tester.enterText(_field('Quantity'), '3');
      await tester.pump();
      await _saveAndSettle(tester);

      expect(harness.records.writes, <({String method, String id})>[
        (method: 'editValues', id: 'r1'),
      ]);
      final List<RecordHistoryEvent> edits = <RecordHistoryEvent>[
        for (final RecordHistoryEvent event in harness.records.historyOf('r1'))
          if (event.kind == RecordHistoryKind.valueChanged) event,
      ];
      expect(
        <(String?, String?, String?)>[
          for (final RecordHistoryEvent event in edits)
            (event.fieldKey, event.previous, event.next),
        ],
        <(String?, String?, String?)>[
          ('asset_tag', 'A-17', 'A-18'),
          ('quantity', '2', '3'),
        ],
      );
      final RecordEntry saved = harness.records.entryOf('r1')!;
      expect(saved.valueOf('asset_tag')!.raw, 'A-17');
      expect(saved.valueOf('asset_tag')!.display, 'A-18');
      expect(saved.valueOf('condition')!.refined, isNull);
      expect(saved.valueOf('visited_on')!.refined, isNull);
      expect(saved.status, RecordStatus.captured);
      expect(find.byType(RecordEditScreen), findsNothing);
      expect(find.text(Copy.recordValuesSaved(2)), findsOneWidget);
    });

    testWidgets('a value typed into an empty field is added', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _pump(tester, record: _record());

      final Finder notes = _field('Notes');
      await tester.ensureVisible(notes);
      await tester.enterText(notes, 'Leaking at the valve');
      await tester.pump();
      await _saveAndSettle(tester);

      final RecordValue added = harness.records
          .entryOf('r1')!
          .valueOf('notes')!;
      expect(added.raw, 'Leaking at the valve');
      expect(added.verified, isTrue);
    });

    testWidgets('saving an approved record says so first and returns it to '
        'review', (WidgetTester tester) async {
      final _Harness harness = await _pump(
        tester,
        record: _record(status: RecordStatus.approved),
      );

      expect(
        find.widgetWithText(AppBanner, Copy.recordEditApprovedNotice),
        findsOneWidget,
      );
      await tester.enterText(_field('Asset tag'), 'A-18');
      await tester.pump();
      await _saveAndSettle(tester);

      expect(harness.records.entryOf('r1')!.status, RecordStatus.needsReview);
      final List<RecordHistoryEvent> history = harness.records.historyOf('r1');
      final RecordHistoryEvent edit = history.firstWhere(
        (RecordHistoryEvent event) =>
            event.kind == RecordHistoryKind.valueChanged,
      );
      expect(
        (edit.fieldKey, edit.previous, edit.next),
        ('asset_tag', 'A-17', 'A-18'),
      );
      final RecordHistoryEvent status = history.firstWhere(
        (RecordHistoryEvent event) =>
            event.kind == RecordHistoryKind.statusChanged,
      );
      expect(
        (status.previous, status.next),
        (RecordStatus.approved.stored, RecordStatus.needsReview.stored),
      );
      expect(
        find.text(Copy.recordValuesSaved(1, backToReview: true)),
        findsOneWidget,
      );
    });

    testWidgets('a record that is not approved carries no review notice', (
      WidgetTester tester,
    ) async {
      await _pump(tester, record: _record(status: RecordStatus.needsReview));

      expect(
        find.byKey(const ValueKey<String>('record-edit-approved')),
        findsNothing,
      );
    });

    testWidgets('Save with nothing changed goes back without writing', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _pump(tester, record: _record());

      await _saveAndSettle(tester);

      expect(harness.records.writes, isEmpty);
      expect(find.byType(RecordEditScreen), findsNothing);
      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('a failed save keeps what was typed and shows why', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _pump(tester, record: _record());
      harness.records.writeFailure = _full;

      await tester.enterText(_field('Asset tag'), 'A-18');
      await tester.pump();
      await _saveAndSettle(tester);

      expect(find.byType(RecordEditScreen), findsOneWidget);
      expect(
        find.widgetWithText(
          AppBanner,
          '${_full.message} ${_full.recoveryAction}',
        ),
        findsOneWidget,
      );
      expect(_textOf(tester, 'Asset tag'), 'A-18');
      expect(
        harness.records.entryOf('r1')!.valueOf('asset_tag')!.display,
        'A-17',
      );
      expect(harness.records.writes, isEmpty);

      harness.records.writeFailure = null;
      await _saveAndSettle(tester);

      expect(find.byType(RecordEditScreen), findsNothing);
      expect(
        harness.records.entryOf('r1')!.valueOf('asset_tag')!.display,
        'A-18',
      );
    });

    testWidgets('a value its type refuses is not saved, the form names the '
        'field, and the line goes once it is corrected', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _pump(tester, record: _record());

      final Finder serial = _field('Serial');
      await tester.ensureVisible(serial);
      await tester.enterText(serial, 'SERIAL-0042');
      await tester.pump();
      await _saveAndSettle(tester);

      expect(find.byType(RecordEditScreen), findsOneWidget);
      final Finder problem = find.text(
        Copy.fieldError(
          'Serial',
          'That value is longer than this field allows.',
        ),
      );
      expect(problem, findsOneWidget);
      expect(find.text(Copy.fixFields(1)), findsOneWidget);
      expect(harness.records.writes, isEmpty);

      await tester.enterText(_field('Serial'), 'S-42');
      await tester.pump();

      expect(problem, findsNothing);
      await _saveAndSettle(tester);
      expect(find.byType(RecordEditScreen), findsNothing);
      expect(harness.records.entryOf('r1')!.valueOf('serial')!.display, 'S-42');
    });

    testWidgets('a saved value is never emptied', (WidgetTester tester) async {
      final _Harness harness = await _pump(tester, record: _record());

      await tester.enterText(_field('Asset tag'), '');
      await tester.pump();
      await _saveAndSettle(tester);

      expect(
        find.text(Copy.fieldError('Asset tag', Copy.recordValueCannotEmpty)),
        findsOneWidget,
      );
      expect(harness.records.writes, isEmpty);
      expect(
        harness.records.entryOf('r1')!.valueOf('asset_tag')!.display,
        'A-17',
      );
    });
  });

  group('retired and flagged values', () {
    testWidgets('retired values are read-only, marked Retired and never sent', (
      WidgetTester tester,
    ) async {
      final RecordEntry record = _record();
      final _Harness harness = await _pump(
        tester,
        record: record.copyWith(
          values: <RecordValue>[
            ...record.values,
            const RecordValue(fieldKey: 'old_code', raw: 'X-1', retired: true),
            const RecordValue(fieldKey: 'legacy_note', raw: 'Kept'),
            const RecordValue(
              fieldKey: 'notes',
              raw: 'Old note',
              retired: true,
            ),
          ],
        ),
      );

      expect(find.text(Copy.recordRetiredValuesTitle), findsOneWidget);
      for (final String key in <String>['old_code', 'legacy_note', 'notes']) {
        final Finder row = find.byKey(ValueKey<String>('record-retired-$key'));
        expect(row, findsOneWidget, reason: key);
        expect(tester.widget<AppListTile>(row).onTap, isNull);
        expect(
          find.byKey(ValueKey<String>('record-field-input-$key')),
          findsNothing,
          reason: key,
        );
      }
      expect(find.text(Copy.recordValueRetired), findsNWidgets(3));
      // A retired value the template declares keeps its label; the others
      // are named by their key.
      expect(
        tester
            .widget<AppListTile>(
              find.byKey(const ValueKey<String>('record-retired-notes')),
            )
            .title,
        'Notes',
      );
      expect(
        tester
            .widget<AppListTile>(
              find.byKey(const ValueKey<String>('record-retired-old_code')),
            )
            .title,
        'old_code',
      );

      final Finder legacy = find.byKey(
        const ValueKey<String>('record-retired-legacy_note'),
      );
      await tester.ensureVisible(legacy);
      await tester.pumpAndSettle();
      await tester.tap(legacy);
      await tester.pumpAndSettle();
      await tester.enterText(_field('Asset tag'), 'A-18');
      await tester.pump();
      await _saveAndSettle(tester);

      final RecordEntry saved = harness.records.entryOf('r1')!;
      expect(saved.valueOf('old_code')!.display, 'X-1');
      expect(saved.valueOf('legacy_note')!.display, 'Kept');
      expect(saved.valueOf('notes')!.display, 'Old note');
      expect(
        <String?>[
          for (final RecordHistoryEvent event in harness.records.historyOf(
            'r1',
          ))
            event.fieldKey,
        ],
        <String?>['asset_tag'],
      );
    });

    testWidgets('a value whose evidence was removed is marked and kept', (
      WidgetTester tester,
    ) async {
      final RecordEntry record = _record();
      await _pump(
        tester,
        record: record.copyWith(
          values: <RecordValue>[
            for (final RecordValue value in record.values)
              value.fieldKey == 'condition'
                  ? value.copyWith(evidenceRemoved: true)
                  : value,
          ],
        ),
      );

      final Finder mark = find.byKey(
        const ValueKey<String>('record-evidence-removed-condition'),
      );
      expect(mark, findsOneWidget);
      expect(find.text(Copy.recordValueEvidenceRemoved), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('field-editor-choice-condition')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('record-evidence-removed-asset_tag')),
        findsNothing,
      );
    });
  });

  group('leaving', () {
    testWidgets('leaving with unsaved changes asks first', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _pump(tester, record: _record());

      await tester.enterText(_field('Asset tag'), 'A-18');
      await tester.pump();
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.text(Copy.discardChangesTitle), findsOneWidget);
      await tester.tap(find.text(Copy.cancel));
      await tester.pumpAndSettle();
      expect(find.byType(RecordEditScreen), findsOneWidget);
      expect(_textOf(tester, 'Asset tag'), 'A-18');

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Copy.discard));
      await tester.pumpAndSettle();

      expect(find.byType(RecordEditScreen), findsNothing);
      expect(harness.records.writes, isEmpty);
    });

    testWidgets('leaving with nothing changed does not ask', (
      WidgetTester tester,
    ) async {
      await _pump(tester, record: _record());

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.text(Copy.discardChangesTitle), findsNothing);
      expect(find.byType(RecordEditScreen), findsNothing);
    });

    testWidgets('a reopened page starts from what is stored', (
      WidgetTester tester,
    ) async {
      await _pump(tester, record: _record());

      await tester.enterText(_field('Asset tag'), 'A-18');
      await tester.pump();
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Copy.discard));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(_textOf(tester, 'Asset tag'), 'A-17');
    });
  });

  group('layout', () {
    for (final ({String name, Size size, double scale}) layout
        in <({String name, Size size, double scale})>[
          (name: '393 dp', size: const Size(393, 886), scale: 1),
          (name: '800 dp', size: const Size(800, 1000), scale: 1),
          (name: '1200 dp', size: const Size(1200, 800), scale: 1),
          (name: 'landscape', size: const Size(886, 393), scale: 1),
          (name: '200 percent text', size: const Size(393, 886), scale: 2),
        ]) {
      testWidgets('at ${layout.name} the fields fit and Save stays in reach', (
        WidgetTester tester,
      ) async {
        final RecordEntry record = _record(status: RecordStatus.approved);
        await _pump(
          tester,
          record: record.copyWith(
            values: <RecordValue>[
              ...record.values,
              const RecordValue(
                fieldKey: 'old_code',
                raw: 'X-1',
                retired: true,
              ),
            ],
          ),
          size: layout.size,
          textScale: layout.scale,
        );

        expect(tester.takeException(), isNull);
        final Rect save = tester.getRect(find.byType(AppPrimaryAction));
        expect(save.bottom, lessThanOrEqualTo(layout.size.height));
        expect(save.top, greaterThanOrEqualTo(0));
        final Finder retired = find.byKey(
          const ValueKey<String>('record-retired-old_code'),
        );
        await tester.ensureVisible(retired);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final Rect row = tester.getRect(retired);
        expect(row.bottom, lessThanOrEqualTo(save.top + 1));
      });
    }

    testWidgets('at 200 percent text in landscape the states scroll', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        record: null,
        size: const Size(886, 393),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
      expect(find.text(Copy.recordGoneHeadline), findsOneWidget);
    });
  });

  group('accessibility', () {
    testWidgets('every control is a labelled 48dp target and the marks are '
        'read out', (WidgetTester tester) async {
      final RecordEntry record = _record(status: RecordStatus.approved);
      await _pump(
        tester,
        record: record.copyWith(
          values: <RecordValue>[
            for (final RecordValue value in record.values)
              value.fieldKey == 'condition'
                  ? value.copyWith(evidenceRemoved: true)
                  : value,
            const RecordValue(fieldKey: 'old_code', raw: 'X-1', retired: true),
          ],
        ),
      );
      final SemanticsHandle handle = tester.ensureSemantics();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      expect(find.byType(AppPrimaryAction), meetsTapTarget());
      expect(
        find.byKey(const ValueKey<String>('record-evidence-removed-condition')),
        hasSemanticLabel(Copy.recordValueEvidenceRemoved),
      );
      expect(
        find.bySemanticsLabel(RegExp(Copy.recordValueRetired)),
        findsWidgets,
      );
      expect(
        find.byKey(const ValueKey<String>('record-edit-approved')),
        hasSemanticLabel(Copy.recordEditApprovedNotice),
      );
      handle.dispose();
    });
  });
}

Finder _field(String label) {
  return find.ancestor(of: find.text(label), matching: find.byType(TextField));
}

String? _textOf(WidgetTester tester, String label) {
  return tester.widget<TextField>(_field(label)).controller?.text;
}

Future<void> _saveAndSettle(WidgetTester tester) async {
  final Finder save = find.byType(AppPrimaryAction);
  await tester.ensureVisible(save);
  await tester.pumpAndSettle();
  await tester.tap(save);
  await tester.pumpAndSettle();
}

typedef _Harness = ({
  FakeRecordRepository records,
  FakeTemplateRepository templates,
});

Future<_Harness> _pump(
  WidgetTester tester, {
  required RecordEntry? record,
  List<FieldDef> fields = _fields,
  List<Override> overrides = const <Override>[],
  Failure? readFailure,
  Size size = const Size(393, 886),
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final FakeRecordRepository records = FakeRecordRepository();
  addTearDown(records.dispose);
  if (record != null) {
    records.seedEntry(record);
  }
  records.readFailure = readFailure;
  final FakeTemplateRepository templates = FakeTemplateRepository();
  addTearDown(templates.dispose);
  await templates.save(aTemplate(fields: fields));
  await tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        recordRepositoryProvider.overrideWith((Ref _) => records),
        templateRepositoryProvider.overrideWith((Ref _) => templates),
        fieldEditorBindingsProvider.overrideWithValue(
          templateFieldEditorBindings,
        ),
        ...overrides,
      ],
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (BuildContext context) {
                return AppButton(
                  label: 'Open',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext _) =>
                          const RecordEditScreen(recordId: 'r1'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return (records: records, templates: templates);
}
