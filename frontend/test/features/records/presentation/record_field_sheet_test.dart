import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/copy/l10n/app_localizations.g.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/fields/field_editor.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/records/domain/domain.dart';
import 'package:tapture/features/records/presentation/record_edit_controller.dart';
import 'package:tapture/features/records/presentation/record_field_sheet.dart';
import 'package:tapture/features/records/presentation/record_providers.dart';
import 'package:tapture/features/records/records.dart'
    show recordRepositoryProvider;
import 'package:tapture/features/templates/templates.dart';

import '../../../support/a11y_matchers.dart';
import '../../../support/factories.dart';
import '../../../support/screen_fonts.dart';
import '../../../support/screen_matrix.dart';
import '../../../support/screen_probe.dart';
import '../../templates/fakes/fake_template_repository.dart';
import '../fakes/fake_record_repository.dart';

const List<FieldDef> _fields = <FieldDef>[
  FieldDef(
    fieldKey: 'asset_tag',
    label: 'Asset tag',
    type: FieldType.text,
    sortOrder: 1,
  ),
  FieldDef(
    fieldKey: 'quantity',
    label: 'Quantity',
    type: FieldType.number,
    sortOrder: 2,
  ),
  FieldDef(
    fieldKey: 'condition',
    label: 'Condition',
    type: FieldType.choice,
    options: <Object>['Good', 'Faulty'],
    sortOrder: 3,
  ),
  FieldDef(
    fieldKey: 'working',
    label: 'Working',
    type: FieldType.boolean,
    sortOrder: 4,
  ),
  FieldDef(
    fieldKey: 'notes',
    label: 'Notes',
    type: FieldType.longText,
    sortOrder: 5,
  ),
  FieldDef(
    fieldKey: 'serial',
    label: 'Serial',
    type: FieldType.text,
    validation: <String, Object?>{'maxLength': 6},
    sortOrder: 6,
  ),
  FieldDef(
    fieldKey: 'record_uid',
    label: 'Record id',
    type: FieldType.text,
    inputMode: InputMode.auto,
    sortOrder: 7,
  ),
];

const StorageFailure _full = StorageFailure(
  message: 'The device storage is full.',
  recoveryAction: 'Free some space and try again.',
);

const FieldDef _automaticModel = FieldDef(
  fieldKey: 'model',
  label: 'Model',
  type: FieldType.text,
  inputMode: InputMode.auto,
  autoFill: AutoFill.context,
);
const List<TargetPlatform> _platforms = <TargetPlatform>[
  TargetPlatform.android,
  TargetPlatform.iOS,
  TargetPlatform.windows,
  TargetPlatform.macOS,
  TargetPlatform.linux,
];

RecordEntry _automaticRecord() => _record(
  extra: const <RecordValue>[
    RecordValue(fieldKey: 'model', raw: 'Pump', source: 'AUTO'),
  ],
);

/// A record named apart from its values, so a value is found once.
RecordEntry _record({
  RecordStatus status = RecordStatus.captured,
  List<RecordValue> extra = const <RecordValue>[],
}) {
  final RecordEntry record = aRecordEntry(
    id: 'r1',
    name: 'Boiler 3',
    status: status,
    fields: const <String, String>{
      'asset_tag': 'A-17',
      'quantity': '2',
      'condition': 'Faulty',
    },
  );
  return record.copyWith(values: <RecordValue>[...record.values, ...extra]);
}

