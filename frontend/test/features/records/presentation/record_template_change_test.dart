import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/router.dart' show AppRoutes;
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/records/domain/domain.dart';
import 'package:tapture/features/records/presentation/record_template_change.dart';
import 'package:tapture/features/records/presentation/record_template_change_controller.dart';
import 'package:tapture/features/records/records.dart'
    show recordRepositoryProvider;
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';
import '../../templates/fakes/fake_template_repository.dart';
import '../fakes/fake_record_repository.dart';

const StorageFailure _locked = StorageFailure(
  message: 'That record is locked by a merge.',
  recoveryAction: 'Finish the merge, then try again.',
);

const StorageFailure _unreadable = StorageFailure(
  message: 'The templates could not be read.',
  recoveryAction: 'Restart the app and try again.',
);

/// The pump template the record is on, and the motor template it can move
/// to. Their labels differ for the key they share, so the preview can show
/// which template names each field.
final TemplateDef _pump = aTemplate(
  id: 'template-1',
  name: 'Pump',
  fields: const <FieldDef>[
    FieldDef(fieldKey: 'serial', label: 'Serial number', type: FieldType.text),
    FieldDef(fieldKey: 'model', label: 'Model', type: FieldType.text),
    FieldDef(fieldKey: 'location', label: 'Location', type: FieldType.text),
  ],
);

final TemplateDef _motor = aTemplate(
  id: 'template-2',
  name: 'Motor',
  fields: const <FieldDef>[
    FieldDef(fieldKey: 'serial', label: 'Serial no.', type: FieldType.text),
    FieldDef(fieldKey: 'rating', label: 'Rating', type: FieldType.text),
    FieldDef(fieldKey: 'capacity', label: 'Capacity', type: FieldType.text),
  ],
);

