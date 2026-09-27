import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/records/domain/domain.dart';
import 'package:tapture/features/records/presentation/record_history_providers.dart';
import 'package:tapture/features/records/presentation/record_history_screen.dart';
import 'package:tapture/features/records/records.dart'
    show recordRepositoryProvider;
import 'package:tapture/features/templates/templates.dart';

import '../../../support/a11y_matchers.dart';
import '../../../support/factories.dart';
import '../../templates/fakes/fake_template_repository.dart';
import '../fakes/fake_record_repository.dart';

const String _recordId = 'r1';

/// The template the record was captured under: it names the serial one way
/// and still declares the condition the record's current template retired.
final TemplateDef _boiler = aTemplate(
  id: 't1',
  name: 'Boiler',
  fields: const <FieldDef>[
    FieldDef(fieldKey: 'serial', label: 'Serial number', type: FieldType.text),
    FieldDef(
      fieldKey: 'condition',
      label: 'Condition',
      type: FieldType.text,
      sortOrder: 1,
    ),
  ],
);

/// The record's template now: its label for the serial wins.
final TemplateDef _pump = aTemplate(
  id: 't2',
  name: 'Pump',
  fields: const <FieldDef>[
    FieldDef(fieldKey: 'serial', label: 'Serial', type: FieldType.text),
  ],
);

RecordEntry _record({String templateId = 't2'}) {
  return aRecordEntry(
    id: _recordId,
    templateId: templateId,
    number: 12,
    name: 'Autoclave',
    fields: const <String, String>{'serial': 'SN-2'},
  );
}

/// Every line in this suite is written between 12:00 and 12:40 UTC, so no
/// local time zone splits one day's lines across two headings.
DateTime _on(int day, int minute) => DateTime.utc(2026, 9, day, 12, minute);

RecordHistoryEvent _event(
  String id,
  DateTime at,
  RecordHistoryKind kind, {
  String? fieldKey,
  String? previous,
  String? next,
  String? reason,
  String operator = 'Ann',
  String device = 'device-a',
}) {
  return RecordHistoryEvent(
    id: id,
    at: at,
    kind: kind,
    operator: operator,
    device: device,
    fieldKey: fieldKey,
    previous: previous,
    next: next,
    reason: reason,
  );
}