void main() {
  group('automatic correction', () {
    for (final ({FieldDef field, String raw, String next}) sample
        in <({FieldDef field, String raw, String next})>[
          (
            field: const FieldDef(
              fieldKey: 'captured_date',
              label: 'Captured date',
              type: FieldType.date,
              inputMode: InputMode.auto,
              autoFill: AutoFill.today,
            ),
            raw: '2026-09-20',
            next: '2026-09-21',
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
            next: '11:45:00',
          ),
        ]) {
      testWidgets('${sample.field.fieldKey} uses the existing picker after '
          'Correct value and preserves its original on Save', (
        WidgetTester tester,
      ) async {
        final RecordEntry record = _record(
          extra: <RecordValue>[
            RecordValue(
              fieldKey: sample.field.fieldKey,
              raw: sample.raw,
              source: 'AUTO',
            ),
          ],
        );
        final _Harness harness = await _pump(
          tester,
          record: record,
          fields: <FieldDef>[sample.field],
          fieldKey: sample.field.fieldKey,
          label: sample.field.label,
        );
        expect(find.byType(FieldEditor), findsNothing);
        await tester.tap(
          find.byKey(
            ValueKey<String>('record-field-correct-${sample.field.fieldKey}'),
          ),
        );
        await tester.pumpAndSettle();
        expect(harness.records.writes, isEmpty);
        await tester.tap(_field(sample.field.label));
        await tester.pumpAndSettle();
        if (sample.field.type == FieldType.date) {
          final Finder dialog = find.byType(DatePickerDialog);
          expect(dialog, findsOneWidget);
          await tester.tap(
            find.descendant(of: dialog, matching: find.text('21')),
          );
        } else {
          final Finder dialog = find.byType(TimePickerDialog);
          expect(dialog, findsOneWidget);
          final MaterialLocalizations local = MaterialLocalizations.of(
            tester.element(dialog),
          );
          await tester.tap(find.byTooltip(local.inputTimeModeButtonLabel));
          await tester.pumpAndSettle();
          final Finder inputs = find.descendant(
            of: dialog,
            matching: find.byType(TextField),
          );
          await tester.enterText(inputs.at(0), '11');
          await tester.enterText(inputs.at(1), '45');
        }
        await tester.pump();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        await _saveAndSettle(tester);
        final RecordValue saved = harness.records
            .entryOf('r1')!
            .valueOf(sample.field.fieldKey)!;
        expect(saved.raw, sample.raw);
        expect(saved.refined, sample.next);
        expect(saved.source, 'manual');
        expect(saved.verified, isTrue);
        expect(
          harness.records
              .historyOf('r1')
              .where((event) => event.fieldKey == sample.field.fieldKey),
          hasLength(1),
        );
      });
    }

    testWidgets(
      'Correct value alone and cancel never write; Save is explicit',
      (WidgetTester tester) async {
        final _Harness harness = await _pump(
          tester,
          record: _automaticRecord(),
          fields: const <FieldDef>[_automaticModel],
          fieldKey: 'model',
          label: 'Model',
        );
        expect(find.byType(FieldEditor), findsNothing);
        await tester.tap(
          find.byKey(const ValueKey<String>('record-field-correct-model')),
        );
        await tester.pumpAndSettle();
        expect(_textOf(tester, 'Model'), 'Pump');
        expect(harness.records.writes, isEmpty);
        await _saveAndSettle(tester);
        expect(harness.records.writes, isEmpty);
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey<String>('record-field-correct-model')),
        );
        await tester.pumpAndSettle();
        await tester.enterText(_field('Model'), 'Discarded');
        await tester.pump();
        await tester.tapAt(const Offset(8, 8));
        await tester.pumpAndSettle();
        expect(harness.records.writes, isEmpty);
        expect(harness.records.entryOf('r1')!.valueOf('model')!.raw, 'Pump');
      },
    );

    testWidgets('automatic correction failure retains the draft and retry '
        'saves beside the original once', (WidgetTester tester) async {
      final _Harness harness = await _pump(
        tester,
        record: _automaticRecord(),
        fields: const <FieldDef>[_automaticModel],
        fieldKey: 'model',
        label: 'Model',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('record-field-correct-model')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(_field('Model'), 'Boiler');
      await tester.pump();
      harness.records.writeFailure = _full;
      await _saveAndSettle(tester);
      expect(_textOf(tester, 'Model'), 'Boiler');
      expect(harness.records.writes, isEmpty);
      expect(harness.records.entryOf('r1')!.valueOf('model')!.source, 'AUTO');
      harness.records.writeFailure = null;
      await _saveAndSettle(tester);
      final RecordValue saved = harness.records
          .entryOf('r1')!
          .valueOf('model')!;
      expect(saved.raw, 'Pump');
      expect(saved.refined, 'Boiler');
      expect(saved.source, 'manual');
      expect(saved.verified, isTrue);
      expect(
        harness.records
            .historyOf('r1')
            .where((event) => event.fieldKey == 'model'),
        hasLength(1),
      );
    });

    testWidgets('sheet keeps the captured policy after template edits and '
        'stops editing when the record moves to a protected shape', (
      WidgetTester tester,
    ) async {
      final RecordEntry record = _automaticRecord();
      final _Harness harness = await _pump(
        tester,
        record: record,
        fields: const <FieldDef>[_automaticModel],
        fieldKey: 'model',
        label: 'Model',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('record-field-correct-model')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(_field('Model'), 'Draft');
      await harness.templates.save(
        harness.templates.stored.single.copyWith(
          fields: <FieldDef>[_automaticModel.copyWith(hidden: true)],
        ),
      );
      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(FieldEditor)),
      );
      container.invalidate(recordEditTemplateProvider(record.templateId));
      await tester.pumpAndSettle();
      expect(find.byType(FieldEditor), findsOneWidget);
      expect(_textOf(tester, 'Model'), 'Draft');
      harness.records.seedEntry(record.copyWith(templateVersion: 2));
      await tester.pumpAndSettle();
      expect(find.byType(FieldEditor), findsNothing);
      expect(find.byType(AppPrimaryAction), findsNothing);
      expect(harness.records.writes, isEmpty);
      expect(harness.records.entryOf('r1')!.valueOf('model')!.raw, 'Pump');
    });

    for (final TargetPlatform platform in _platforms) {
      for (final bool pseudo in <bool>[false, true]) {
        for (final ScreenMatrix cell in ScreenMatrix.cells) {
          testWidgets(
            'automatic correction ${cell.description} ${pseudo ? 'pseudo RTL' : 'normal'} ${platform.name}',
            (WidgetTester tester) async {
              await tester.runAsync(ScreenFonts.load);
              final _Harness harness = await _pump(
                tester,
                record: _automaticRecord(),
                fields: const <FieldDef>[_automaticModel],
                fieldKey: 'model',
                label: 'Model',
                size: cell.size,
                textScale: cell.textScale,
                brightness: cell.brightness,
                outdoor: cell.outdoor,
                locale: pseudo ? const Locale('en', 'XA') : const Locale('en'),
                direction: pseudo ? TextDirection.rtl : TextDirection.ltr,
                platform: platform,
              );
              final Finder correct = find.byKey(
                const ValueKey<String>('record-field-correct-model'),
              );
              await tester.ensureVisible(correct);
              await tester.pumpAndSettle();
              expect(
                await ScreenProbe.accessibilityIssues(
                  tester,
                  targets: <Finder>[correct],
                ),
                isEmpty,
              );
              await tester.tap(correct);
              await tester.pumpAndSettle();
              await tester.ensureVisible(_field('Model'));
              await tester.enterText(_field('Model'), 'Boiler');
              await tester.pumpAndSettle();
              final Finder save = find.byType(AppPrimaryAction);
              await tester.ensureVisible(save);
              await tester.pumpAndSettle();
              expect(
                await ScreenProbe.accessibilityIssues(
                  tester,
                  targets: <Finder>[save],
                ),
                isEmpty,
              );
              await _saveAndSettle(tester);
              expect(
                harness.records.entryOf('r1')!.valueOf('model')!.refined,
                'Boiler',
              );
              expect(
                harness.records.entryOf('r1')!.valueOf('model')!.raw,
                'Pump',
              );
            },
          );
        }
      }
    }
  });

  group('states', () {
    testWidgets('while the record loads the sheet shows a skeleton', (
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

      expect(find.byType(AppBottomSheet), findsOneWidget);
      expect(find.byType(AppSkeleton), findsOneWidget);
      expect(find.byType(AppPrimaryAction), findsNothing);
    });

    testWidgets('a record that is not on this device says so', (
      WidgetTester tester,
    ) async {
      await _pump(tester, record: null);

      expect(find.text(Copy.recordGoneHeadline), findsOneWidget);
      expect(find.byType(FieldEditor), findsNothing);
      expect(find.byType(AppPrimaryAction), findsNothing);
    });

    testWidgets('a record in the recycle bin cannot be edited', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _pump(tester, record: null);
      harness.records.seedDeleted(_record());
      await tester.pumpAndSettle();

      expect(find.text(Copy.recordEditDeletedHeadline), findsOneWidget);
      expect(find.byType(FieldEditor), findsNothing);
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

    testWidgets('a field the record cannot show says so', (
      WidgetTester tester,
    ) async {
      await _pump(tester, record: _record(), fieldKey: 'record_uid');

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text(Copy.recordFieldMissingHeadline), findsOneWidget);
      expect(find.text(Copy.recordFieldMissingMessage), findsOneWidget);
      expect(find.byType(AppPrimaryAction), findsNothing);
    });
  });

  group('editing', () {
    testWidgets('the sheet is titled by the field and holds its typed input '
        'with the stored value', (WidgetTester tester) async {
      await _pump(
        tester,
        record: _record(),
        fieldKey: 'quantity',
        label: 'Quantity',
      );

      expect(
        tester.widget<AppBottomSheet>(find.byType(AppBottomSheet)).title,
        'Quantity',
      );
      expect(
        find.byKey(const ValueKey<String>('field-editor-number-quantity')),
        findsOneWidget,
      );
      expect(_textOf(tester, 'Quantity'), '2');
      expect(find.byType(FieldEditor), findsOneWidget);
    });

    testWidgets('without a label the sheet has a plain title', (
      WidgetTester tester,
    ) async {
      await _pump(tester, record: _record(), label: null);

      expect(
        tester.widget<AppBottomSheet>(find.byType(AppBottomSheet)).title,
        Copy.recordValueEditTitle,
      );
      expect(_textOf(tester, 'Asset tag'), 'A-17');
    });

    testWidgets('Save writes only this value, closes the sheet and says so', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _pump(tester, record: _record());

      await tester.enterText(_field('Asset tag'), 'A-18');
      await tester.pump();
      await _saveAndSettle(tester);

      expect(find.byType(AppBottomSheet), findsNothing);
      expect(find.text(Copy.recordValuesSaved(1)), findsOneWidget);
      expect(harness.records.writes, <({String method, String id})>[
        (method: 'editValues', id: 'r1'),
      ]);
      expect(
        <(String?, String?, String?)>[
          for (final RecordHistoryEvent event in harness.records.historyOf(
            'r1',
          ))
            (event.fieldKey, event.previous, event.next),
        ],
        <(String?, String?, String?)>[('asset_tag', 'A-17', 'A-18')],
      );
      final RecordEntry saved = harness.records.entryOf('r1')!;
      expect(saved.valueOf('asset_tag')!.raw, 'A-17');
      expect(saved.valueOf('asset_tag')!.display, 'A-18');
      expect(saved.valueOf('asset_tag')!.verified, isTrue);
      expect(saved.valueOf('quantity')!.refined, isNull);
      expect(saved.status, RecordStatus.captured);
    });

    testWidgets('a picked choice is saved as its text', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _pump(
        tester,
        record: _record(),
        fieldKey: 'condition',
        label: 'Condition',
      );

      await tester.tap(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('field-editor-choice-condition'),
          ),
          matching: find.text('Good'),
        ),
      );
      await tester.pumpAndSettle();
      await _saveAndSettle(tester);

      final RecordValue condition = harness.records
          .entryOf('r1')!
          .valueOf('condition')!;
      expect(condition.raw, 'Faulty');
      expect(condition.display, 'Good');
    });

    testWidgets('a switched toggle fills an empty field', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _pump(
        tester,
        record: _record(),
        fieldKey: 'working',
        label: 'Working',
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('field-editor-toggle-working')),
      );
      await tester.pumpAndSettle();
      await _saveAndSettle(tester);

      final RecordValue working = harness.records
          .entryOf('r1')!
          .valueOf('working')!;
      expect(working.display, 'true');
      expect(working.verified, isTrue);
    });

    testWidgets('Save with nothing changed closes without writing', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _pump(tester, record: _record());

      await _saveAndSettle(tester);

      expect(find.byType(AppBottomSheet), findsNothing);
      expect(harness.records.writes, isEmpty);
      expect(find.text(Copy.recordValuesSaved(1)), findsNothing);
    });

    testWidgets('an approved record says so, and saving returns it to review', (
      WidgetTester tester,
    ) async {
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
      expect(
        <RecordHistoryKind>[
          for (final RecordHistoryEvent event in history) event.kind,
        ],
        containsAll(<RecordHistoryKind>[
          RecordHistoryKind.valueChanged,
          RecordHistoryKind.statusChanged,
        ]),
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
        find.byKey(const ValueKey<String>('record-field-approved')),
        findsNothing,
      );
    });

    testWidgets('a failed save keeps the sheet open with what was typed', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _pump(tester, record: _record());
      harness.records.writeFailure = _full;

      await tester.enterText(_field('Asset tag'), 'A-18');
      await tester.pump();
      await _saveAndSettle(tester);

      expect(find.byType(AppBottomSheet), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('record-field-failure')),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(
          AppBanner,
          '${_full.message} ${_full.recoveryAction}',
        ),
        findsOneWidget,
      );
      expect(_textOf(tester, 'Asset tag'), 'A-18');
      expect(harness.records.writes, isEmpty);
      expect(
        harness.records.entryOf('r1')!.valueOf('asset_tag')!.display,
        'A-17',
      );

      harness.records.writeFailure = null;
      await _saveAndSettle(tester);

      expect(find.byType(AppBottomSheet), findsNothing);
      expect(
        harness.records.entryOf('r1')!.valueOf('asset_tag')!.display,
        'A-18',
      );
    });

    testWidgets('a value its type refuses is not saved, and the line goes '
        'once it is corrected', (WidgetTester tester) async {
      final _Harness harness = await _pump(
        tester,
        record: _record(),
        fieldKey: 'serial',
        label: 'Serial',
      );

      await tester.enterText(_field('Serial'), 'SERIAL-0042');
      await tester.pump();
      await _saveAndSettle(tester);

      final String problem = Copy.fieldError(
        'Serial',
        'That value is longer than this field allows.',
      );
      expect(
        find.byKey(const ValueKey<String>('record-field-problem')),
        findsOneWidget,
      );
      expect(find.widgetWithText(AppBanner, problem), findsOneWidget);
      expect(find.byType(AppBottomSheet), findsOneWidget);
      expect(harness.records.writes, isEmpty);

      await tester.enterText(_field('Serial'), 'S-42');
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('record-field-problem')),
        findsNothing,
      );
      await _saveAndSettle(tester);
      expect(harness.records.entryOf('r1')!.valueOf('serial')!.display, 'S-42');
    });

    testWidgets('a saved value is never emptied', (WidgetTester tester) async {
      final _Harness harness = await _pump(tester, record: _record());

      await tester.enterText(_field('Asset tag'), '');
      await tester.pump();
      await _saveAndSettle(tester);

      expect(
        find.widgetWithText(
          AppBanner,
          Copy.fieldError('Asset tag', Copy.recordValueCannotEmpty),
        ),
        findsOneWidget,
      );
      expect(harness.records.writes, isEmpty);
      expect(
        harness.records.entryOf('r1')!.valueOf('asset_tag')!.display,
        'A-17',
      );
    });

    testWidgets('a closed sheet forgets what was typed', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _pump(tester, record: _record());

      await tester.enterText(_field('Asset tag'), 'A-18');
      await tester.pump();
      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();
      expect(find.byType(AppBottomSheet), findsNothing);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(_textOf(tester, 'Asset tag'), 'A-17');
      expect(harness.records.writes, isEmpty);
    });
  });

  group('retired and flagged values', () {
    testWidgets('a retired value opens read-only, with no Save', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _pump(
        tester,
        record: _record(
          extra: const <RecordValue>[
            RecordValue(fieldKey: 'old_code', raw: 'X-1', retired: true),
          ],
        ),
        fieldKey: 'old_code',
        label: 'old_code',
      );

      final Finder row = find.byKey(
        const ValueKey<String>('record-retired-old_code'),
      );
      expect(row, findsOneWidget);
      expect(tester.widget<AppListTile>(row).onTap, isNull);
      expect(find.text('X-1'), findsOneWidget);
      expect(find.text(Copy.recordValueRetired), findsOneWidget);
      expect(find.text(Copy.recordRetiredValuesMessage), findsOneWidget);
      expect(find.byType(FieldEditor), findsNothing);
      expect(find.byType(AppPrimaryAction), findsNothing);

      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(harness.records.writes, isEmpty);
    });

    testWidgets('a value the template no longer declares is read-only too', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        record: _record(
          extra: const <RecordValue>[
            RecordValue(fieldKey: 'legacy_note', raw: 'Kept'),
          ],
        ),
        fieldKey: 'legacy_note',
        label: 'legacy_note',
      );

      expect(
        find.byKey(const ValueKey<String>('record-retired-legacy_note')),
        findsOneWidget,
      );
      expect(find.text('Kept'), findsOneWidget);
      expect(find.byType(FieldEditor), findsNothing);
      expect(find.byType(AppPrimaryAction), findsNothing);
    });

    testWidgets('a retired value the template declares keeps its label', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        record: _record(
          extra: const <RecordValue>[
            RecordValue(fieldKey: 'notes', raw: 'Old note', retired: true),
          ],
        ),
        fieldKey: 'notes',
        label: null,
      );

      final Finder row = find.byKey(
        const ValueKey<String>('record-retired-notes'),
      );
      expect(tester.widget<AppListTile>(row).title, 'Notes');
      expect(find.byType(FieldEditor), findsNothing);
      expect(find.byType(AppPrimaryAction), findsNothing);
    });

    testWidgets('a value whose evidence was removed is marked and editable', (
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
        fieldKey: 'condition',
        label: 'Condition',
      );

      expect(
        find.byKey(const ValueKey<String>('record-evidence-removed-condition')),
        findsOneWidget,
      );
      expect(find.text(Copy.recordValueEvidenceRemoved), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('field-editor-choice-condition')),
        findsOneWidget,
      );
      expect(find.byType(AppPrimaryAction), findsOneWidget);
    });
  });

  group('layout', () {
    for (final ({String name, Size size, double scale, bool side}) layout
        in <({String name, Size size, double scale, bool side})>[
          (name: '393 dp', size: const Size(393, 886), scale: 1, side: false),
          (name: '800 dp', size: const Size(800, 1000), scale: 1, side: false),
          (name: '1200 dp', size: const Size(1200, 800), scale: 1, side: true),
          (
            name: 'landscape',
            size: const Size(886, 393),
            scale: 1,
            side: false,
          ),
          (
            name: '200 percent text in landscape',
            size: const Size(886, 393),
            scale: 2,
            side: false,
          ),
        ]) {
      testWidgets('at ${layout.name} the sheet fits and Save saves', (
        WidgetTester tester,
      ) async {
        final _Harness harness = await _pump(
          tester,
          record: _record(status: RecordStatus.approved),
          size: layout.size,
          textScale: layout.scale,
        );

        expect(tester.takeException(), isNull);
        expect(
          tester.widget<AppBottomSheet>(find.byType(AppBottomSheet)).sidePanel,
          layout.side,
        );
        await tester.enterText(_field('Asset tag'), 'A-18');
        await tester.pump();
        final Finder save = find.byType(AppPrimaryAction);
        await tester.ensureVisible(save);
        await tester.pumpAndSettle();
        final Rect bounds = tester.getRect(save);
        expect(bounds.top, greaterThanOrEqualTo(0));
        expect(bounds.bottom, lessThanOrEqualTo(layout.size.height));
        await tester.tap(save);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(AppBottomSheet), findsNothing);
        expect(
          harness.records.entryOf('r1')!.valueOf('asset_tag')!.display,
          'A-18',
        );
      });
    }
  });

  group('accessibility', () {
    testWidgets('Save is a labelled 48dp target and the marks are read out', (
      WidgetTester tester,
    ) async {
      final RecordEntry record = _record(status: RecordStatus.approved);
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
        fieldKey: 'condition',
        label: 'Condition',
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
        find.byKey(const ValueKey<String>('record-field-approved')),
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

/// Pumps a host page whose Open button shows the sheet for [fieldKey] of
/// record r1, the way the record detail opens it, then opens it.
Future<_Harness> _pump(
  WidgetTester tester, {
  required RecordEntry? record,
  String fieldKey = 'asset_tag',
  String? label = 'Asset tag',
  List<FieldDef> fields = _fields,
  List<Override> overrides = const <Override>[],
  Failure? readFailure,
  Size size = const Size(393, 886),
  double textScale = 1,
  Brightness brightness = Brightness.light,
  bool outdoor = false,
  Locale locale = const Locale('en'),
  TextDirection direction = TextDirection.ltr,
  TargetPlatform platform = TargetPlatform.android,
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
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ScreenFonts.theme(
          buildTheme(brightness: brightness, outdoor: outdoor),
        ).copyWith(platform: platform),
        builder: (context, child) =>
            Directionality(textDirection: direction, child: child!),
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (BuildContext context) {
                return AppButton(
                  label: 'Open',
                  onPressed: () => unawaited(
                    RecordFieldSheet.show(
                      context,
                      recordId: 'r1',
                      fieldKey: fieldKey,
                      label: label,
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