void main() {
  late FakeRecordRepository records;
  late FakeTemplateRepository templates;

  setUp(() {
    records = FakeRecordRepository();
    templates = FakeTemplateRepository();
  });

  tearDown(() {
    records.dispose();
    templates.dispose();
  });

  /// Declares [defs] in both stores: the template store the sheet lists
  /// from and the record store that plans and applies the move.
  Future<void> declare(List<TemplateDef> defs) async {
    for (final TemplateDef def in defs) {
      await templates.save(def);
      records.seedTemplate(
        def.id,
        name: def.name,
        fieldKeys: <String>[for (final FieldDef f in def.fields) f.fieldKey],
      );
    }
  }

  /// Record `record-1` on the pump template, with a serial and a model
  /// read from its photos and a rating an earlier move retired.
  void seedRecord({RecordStatus status = RecordStatus.needsReview}) {
    final RecordEntry entry = aRecordEntry(
      id: 'record-1',
      templateId: 'template-1',
      status: status,
      fields: const <String, String>{'serial': 'SN-1', 'model': 'X200'},
      source: 'ocr',
    );
    records.seedEntry(
      entry.copyWith(
        values: <RecordValue>[
          ...entry.values,
          const RecordValue(
            fieldKey: 'rating',
            raw: '5 kW',
            source: 'ocr',
            retired: true,
          ),
        ],
      ),
    );
  }

  Future<GoRouter> open(
    WidgetTester tester, {
    List<Override> overrides = const <Override>[],
    bool settle = true,
  }) async {
    final GoRouter router = GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (BuildContext _, GoRouterState _) => Scaffold(
            body: Center(
              child: Builder(
                builder: (BuildContext context) => AppButton(
                  label: 'Open',
                  onPressed: () => unawaited(
                    RecordTemplateChange.show(
                      context,
                      projectId: 'project-1',
                      recordId: 'record-1',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/projects/:projectId/templates',
          builder: (BuildContext _, GoRouterState state) => Scaffold(
            body: Text('templates of ${state.pathParameters['projectId']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        retry: (int _, Object _) => null,
        overrides: <Override>[
          recordRepositoryProvider.overrideWith((Ref _) => records),
          templateRepositoryProvider.overrideWith((Ref _) => templates),
          ...overrides,
        ],
        child: MaterialApp.router(
          theme: buildTheme(brightness: Brightness.light),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump();
    }
    return router;
  }

  Finder choice(String id) =>
      find.byKey(ValueKey<String>('template-change-choice-$id'));

  Finder row(String group, String key) =>
      find.byKey(ValueKey<String>('template-change-$group-$key'));

  AppPrimaryAction applyButton(WidgetTester tester) {
    return tester.widget<AppPrimaryAction>(
      find.byKey(const ValueKey<String>('record-template-change-apply')),
    );
  }

  Future<void> apply(WidgetTester tester) async {
    await tester.tap(
      find.byKey(const ValueKey<String>('record-template-change-apply')),
    );
    await tester.pumpAndSettle();
  }

  group('before a template is chosen', () {
    testWidgets('lists the other templates of the project and says what '
        'choosing one does, with nothing to apply yet', (
      WidgetTester tester,
    ) async {
      await declare(<TemplateDef>[_pump, _motor]);
      seedRecord();
      await open(tester);

      expect(find.text(Copy.recordTemplateChangeTitle), findsWidgets);
      expect(
        find.text(Copy.recordTemplateChangeCurrent('Pump')),
        findsOneWidget,
      );
      expect(choice('template-2'), findsOneWidget);
      expect(find.text('Motor'), findsOneWidget);
      expect(find.text(Copy.fieldsCount(3)), findsOneWidget);
      // The template the record is already on is not offered.
      expect(choice('template-1'), findsNothing);
      expect(find.text(Copy.recordTemplateChangeHint), findsOneWidget);
      expect(applyButton(tester).onPressed, isNull);
      expect(records.writes, isEmpty);
    });

    testWidgets('an approved record is warned that the move sends it back '
        'to review', (WidgetTester tester) async {
      await declare(<TemplateDef>[_pump, _motor]);
      seedRecord(status: RecordStatus.approved);
      await open(tester);

      expect(
        find.text(Copy.recordTemplateChangeApprovedNotice),
        findsOneWidget,
      );
    });

    testWidgets('a record that is not approved gets no review warning', (
      WidgetTester tester,
    ) async {
      await declare(<TemplateDef>[_pump, _motor]);
      seedRecord();
      await open(tester);

      expect(find.text(Copy.recordTemplateChangeApprovedNotice), findsNothing);
    });
  });

  group('the preview', () {
    testWidgets('names every value by its field label under carried over, '
        'kept as retired, start empty and comes back, and changes nothing', (
      WidgetTester tester,
    ) async {
      await declare(<TemplateDef>[_pump, _motor]);
      seedRecord();
      await open(tester);

      await tester.tap(choice('template-2'));
      await tester.pumpAndSettle();

      expect(find.text(Copy.recordTemplateChangeHint), findsNothing);
      // Carried over: named by the new template, with what it holds.
      expect(find.text(Copy.recordTemplateChangeMapped(1)), findsOneWidget);
      expect(
        find.descendant(
          of: row('mapped', 'serial'),
          matching: find.text('Serial no.'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: row('mapped', 'serial'),
          matching: find.text('SN-1'),
        ),
        findsOneWidget,
      );
      // Kept as retired: named by the template it leaves, value shown.
      expect(find.text(Copy.recordTemplateChangeRetired(1)), findsOneWidget);
      expect(
        find.descendant(
          of: row('retired', 'model'),
          matching: find.text('Model'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: row('retired', 'model'),
          matching: find.text('X200'),
        ),
        findsOneWidget,
      );
      expect(find.text(Copy.recordTemplateChangeRetiredNotice), findsOneWidget);
      // Starts empty: the new template's field with no value.
      expect(find.text(Copy.recordTemplateChangeAdded(1)), findsOneWidget);
      expect(
        find.descendant(
          of: row('added', 'capacity'),
          matching: find.text('Capacity'),
        ),
        findsOneWidget,
      );
      // Comes back: the retired value the new template has a field for.
      expect(find.text(Copy.recordTemplateChangeRestored(1)), findsOneWidget);
      expect(
        find.descendant(
          of: row('restored', 'rating'),
          matching: find.text('Rating'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: row('restored', 'rating'),
          matching: find.text('5 kW'),
        ),
        findsOneWidget,
      );
      // A value the new template does not declare never reads as mapped.
      expect(row('mapped', 'model'), findsNothing);
      expect(applyButton(tester).onPressed, isNotNull);
      expect(records.writes, isEmpty);
      expect(records.entryOf('record-1')!.templateId, 'template-1');
    });

    testWidgets('the chosen template is marked and announced as selected', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await declare(<TemplateDef>[_pump, _motor]);
      seedRecord();
      await open(tester);

      await tester.tap(choice('template-2'));
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(choice('template-2')),
        isSemantics(label: 'Motor', isSelected: true, isButton: true),
      );
      semantics.dispose();
    });

    testWidgets('a move that changes no value says so', (
      WidgetTester tester,
    ) async {
      await declare(<TemplateDef>[
        _pump,
        aTemplate(id: 'template-3', name: 'Blank'),
      ]);
      records.seedEntry(
        aRecordEntry(
          id: 'record-1',
          templateId: 'template-1',
          fields: const <String, String>{},
        ),
      );
      await open(tester);

      await tester.tap(choice('template-3'));
      await tester.pumpAndSettle();

      expect(find.text(Copy.recordTemplateChangeNoValues), findsOneWidget);
      expect(applyButton(tester).onPressed, isNotNull);
    });

    testWidgets('a plan that cannot be made shows the failure and keeps '
        'Change template off', (WidgetTester tester) async {
      await declare(<TemplateDef>[_pump]);
      // Listed by the template store, but unknown to the record store, so
      // the plan fails.
      await templates.save(_motor);
      seedRecord();
      await open(tester);

      await tester.tap(choice('template-2'));
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.text(Copy.recordTemplateChangeMapped(1)), findsNothing);
      expect(applyButton(tester).onPressed, isNull);
      expect(records.writes, isEmpty);
    });
  });

  group('applying', () {
    testWidgets('moves the record, keeps the unmapped value as retired, '
        'closes the sheet and says so', (WidgetTester tester) async {
      await declare(<TemplateDef>[_pump, _motor]);
      seedRecord();
      await open(tester);
      await tester.tap(choice('template-2'));
      await tester.pumpAndSettle();

      await apply(tester);

      final RecordEntry moved = records.entryOf('record-1')!;
      expect(moved.templateId, 'template-2');
      expect(moved.status, RecordStatus.needsReview);
      // Nothing deleted: model is kept as retired, rating is live again.
      expect(moved.valueOf('model')!.retired, isTrue);
      expect(moved.valueOf('model')!.display, 'X200');
      expect(moved.valueOf('rating')!.retired, isFalse);
      expect(moved.valueOf('serial')!.display, 'SN-1');
      expect(records.writes, <({String method, String id})>[
        (method: 'changeTemplate', id: 'record-1'),
      ]);
      expect(find.byType(RecordTemplateChange), findsNothing);
      expect(find.text(Copy.recordTemplateChanged()), findsOneWidget);
    });

    testWidgets('an approved record goes back to review, and the snack says '
        'so', (WidgetTester tester) async {
      await declare(<TemplateDef>[_pump, _motor]);
      seedRecord(status: RecordStatus.approved);
      await open(tester);
      await tester.tap(choice('template-2'));
      await tester.pumpAndSettle();

      await apply(tester);

      expect(records.entryOf('record-1')!.status, RecordStatus.needsReview);
      expect(
        find.text(Copy.recordTemplateChanged(backToReview: true)),
        findsOneWidget,
      );
    });

    testWidgets('a failure keeps the sheet open with the reason, and a '
        'second try can succeed', (WidgetTester tester) async {
      await declare(<TemplateDef>[_pump, _motor]);
      seedRecord();
      records.failuresById['record-1'] = _locked;
      await open(tester);
      await tester.tap(choice('template-2'));
      await tester.pumpAndSettle();

      await apply(tester);

      expect(find.byType(RecordTemplateChange), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('record-template-change-failure')),
        findsOneWidget,
      );
      expect(find.text(_locked.message), findsOneWidget);
      expect(records.entryOf('record-1')!.templateId, 'template-1');
      expect(records.writes, isEmpty);
      expect(find.text(Copy.recordTemplateChanged()), findsNothing);

      records.failuresById.clear();
      await apply(tester);

      expect(find.byType(RecordTemplateChange), findsNothing);
      expect(records.entryOf('record-1')!.templateId, 'template-2');
    });

    testWidgets('closing the sheet without applying changes nothing', (
      WidgetTester tester,
    ) async {
      await declare(<TemplateDef>[_pump, _motor]);
      seedRecord();
      await open(tester);
      await tester.tap(choice('template-2'));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byType(RecordTemplateChange), findsNothing);
      expect(records.writes, isEmpty);
      expect(find.text(Copy.recordTemplateChanged()), findsNothing);
    });
  });

  group('states', () {
    testWidgets('with no other template the sheet names the next action, '
        'which opens the project templates', (WidgetTester tester) async {
      await declare(<TemplateDef>[_pump]);
      seedRecord();
      final GoRouter router = await open(tester);

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text(Copy.recordTemplateChangeEmptyHeadline), findsOneWidget);
      expect(find.text(Copy.recordTemplateChangeEmptyMessage), findsOneWidget);

      await tester.tap(find.text(Copy.recordTemplateChangeEmptyAction));
      await tester.pumpAndSettle();

      expect(find.byType(RecordTemplateChange), findsNothing);
      expect(router.state.uri.path, AppRoutes.projectTemplates('project-1'));
      expect(find.text('templates of project-1'), findsOneWidget);
    });

    testWidgets('templates that cannot be read show the failure with retry', (
      WidgetTester tester,
    ) async {
      seedRecord();
      await open(
        tester,
        overrides: <Override>[
          recordTemplateChangeChoicesProvider.overrideWith(
            (Ref _, String _) => Stream<List<TemplateDef>>.error(_unreadable),
          ),
        ],
      );

      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.text(_unreadable.message), findsOneWidget);
      expect(find.byType(AppPrimaryAction), findsNothing);
    });

    testWidgets('a record that cannot be read shows the failure', (
      WidgetTester tester,
    ) async {
      await declare(<TemplateDef>[_pump, _motor]);
      seedRecord();
      records.readFailure = _unreadable;
      await open(tester);

      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.byType(AppPrimaryAction), findsNothing);
    });

    testWidgets('while the templates load the sheet holds their place', (
      WidgetTester tester,
    ) async {
      final StreamController<List<TemplateDef>> pending =
          StreamController<List<TemplateDef>>();
      addTearDown(pending.close);
      seedRecord();
      await open(
        tester,
        overrides: <Override>[
          recordTemplateChangeChoicesProvider.overrideWith(
            (Ref _, String _) => pending.stream,
          ),
        ],
      );

      expect(find.byType(AppSkeleton), findsOneWidget);
      expect(find.byType(AppPrimaryAction), findsNothing);
    });

    testWidgets('a record that is gone says so', (WidgetTester tester) async {
      await declare(<TemplateDef>[_pump, _motor]);
      await open(tester);

      expect(find.text(Copy.recordTemplateChangeGoneHeadline), findsOneWidget);
      expect(find.byType(AppPrimaryAction), findsNothing);
    });
  });

  for (final ({String name, Size size, double scale}) layout
      in <({String name, Size size, double scale})>[
        (name: '393 dp', size: const Size(393, 886), scale: 1),
        (name: '800 dp', size: const Size(800, 1000), scale: 1),
        (name: '1200 dp', size: const Size(1200, 800), scale: 1),
        (name: 'landscape', size: const Size(886, 393), scale: 1),
        (name: '200 percent text', size: const Size(393, 886), scale: 2),
      ]) {
    testWidgets('at ${layout.name} the preview and Change template lay out', (
      WidgetTester tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = layout.size;
      tester.platformDispatcher.textScaleFactorTestValue = layout.scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await declare(<TemplateDef>[_pump, _motor]);
      seedRecord(status: RecordStatus.approved);
      await open(tester);
      final Finder body = find.descendant(
        of: find.byKey(const ValueKey<String>('record-template-change-body')),
        matching: find.byType(Scrollable),
      );

      await tester.scrollUntilVisible(
        choice('template-2'),
        Space.x12,
        scrollable: body,
      );
      await tester.ensureVisible(choice('template-2'));
      await tester.pumpAndSettle();
      await tester.tap(choice('template-2'));
      await tester.pumpAndSettle();
      // The preview scrolls under the pinned action, down to its last row.
      await tester.scrollUntilVisible(
        row('restored', 'rating'),
        Space.x12,
        scrollable: body,
      );
      await tester.ensureVisible(row('restored', 'rating'));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(row('restored', 'rating')).bottom,
        lessThanOrEqualTo(tester.getRect(body).bottom),
      );

      expect(tester.takeException(), isNull);
      expect(applyButton(tester).onPressed, isNotNull);
      final Rect action = tester.getRect(
        find.byKey(const ValueKey<String>('record-template-change-apply')),
      );
      expect(action.bottom, lessThanOrEqualTo(layout.size.height));
      expect(action.right, lessThanOrEqualTo(layout.size.width));
    });
  }
}