/// One line of every kind, over three days, as the audit table writes them
/// (D10): markers, flag values and JSON reasons included.
final List<RecordHistoryEvent> _everyKind = <RecordHistoryEvent>[
  _event(
    'e01',
    _on(14, 0),
    RecordHistoryKind.created,
    next: 'captured',
    reason: 'capture',
    operator: '',
  ),
  _event(
    'e02',
    _on(14, 5),
    RecordHistoryKind.processed,
    fieldKey: 'processing',
    next: 'completed',
    reason:
        '{"job":"j1","stage":"validate","provider":"OpenAI","model":"gpt-4o"}',
    operator: '',
  ),
  _event(
    'e03',
    _on(14, 6),
    RecordHistoryKind.valueChanged,
    fieldKey: 'serial',
    next: 'SN-1',
    operator: '',
  ),
  _event(
    'e04',
    _on(14, 10),
    RecordHistoryKind.valueChanged,
    fieldKey: 'serial',
    previous: 'SN-1',
    next: 'SN-2',
  ),
  _event(
    'e05',
    _on(14, 11),
    RecordHistoryKind.statusChanged,
    fieldKey: 'status',
    previous: 'extracted',
    next: 'needsReview',
    reason: '{"stage":"validate"}',
  ),
  _event(
    'e06',
    _on(16, 0),
    RecordHistoryKind.photoAdded,
    fieldKey: 'photo',
    next: 'added',
    reason: 'photo-9',
  ),
  _event(
    'e07',
    _on(16, 5),
    RecordHistoryKind.photoRemoved,
    fieldKey: 'photo',
    next: 'removed',
    reason: 'photo-9',
  ),
  _event(
    'e08',
    _on(16, 10),
    RecordHistoryKind.captionChanged,
    fieldKey: 'caption',
    previous: 'Front',
    next: 'Front of the boiler',
  ),
  _event(
    'e09',
    _on(16, 15),
    RecordHistoryKind.evidenceRemoved,
    fieldKey: 'serial',
    previous: 'false',
    next: 'true',
    reason: 'evidenceRemoved',
  ),
  _event(
    'e10',
    _on(16, 20),
    RecordHistoryKind.evidenceRemoved,
    fieldKey: 'serial',
    previous: 'true',
    next: 'false',
    reason: 'evidenceRemoved',
  ),
  _event(
    'e11',
    _on(16, 25),
    RecordHistoryKind.templateChanged,
    fieldKey: 'templateId',
    previous: 't1',
    next: 't2',
    reason: '{"method":"remap"}',
  ),
  _event(
    'e12',
    _on(16, 26),
    RecordHistoryKind.retired,
    fieldKey: 'condition',
    previous: 'false',
    next: 'true',
    reason: 'retired',
  ),
  _event(
    'e13',
    _on(16, 30),
    RecordHistoryKind.retired,
    fieldKey: 'condition',
    previous: 'true',
    next: 'false',
    reason: 'retired',
  ),
  _event(
    'e14',
    _on(18, 0),
    RecordHistoryKind.statusChanged,
    fieldKey: 'status',
    previous: 'needsReview',
    next: 'approved',
    reason: 'Checked on site',
  ),
  _event(
    'e15',
    _on(18, 5),
    RecordHistoryKind.merged,
    fieldKey: 'merge',
    next: 'inserted',
    reason: 'site-a.tapture',
  ),
  _event(
    'e16',
    _on(18, 10),
    RecordHistoryKind.merged,
    fieldKey: 'merge',
    next: 'updated',
    reason: 'site-b.tapture',
    operator: 'Ben',
  ),
  _event(
    'e17',
    _on(18, 20),
    RecordHistoryKind.exported,
    fieldKey: 'export',
    next: 'v2',
    reason: 'bundle,xlsx',
  ),
  _event(
    'e18',
    _on(18, 25),
    RecordHistoryKind.processed,
    fieldKey: 'processing',
    next: 'failed',
    reason: '{"job":"j2","attempts":3}',
    operator: '',
  ),
  _event(
    'e19',
    _on(18, 30),
    RecordHistoryKind.other,
    fieldKey: 'templateRowId',
    next: 'row-4',
    operator: '',
  ),
  _event(
    'e20',
    _on(18, 35),
    RecordHistoryKind.other,
    fieldKey: 'evidenceMissing',
    previous: 'false',
    next: 'true',
    operator: '',
    device: '',
  ),
  _event('e21', _on(18, 40), RecordHistoryKind.other, operator: ''),
];

/// What each line of [_everyKind] reads, in order, with the labels and names
/// the two templates give it.
final List<String> _everySentence = <String>[
  Copy.recordHistoryCaptured,
  Copy.recordHistoryProcessed(provider: 'OpenAI', model: 'gpt-4o'),
  Copy.recordHistoryValue('Serial', next: 'SN-1'),
  Copy.recordHistoryValue('Serial', previous: 'SN-1', next: 'SN-2'),
  Copy.recordHistoryStatus(
    previous: Copy.statusExtracted,
    next: Copy.statusNeedsReview,
  ),
  Copy.recordHistoryPhotoAdded,
  Copy.recordHistoryPhotoRemoved,
  Copy.recordHistoryValue(
    Copy.recordHistoryCaption,
    previous: 'Front',
    next: 'Front of the boiler',
  ),
  Copy.recordHistoryEvidenceRemoved('Serial'),
  Copy.recordHistoryEvidenceRestored('Serial'),
  Copy.recordHistoryTemplate(previous: 'Boiler', next: 'Pump'),
  Copy.recordHistoryRetired('Condition'),
  Copy.recordHistoryMappedAgain('Condition'),
  Copy.recordHistoryStatus(
    previous: Copy.statusNeedsReview,
    next: Copy.statusApproved,
  ),
  Copy.recordHistoryImported('site-a.tapture'),
  Copy.recordHistoryMerged('site-b.tapture'),
  Copy.recordHistoryExported('v2'),
  Copy.recordHistoryProcessingFailed(3),
  Copy.recordHistoryRowMatched,
  Copy.recordHistoryFileMissing,
  Copy.recordHistoryOther,
];

void main() {
  group('states', () {
    testWidgets('while the history loads the page shows a skeleton', (
      WidgetTester tester,
    ) async {
      final StreamController<List<RecordHistoryEvent>> pending =
          StreamController<List<RecordHistoryEvent>>();
      addTearDown(pending.close);
      await _pumpScreen(
        tester,
        history: _everyKind,
        overrides: <Override>[
          recordHistoryProvider.overrideWith(
            (Ref _, String _) => pending.stream,
          ),
        ],
      );

      expect(find.byType(AppSkeleton), findsOneWidget);
      expect(find.byType(AppListTile), findsNothing);

      pending.add(_everyKind.take(2).toList());
      await tester.pumpAndSettle();
      expect(find.byType(AppSkeleton), findsNothing);
      expect(find.text(Copy.recordHistoryCaptured), findsOneWidget);
    });

    testWidgets('an empty history says what will appear and names the '
        'record as the next step', (WidgetTester tester) async {
      await _pumpScreen(tester);

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text(Copy.recordHistoryEmptyHeadline), findsOneWidget);
      expect(find.text(Copy.recordHistoryEmptyMessage), findsOneWidget);
      // Opened on its own there is nowhere to go back to, so no button.
      expect(find.text(Copy.recordHistoryBackToRecord), findsNothing);
      expect(find.byType(AppListTile), findsNothing);
    });

    testWidgets('from the record, the empty history goes back to it', (
      WidgetTester tester,
    ) async {
      await _pumpScreen(tester, fromRecord: true);

      expect(find.text(Copy.recordHistoryEmptyHeadline), findsOneWidget);
      await tester.tap(find.text(Copy.recordHistoryBackToRecord));
      await tester.pumpAndSettle();

      expect(find.byType(RecordHistoryScreen), findsNothing);
      expect(find.text('record page'), findsOneWidget);
    });

    testWidgets('a record that is not on this device says so', (
      WidgetTester tester,
    ) async {
      await _pumpScreen(tester, record: null);

      expect(find.text(Copy.recordGoneHeadline), findsOneWidget);
      expect(find.text(Copy.recordHistoryEmptyHeadline), findsNothing);
    });

    testWidgets('a history that cannot be read shows the failure and a '
        'retry that reads it again', (WidgetTester tester) async {
      const StorageFailure failure = StorageFailure(
        message: 'The history could not be read.',
        recoveryAction: 'Try again in a moment.',
      );
      final _Harness harness = await _pumpScreen(
        tester,
        history: _everyKind,
        readFailure: failure,
      );

      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.text(failure.message), findsOneWidget);
      expect(find.byType(AppListTile), findsNothing);

      harness.records.readFailure = null;
      await tester.tap(find.text(Copy.tryAgain));
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorState), findsNothing);
      expect(find.text(Copy.recordHistoryCaptured), findsOneWidget);
    });
  });

  group('chronology', () {
    testWidgets('every kind of change reads in order under its day, with '
        'previous and new values', (WidgetTester tester) async {
      await _pumpScreen(
        tester,
        history: _everyKind,
        size: const Size(800, 4000),
      );

      expect(tester.takeException(), isNull);
      final List<String> titles = <String>[
        for (final AppListTile tile in tester.widgetList<AppListTile>(
          find.byType(AppListTile),
        ))
          tile.title,
      ];
      expect(titles, _everySentence);

      // One heading per local day, above that day's first line and below
      // the last line of the day before.
      final List<AppSectionHeader> headers = tester
          .widgetList<AppSectionHeader>(find.byType(AppSectionHeader))
          .toList();
      expect(headers.map((AppSectionHeader header) => header.title), <String>[
        Copy.recordHistoryDay(_localDay(_on(14, 0))),
        Copy.recordHistoryDay(_localDay(_on(16, 0))),
        Copy.recordHistoryDay(_localDay(_on(18, 0))),
      ]);
      double previousBottom = 0;
      for (final (String first, String last) in <(String, String)>[
        ('e01', 'e05'),
        ('e06', 'e13'),
        ('e14', 'e21'),
      ]) {
        final double top = tester.getTopLeft(_row(first)).dy;
        final Finder header = find.byKey(
          ValueKey<String>(
            'record-history-day-${_dayKey(_localDay(_at(first)))}',
          ),
        );
        final Rect heading = tester.getRect(header);
        expect(heading.top, greaterThanOrEqualTo(previousBottom));
        expect(heading.bottom, lessThanOrEqualTo(top));
        previousBottom = tester.getBottomLeft(_row(last)).dy;
      }
    });

    testWidgets('each line says when, by whom and on which device', (
      WidgetTester tester,
    ) async {
      await _pumpScreen(
        tester,
        history: _everyKind,
        size: const Size(800, 4000),
      );

      expect(
        find.descendant(
          of: _row('e04'),
          matching: find.text(
            Copy.recordHistoryByline(
              at: _at('e04').toLocal(),
              operator: 'Ann',
              device: 'device-a',
            ),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _row('e01'),
          matching: find.text(
            Copy.recordHistoryByline(
              at: _at('e01').toLocal(),
              device: 'device-a',
            ),
          ),
        ),
        findsOneWidget,
      );
      // A line with neither operator nor device shows only its time.
      expect(
        find.descendant(
          of: _row('e20'),
          matching: find.text(
            Copy.recordHistoryByline(at: _at('e20').toLocal()),
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('each kind carries its own icon', (WidgetTester tester) async {
      await _pumpScreen(
        tester,
        history: _everyKind,
        size: const Size(800, 4000),
      );

      final Map<String, IconData> icons = <String, IconData>{
        'e01': AppIcons.captured,
        'e02': AppIcons.processing,
        'e04': AppIcons.edit,
        'e05': AppIcons.review,
        'e06': AppIcons.addPhoto,
        'e07': AppIcons.remove,
        'e08': AppIcons.caption,
        'e09': AppIcons.brokenFile,
        'e10': AppIcons.photoLibrary,
        'e11': AppIcons.template,
        'e12': AppIcons.archive,
        'e13': AppIcons.unarchive,
        'e14': AppIcons.verified,
        'e15': AppIcons.merge,
        'e16': AppIcons.merge,
        'e17': AppIcons.export,
        'e18': AppIcons.error,
        'e19': AppIcons.checklist,
        'e21': AppIcons.history,
      };
      for (final MapEntry<String, IconData> expected in icons.entries) {
        expect(
          find.descendant(
            of: _row(expected.key),
            matching: find.byIcon(expected.value),
          ),
          findsOneWidget,
          reason: 'line ${expected.key}',
        );
      }
    });

    testWidgets('a tap opens the line whole: before, after, when, who and '
        'where', (WidgetTester tester) async {
      await _pumpScreen(tester, history: _everyKind);

      await tester.tap(_row('e04'));
      await tester.pumpAndSettle();

      final Finder detail = find.byKey(
        const ValueKey<String>('record-history-detail'),
      );
      expect(detail, findsOneWidget);
      expect(find.text(Copy.recordHistoryLineTitle), findsOneWidget);
      for (final String text in <String>[
        Copy.recordHistoryValue('Serial', previous: 'SN-1', next: 'SN-2'),
        Copy.recordHistoryBefore,
        'SN-1',
        Copy.recordHistoryAfter,
        'SN-2',
        Copy.recordHistoryWhen,
        Copy.recordHistoryAt(_at('e04').toLocal()),
        Copy.recordHistoryOperator,
        'Ann',
        Copy.recordHistoryDevice,
        'device-a',
      ]) {
        expect(
          find.descendant(of: detail, matching: find.text(text)),
          findsOneWidget,
          reason: text,
        );
      }
      // An edit with no reason in words shows no reason line.
      expect(
        find.descendant(
          of: detail,
          matching: find.text(Copy.recordHistoryReason),
        ),
        findsNothing,
      );
    });

    testWidgets('a status move shows its reason in words; a machine note '
        'stays hidden', (WidgetTester tester) async {
      await _pumpScreen(
        tester,
        history: _everyKind,
        size: const Size(800, 4000),
      );

      await tester.tap(_row('e14'));
      await tester.pumpAndSettle();
      Finder detail = find.byKey(
        const ValueKey<String>('record-history-detail'),
      );
      expect(
        find.descendant(
          of: detail,
          matching: find.text(Copy.statusNeedsReview),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: detail, matching: find.text(Copy.statusApproved)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: detail,
          matching: find.text(Copy.recordHistoryReason),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: detail, matching: find.text('Checked on site')),
        findsOneWidget,
      );
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await tester.tap(_row('e05'));
      await tester.pumpAndSettle();
      detail = find.byKey(const ValueKey<String>('record-history-detail'));
      expect(detail, findsOneWidget);
      expect(
        find.descendant(
          of: detail,
          matching: find.text(Copy.recordHistoryReason),
        ),
        findsNothing,
      );
      expect(find.textContaining('validate'), findsNothing);
    });

    testWidgets('a first value, a template change and a line with no '
        'operator read whole in the detail', (WidgetTester tester) async {
      await _pumpScreen(
        tester,
        history: _everyKind,
        size: const Size(800, 4000),
      );

      await tester.tap(_row('e03'));
      await tester.pumpAndSettle();
      Finder detail = find.byKey(
        const ValueKey<String>('record-history-detail'),
      );
      expect(
        find.descendant(
          of: detail,
          matching: find.text(Copy.recordHistoryEmptyValue),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: detail,
          matching: find.text(Copy.recordHistoryNotRecorded),
        ),
        findsOneWidget,
      );
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await tester.tap(_row('e11'));
      await tester.pumpAndSettle();
      detail = find.byKey(const ValueKey<String>('record-history-detail'));
      expect(
        find.descendant(of: detail, matching: find.text('Boiler')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: detail, matching: find.text('Pump')),
        findsOneWidget,
      );
    });

    testWidgets('a long value the row cuts short is shown whole in the '
        'detail', (WidgetTester tester) async {
      final String long = List<String>.filled(30, 'corroded flange').join(' ');
      await _pumpScreen(
        tester,
        history: <RecordHistoryEvent>[
          _event(
            'e1',
            _on(14, 0),
            RecordHistoryKind.valueChanged,
            fieldKey: 'serial',
            previous: 'SN-1',
            next: long,
          ),
        ],
      );

      final Text title = tester.widget<Text>(
        find.descendant(
          of: _row('e1'),
          matching: find.text(
            Copy.recordHistoryValue('Serial', previous: 'SN-1', next: long),
          ),
        ),
      );
      expect(title.maxLines, 1);

      await tester.tap(_row('e1'));
      await tester.pumpAndSettle();
      final Finder detail = find.byKey(
        const ValueKey<String>('record-history-detail'),
      );
      expect(
        find.descendant(of: detail, matching: find.text(long)),
        findsOneWidget,
      );
    });

    testWidgets('a record made by hand starts with its own line', (
      WidgetTester tester,
    ) async {
      await _pumpScreen(
        tester,
        history: <RecordHistoryEvent>[
          _event(
            'e1',
            _on(14, 0),
            RecordHistoryKind.created,
            next: 'draft',
            reason: 'manual',
          ),
        ],
      );

      expect(find.text(Copy.recordHistoryCreatedByHand), findsOneWidget);
      expect(
        find.descendant(of: _row('e1'), matching: find.byIcon(AppIcons.draft)),
        findsOneWidget,
      );
    });

    testWidgets('a field no template on this device declares shows its key, '
        'and a template that is gone is named as gone', (
      WidgetTester tester,
    ) async {
      await _pumpScreen(
        tester,
        record: _record(templateId: 't9'),
        templates: const <TemplateDef>[],
        history: <RecordHistoryEvent>[
          _event(
            'e1',
            _on(14, 0),
            RecordHistoryKind.valueChanged,
            fieldKey: 'serial',
            previous: 'SN-1',
            next: 'SN-2',
          ),
          _event(
            'e2',
            _on(14, 5),
            RecordHistoryKind.templateChanged,
            fieldKey: 'templateId',
            previous: 't8',
            next: 't9',
          ),
          _event(
            'e3',
            _on(14, 10),
            RecordHistoryKind.statusChanged,
            fieldKey: 'status',
            previous: 'legacy',
            next: 'NEEDS_REVIEW',
          ),
        ],
      );

      expect(
        find.text(
          Copy.recordHistoryValue('serial', previous: 'SN-1', next: 'SN-2'),
        ),
        findsOneWidget,
      );
      expect(find.text(Copy.recordHistoryTemplate()), findsOneWidget);
      // A spelling the status set folds is labelled; one it does not know
      // is shown as stored rather than dropped.
      expect(
        find.text(
          Copy.recordHistoryStatus(
            previous: 'legacy',
            next: Copy.statusNeedsReview,
          ),
        ),
        findsOneWidget,
      );

      await tester.tap(_row('e2'));
      await tester.pumpAndSettle();
      expect(find.text(Copy.recordHistoryTemplateGone), findsNWidgets(2));
    });

    testWidgets('the page names the record and follows new changes', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _pumpScreen(
        tester,
        history: <RecordHistoryEvent>[
          _event(
            'e1',
            _on(14, 0),
            RecordHistoryKind.created,
            next: 'captured',
            reason: 'capture',
          ),
        ],
      );

      expect(find.text(Copy.recordHistoryTitle), findsOneWidget);
      expect(
        find.text(Copy.recordHistorySubject(number: 12, name: 'Autoclave')),
        findsOneWidget,
      );
      expect(find.byType(AppListTile), findsOneWidget);

      await harness.records.editValues(_recordId, <RecordValueEdit>[
        (fieldKey: 'serial', value: 'SN-3'),
      ]);
      await tester.pumpAndSettle();

      expect(find.byType(AppListTile), findsNWidgets(2));
      expect(
        find.text(
          Copy.recordHistoryValue('Serial', previous: 'SN-2', next: 'SN-3'),
        ),
        findsOneWidget,
      );
      expect(harness.records.historyOf(_recordId), hasLength(2));
    });

    testWidgets('a deleted record keeps its whole history', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _pumpScreen(
        tester,
        history: _everyKind.take(4).toList(),
      );
      await harness.records.delete(
        _recordId,
        reason: 'Deleted by the operator.',
      );
      await tester.pumpAndSettle();

      expect(harness.records.isTombstoned(_recordId), isTrue);
      expect(find.byType(AppListTile), findsNWidgets(5));
      expect(
        find.text(
          Copy.recordHistoryStatus(
            previous: Copy.statusCaptured,
            next: Copy.statusDeleted,
          ),
        ),
        findsOneWidget,
      );
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
          (
            name: '200 percent text in landscape',
            size: const Size(886, 393),
            scale: 2,
          ),
        ]) {
      testWidgets('at ${layout.name} the chronology fits and scrolls to its '
          'last line', (WidgetTester tester) async {
        await _pumpScreen(
          tester,
          history: _everyKind,
          size: layout.size,
          textScale: layout.scale,
        );

        expect(tester.takeException(), isNull);
        expect(_row('e01'), findsOneWidget);
        final Rect first = tester.getRect(_row('e01'));
        expect(first.right, lessThanOrEqualTo(layout.size.width));
        // Rows keep a readable measure on wide windows (FE-RESP-04).
        expect(first.width, lessThanOrEqualTo(720));

        await tester.scrollUntilVisible(
          _row('e21'),
          300,
          scrollable: find.descendant(
            of: find.byKey(const ValueKey<String>('record-history-list')),
            matching: find.byType(Scrollable),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(_row('e21'), findsOneWidget);

        await tester.tap(_row('e21'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey<String>('record-history-detail')),
          findsOneWidget,
        );
      });
    }

    for (final ({String name, Failure? failure}) state
        in <({String name, Failure? failure})>[
          (name: 'empty', failure: null),
          (
            name: 'failure',
            failure: const StorageFailure(
              message: 'The history could not be read.',
              recoveryAction: 'Try again in a moment.',
            ),
          ),
        ]) {
      testWidgets('at 200 percent text in landscape the ${state.name} state '
          'scrolls instead of clipping', (WidgetTester tester) async {
        await _pumpScreen(
          tester,
          fromRecord: true,
          readFailure: state.failure,
          size: const Size(886, 393),
          textScale: 2,
        );

        expect(tester.takeException(), isNull);
        expect(
          find.byType(state.failure == null ? AppEmptyState : AppErrorState),
          findsOneWidget,
        );
      });
    }
  });

  group('accessibility', () {
    testWidgets('lines are labelled 48dp targets and days are headings', (
      WidgetTester tester,
    ) async {
      await _pumpScreen(tester, history: _everyKind);
      final SemanticsHandle handle = tester.ensureSemantics();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      for (final String id in <String>['e01', 'e02', 'e04', 'e05']) {
        expect(_row(id), meetsTapTarget());
      }
      expect(
        _row('e04'),
        hasSemanticLabel(
          Copy.recordHistoryValue('Serial', previous: 'SN-1', next: 'SN-2'),
        ),
      );
      expect(
        tester.getSemantics(_row('e04')),
        isSemantics(isButton: true, hasTapAction: true),
      );
      expect(
        tester.getSemantics(
          find.byKey(
            ValueKey<String>(
              'record-history-day-${_dayKey(_localDay(_on(14, 0)))}',
            ),
          ),
        ),
        isSemantics(isHeader: true),
      );
      handle.dispose();
    });

    testWidgets('the detail reads each label with its value', (
      WidgetTester tester,
    ) async {
      await _pumpScreen(tester, history: _everyKind);
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.tap(_row('e04'));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('${Copy.recordHistoryBefore}\nSN-1'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('${Copy.recordHistoryOperator}\nAnn'),
        findsOneWidget,
      );
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });
}

Finder _row(String eventId) {
  return find.byKey(ValueKey<String>('record-history-$eventId'));
}

DateTime _at(String eventId) {
  return _everyKind
      .firstWhere((RecordHistoryEvent event) => event.id == eventId)
      .at;
}

DateTime _localDay(DateTime at) {
  final DateTime local = at.toLocal();
  return DateTime(local.year, local.month, local.day);
}

String _dayKey(DateTime day) {
  final String month = '${day.month}'.padLeft(2, '0');
  final String date = '${day.day}'.padLeft(2, '0');
  return '${day.year}-$month-$date';
}

typedef _Harness = ({
  FakeRecordRepository records,
  FakeTemplateRepository templates,
});

/// Pumps the history of record [_recordId]. [record] null leaves the record
/// off the device; [fromRecord] opens the page on top of a record page so
/// it can go back.
Future<_Harness> _pumpScreen(
  WidgetTester tester, {
  Object? record = _seeded,
  List<RecordHistoryEvent> history = const <RecordHistoryEvent>[],
  List<TemplateDef>? templates,
  List<Override> overrides = const <Override>[],
  Failure? readFailure,
  bool fromRecord = false,
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
  final RecordEntry? entry = identical(record, _seeded)
      ? _record()
      : record as RecordEntry?;
  if (entry != null) {
    records.seedEntry(entry);
  }
  if (history.isNotEmpty) {
    records.seedHistory(_recordId, history);
  }
  records.readFailure = readFailure;
  final FakeTemplateRepository templateStore = FakeTemplateRepository();
  addTearDown(templateStore.dispose);
  for (final TemplateDef template
      in templates ?? <TemplateDef>[_boiler, _pump]) {
    await templateStore.save(template);
  }
  final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        recordRepositoryProvider.overrideWith((Ref _) => records),
        templateRepositoryProvider.overrideWith((Ref _) => templateStore),
        ...overrides,
      ],
      child: MaterialApp(
        navigatorKey: navigator,
        theme: buildTheme(brightness: Brightness.light),
        home: fromRecord
            ? const Scaffold(body: Text('record page'))
            : const RecordHistoryScreen(recordId: _recordId),
      ),
    ),
  );
  if (fromRecord) {
    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (BuildContext _) =>
              const RecordHistoryScreen(recordId: _recordId),
        ),
      ),
    );
  }
  await tester.pumpAndSettle();
  return (records: records, templates: templateStore);
}

/// Marks the default record in [_pumpScreen], so null can mean "none".
const Object _seeded = Object();
