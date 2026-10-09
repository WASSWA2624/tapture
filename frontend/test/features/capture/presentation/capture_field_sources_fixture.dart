import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/app.dart';
import 'package:tapture/app/nav_shell.dart';
import 'package:tapture/app/theme/dimensions.dart' show Space;
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/device/platform_facts.dart';
import 'package:tapture/core/files/text_store.dart';
import 'package:tapture/core/location/location_service.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_search_field.dart';
import 'package:tapture/core/widgets/fields/field_editor.dart';
import 'package:tapture/core/widgets/fields/field_value.dart';
import 'package:tapture/features/capture/data/capture_device_sources.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/presentation/capture_controller.dart';
import 'package:tapture/features/capture/presentation/capture_device_providers.dart';
import 'package:tapture/features/capture/presentation/capture_manual_form.dart';
import 'package:tapture/features/capture/presentation/capture_screen.dart';
import 'package:tapture/features/settings/settings.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/a11y_matchers.dart';
import '../../../support/empty_state_matchers.dart';
import '../../../support/factories.dart';
import '../../../support/screen_fonts.dart';
import '../../../support/screen_matrix.dart';
import '../../../support/screen_probe.dart';
import 'capture_workflow_fixture.dart';

/// Source checks reuse the production router/shell in native and actual Chrome.
void registerCaptureSourceTests({required bool browser}) {
  setUpAll(ScreenFonts.load);
  final TargetPlatformVariant platforms = TargetPlatformVariant(
    browser
        ? <TargetPlatform>{TargetPlatform.android}
        : <TargetPlatform>{
            TargetPlatform.android,
            TargetPlatform.iOS,
            TargetPlatform.windows,
            TargetPlatform.macOS,
            TargetPlatform.linux,
          },
  );
  for (final Locale locale in const <Locale>[
    Locale('en'),
    Locale('en', 'XA'),
  ]) {
    for (final ScreenMatrix cell in ScreenMatrix.cells) {
      testWidgets(
        'production Capture sources ${cell.description} ${locale.toLanguageTag()}',
        (WidgetTester tester) async {
          final SemanticsHandle semantics = tester.ensureSemantics();
          try {
            final List<String> locationCalls = <String>[];
            final CaptureWorkflowFixture fixture =
                await CaptureWorkflowFixture.open(
                  tester,
                  cell: cell,
                  locale: locale,
                  direction: locale.countryCode == 'XA'
                      ? TextDirection.rtl
                      : null,
                  shownTemplates: <TemplateDef>[
                    aTemplate(id: 't1', projectId: 'p1', fields: _fields),
                  ],
                  extraOverrides: <Override>[
                    captureDeviceIdProvider.overrideWithValue('source-app-id'),
                    currentOperatorProvider.overrideWithValue(
                      const OperatorProfile(
                        name: '  Source worker  ',
                        initials: 'SW',
                      ),
                    ),
                    locationServiceProvider.overrideWithValue(
                      LocationService.fake(
                        calls: locationCalls,
                        gpsEnabled: () => false,
                      ),
                    ),
                  ],
                );
            await revealScrollableBody(tester, find.byType(CaptureScreen));
            expect(
              find.byWidgetPredicate((Widget widget) => widget is TaptureApp),
              findsOneWidget,
            );
            expect(find.byType(NavShell), findsOneWidget);
            final ProviderContainer container = ProviderScope.containerOf(
              tester.element(find.byType(CaptureScreen)),
            );
            final CaptureController controller = container.read(
              captureControllerProvider('p1').notifier,
            );
            (await controller.setValue('manual', 'Typed value')).getOrThrow();
            (await controller.setValue(
              'business',
              'Retained automatic',
              source: 'AUTO',
            )).getOrThrow();
            await tester.pumpAndSettle();
            final List<String> initialLocationCalls = List<String>.of(
              locationCalls,
            );
            tester
                .widget<AppPage>(find.byType(AppPage))
                .overflow
                .firstWhere(
                  (action) =>
                      action.key ==
                      const ValueKey<String>('capture-manual-form'),
                )
                .onTap();
            await tester.pumpAndSettle();
            final LocalizedCopy copy = Copy.of(
              tester.element(find.byType(CaptureManualForm)),
            );
            final Map<String, String> states = <String, String>{
              'manual': copy.captureFieldManual,
              'district': copy.captureFieldContext,
              'business': copy.captureFieldAutomatic,
              'processing': copy.captureFieldProcessing,
              'ticket_number': copy.captureFieldFilledAtSave,
              'record_status': copy.captureFieldUnavailable,
              'device_id': copy.captureFieldFilledAtSave,
              'gps_latitude': copy.captureFieldUnavailable,
              'network_address': copy.captureFieldUnavailable,
              'opaque_source': copy.captureFieldUnavailable,
            };
            for (final MapEntry<String, String> expected in states.entries) {
              await _search(tester, expected.key);
              final Finder source = find.byKey(
                ValueKey<String>('capture-field-source-${expected.key}'),
              );
              await _revealRow(tester, source);
              await Scrollable.ensureVisible(
                tester.element(source),
                alignment: 0.5,
              );
              await tester.pumpAndSettle();
              expect(tester.widget<AppListTile>(source).title, expected.value);
              expect(
                tester.getSemantics(source).label,
                contains(expected.value),
              );
              expect(
                find.descendant(
                  of: source,
                  matching: find.text(expected.value),
                ),
                findsOneWidget,
              );
              if (locale.countryCode == 'XA') {
                expect(
                  Directionality.of(tester.element(source)),
                  TextDirection.rtl,
                );
              }
              if (expected.key == 'record_status' ||
                  expected.key == 'device_id' ||
                  expected.key == 'gps_latitude') {
                expect(_editor(expected.key), findsNothing);
                expect(
                  find.byKey(
                    ValueKey<String>('capture-field-correct-${expected.key}'),
                  ),
                  findsNothing,
                );
                if (expected.key == 'device_id') {
                  expect(find.text('source-app-id'), findsOneWidget);
                }
              } else if (expected.key == 'business' ||
                  expected.key == 'district') {
                final Finder correction = find.byKey(
                  ValueKey<String>('capture-field-correct-${expected.key}'),
                );
                await _revealRow(tester, correction);
                await Scrollable.ensureVisible(
                  tester.element(correction),
                  alignment: 0.5,
                );
                await tester.pumpAndSettle();
                expect(correction, meetsTapTarget());
                final Rect visible = tester
                    .getRect(correction)
                    .intersect(ScreenProbe.targetViewport(tester, correction));
                await tester.tapAt(visible.center);
                await tester.pumpAndSettle();
                expect(
                  tester
                      .widget<FieldEditor>(_editor(expected.key))
                      .value
                      .source,
                  expected.key == 'district'
                      ? ValueSource.context
                      : ValueSource.auto,
                );
              } else if (expected.key == 'manual' ||
                  expected.key == 'processing') {
                expect(
                  tester
                      .widget<FieldEditor>(_editor(expected.key))
                      .value
                      .source,
                  ValueSource.manual,
                );
              } else {
                expect(_editor(expected.key), findsNothing);
              }
              expect(ScreenProbe.layoutIssues(tester), isEmpty);
            }
            expect(fixture.records.persisted, isEmpty);
            expect(locationCalls, initialLocationCalls);
            expect(locationCalls, isNot(contains('requestPermission')));
            expect(
              controller.state.values.containsKey('ticket_number'),
              isFalse,
            );
            await _search(tester, 'business');
            final Finder editor = find.descendant(
              of: _editor('business'),
              matching: find.byType(TextField),
            );
            await _revealRow(tester, editor);
            await Scrollable.ensureVisible(tester.element(editor));
            await tester.enterText(editor, '');
            await tester.pumpAndSettle();
            expect(controller.state.values.containsKey('business'), isTrue);
            expect(controller.state.values['business'], isNull);
            expect(controller.state.valueSources['business'], 'TYPED');
            expect(
              tester.widget<FieldEditor>(_editor('business')).value.source,
              ValueSource.manual,
            );
            expect(
              tester
                  .widget<AppListTile>(
                    find.byKey(
                      const ValueKey<String>('capture-field-source-business'),
                    ),
                  )
                  .title,
              copy.captureFieldManual,
            );
            final String owner = controller.state.id;
            await _search(tester, 'district');
            await _search(tester, 'business');
            await _revealRow(tester, editor);
            expect(tester.widget<TextField>(editor).controller?.text, isEmpty);
            final CaptureSession saved =
                (await container
                        .read(capturePersistenceProvider)
                        .loadSession('p1'))
                    .getOrThrow()!;
            expect(saved.id, owner);
            expect(saved.values['business'], isNull);
            expect(saved.contextSnapshot['district'], 'North');
            expect(saved.valueSources['business'], 'TYPED');
            (await controller.setValue(
              'processing',
              'Read from the retained evidence',
              source: 'AI_TEXT',
            )).getOrThrow();
            await tester.pumpAndSettle();
            await _search(tester, 'processing');
            await _revealRow(tester, _editor('processing'));
            final FieldEditor processed = tester.widget<FieldEditor>(
              _editor('processing'),
            );
            expect(processed.value.value, 'Read from the retained evidence');
            expect(processed.value.source, ValueSource.aiText);
            expect(
              tester
                  .widget<AppListTile>(
                    find.byKey(
                      const ValueKey<String>('capture-field-source-processing'),
                    ),
                  )
                  .title,
              copy.captureFieldProcessing,
            );
            final CaptureSession evidence =
                (await container
                        .read(capturePersistenceProvider)
                        .loadSession('p1'))
                    .getOrThrow()!;
            expect(evidence.valueSources['processing'], 'AI_TEXT');
            expect(fixture.records.persisted, isEmpty);
            expect(ScreenProbe.layoutIssues(tester), isEmpty);
          } finally {
            semantics.dispose();
          }
        },
        variant: platforms,
      );
    }
  }

  testWidgets(
    'local address capability and explicit clear preserve real Capture source state',
    (WidgetTester tester) async {
      int reads = 0;
      CaptureDeviceSources? device;
      final CaptureWorkflowFixture fixture = await CaptureWorkflowFixture.open(
        tester,
        cell: ScreenMatrix.cells.first,
        shownTemplates: <TemplateDef>[
          aTemplate(id: 't1', projectId: 'p1', fields: _fields),
        ],
        extraOverrides: <Override>[
          if (!browser)
            captureDeviceSourceProvider.overrideWith((Ref ref, String key) {
              device = CaptureDeviceSources(
                clock: ref.read(captureClockProvider),
                readFacts: () async {
                  reads += 1;
                  return const PlatformFacts.fake(
                    addresses: <String>['10.0.0.2'],
                  );
                },
              );
              ref.onDispose(device!.dispose);
              return device!;
            }),
        ],
      );
      await revealScrollableBody(tester, find.byType(CaptureScreen));
      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(CaptureScreen)),
      );
      final CaptureController controller = container.read(
        captureControllerProvider('p1').notifier,
      );
      if (!browser) {
        final Future<void> completed = device!.changes.firstWhere(
          (_) => device!.snapshot(controller.state) != null,
        );
        device!.refresh();
        await tester.pump();
        await completed;
      }
      tester
          .widget<AppPage>(find.byType(AppPage))
          .overflow
          .firstWhere(
            (action) =>
                action.key == const ValueKey<String>('capture-manual-form'),
          )
          .onTap();
      await tester.pumpAndSettle();
      final LocalizedCopy copy = Copy.of(
        tester.element(find.byType(CaptureManualForm)),
      );
      await _search(tester, 'network_address');
      final Finder status = find.byKey(
        const ValueKey<String>('capture-field-source-network_address'),
      );
      await _revealRow(tester, status);
      expect(
        tester.widget<AppListTile>(status).title,
        browser ? copy.captureFieldUnavailable : copy.captureFieldFilledAtSave,
      );
      expect(reads, browser ? 0 : greaterThan(0));
      if (!browser) expect(find.text('10.0.0.2'), findsOneWidget);
      expect(_editor('network_address'), findsNothing);
      final Finder correct = find.byKey(
        const ValueKey<String>('capture-field-correct-network_address'),
      );
      await _revealRow(tester, correct);
      await Scrollable.ensureVisible(tester.element(correct), alignment: 0.5);
      await tester.pumpAndSettle();
      expect(correct, meetsTapTarget());
      await tester.tapAt(
        tester
            .getRect(correct)
            .intersect(ScreenProbe.targetViewport(tester, correct))
            .center,
      );
      await tester.pumpAndSettle();
      final Finder input = find.descendant(
        of: _editor('network_address'),
        matching: find.byType(TextField),
      );
      await _revealRow(tester, input);
      await Scrollable.ensureVisible(tester.element(input));
      await tester.enterText(input, 'Manual address');
      await tester.pumpAndSettle();
      expect(controller.state.values['network_address'], 'Manual address');
      expect(controller.state.valueSources['network_address'], 'TYPED');
      await tester.enterText(input, '');
      await tester.pumpAndSettle();
      expect(controller.state.values.containsKey('network_address'), isTrue);
      expect(controller.state.values['network_address'], isNull);
      expect(tester.widget<AppListTile>(status).title, copy.captureFieldManual);
      final CaptureSession saved =
          (await container.read(capturePersistenceProvider).loadSession('p1'))
              .getOrThrow()!;
      expect(saved.values.containsKey('network_address'), isTrue);
      expect(saved.values['network_address'], isNull);
      expect(saved.valueSources['network_address'], 'TYPED');
      expect(fixture.records.persisted, isEmpty);
      expect(ScreenProbe.layoutIssues(tester), isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
    variant: platforms,
  );
  testWidgets(
    'production date and time previews use explicit pickers and persist canonical typed corrections',
    (WidgetTester tester) async {
      final CaptureWorkflowFixture fixture = await CaptureWorkflowFixture.open(
        tester,
        cell: const ScreenMatrix(Size(800, 1280), 1, Brightness.light, false),
        shownTemplates: <TemplateDef>[
          aTemplate(
            id: 't1',
            projectId: 'p1',
            fields: const <FieldDef>[
              FieldDef(
                fieldKey: 'captured_date',
                label: 'Capture date',
                type: FieldType.date,
                group: 'record_admin',
                inputMode: InputMode.auto,
                requiredness: Requiredness.required,
              ),
              FieldDef(
                fieldKey: 'captured_time',
                label: 'Capture time',
                type: FieldType.time,
                group: 'record_admin',
                inputMode: InputMode.auto,
                requiredness: Requiredness.required,
              ),
            ],
          ),
        ],
      );
      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(CaptureScreen)),
      );
      final CaptureController controller = container.read(
        captureControllerProvider('p1').notifier,
      );
      tester
          .widget<AppPage>(find.byType(AppPage))
          .overflow
          .firstWhere(
            (action) =>
                action.key == const ValueKey<String>('capture-manual-form'),
          )
          .onTap();
      await tester.pumpAndSettle();
      for (final String key in <String>['captured_date', 'captured_time']) {
        await _search(tester, key);
        expect(_editor(key), findsNothing);
        expect(
          find.widgetWithText(AppListTile, Copy.captureFieldFilledAtSave),
          findsOneWidget,
        );
        final Finder correct = find.byKey(
          ValueKey<String>('capture-field-correct-$key'),
        );
        await tester.ensureVisible(correct);
        await tester.tap(correct);
        await tester.pumpAndSettle();
        expect(
          tester.widget<FieldEditor>(_editor(key)).value.source,
          ValueSource.auto,
        );
        final Finder input = find.descendant(
          of: _editor(key),
          matching: find.byType(TextField),
        );
        await tester.ensureVisible(input);
        await tester.tap(input);
        await tester.pumpAndSettle();
        if (key == 'captured_date') {
          expect(find.byType(DatePickerDialog), findsOneWidget);
          await tester.tap(
            find.descendant(
              of: find.byType(DatePickerDialog),
              matching: find.text('10'),
            ),
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
          if (find.text('AM').evaluate().isNotEmpty) {
            await tester.tap(find.text('AM'));
          }
        }
        await tester.pump();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(controller.state.valueSources[key], 'TYPED');
        expect(
          controller.state.values[key],
          key == 'captured_date' ? '2026-10-10' : '11:45:00',
        );
        expect(
          tester.widget<FieldEditor>(_editor(key)).value.source,
          ValueSource.manual,
        );
        expect(
          find.widgetWithText(AppListTile, Copy.captureFieldManual),
          findsOneWidget,
        );
      }
      final CaptureSession persisted =
          (await container.read(capturePersistenceProvider).loadSession('p1'))
              .getOrThrow()!;
      expect(persisted.values['captured_date'], '2026-10-10');
      expect(persisted.values['captured_time'], '11:45:00');
      expect(fixture.records.persisted, isEmpty);
      expect(ScreenProbe.layoutIssues(tester), isEmpty);
    },
    variant: platforms,
  );

  testWidgets(
    'restarted production Capture resumes typed override and null clear with their real sources',
    (WidgetTester tester) async {
      final TextStore durable = TextStore.memory();
      final List<TemplateDef> templates = <TemplateDef>[
        aTemplate(id: 't1', projectId: 'p1', fields: _fields),
      ];
      await CaptureWorkflowFixture.open(
        tester,
        cell: const ScreenMatrix(Size(800, 1280), 1, Brightness.light, false),
        store: durable,
        shownTemplates: templates,
      );
      ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(CaptureScreen)),
      );
      final CaptureController original = container.read(
        captureControllerProvider('p1').notifier,
      );
      (await original.setValue('business', null)).getOrThrow();
      (await original.setValue('manual', 'Restarted typed value')).getOrThrow();
      final String owner = original.state.id;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await CaptureWorkflowFixture.open(
        tester,
        cell: const ScreenMatrix(Size(800, 1280), 1, Brightness.light, false),
        store: durable,
        shownTemplates: templates,
      );
      await tester.tap(find.text(Copy.captureResume));
      await tester.pumpAndSettle();
      container = ProviderScope.containerOf(
        tester.element(find.byType(CaptureScreen)),
      );
      final CaptureSession resumed = container.read(
        captureControllerProvider('p1'),
      );
      expect(resumed.id, owner);
      expect(resumed.values['manual'], 'Restarted typed value');
      expect(resumed.values.containsKey('business'), isTrue);
      expect(resumed.values['business'], isNull);
      expect(resumed.valueSources['business'], 'TYPED');
      tester
          .widget<AppPage>(find.byType(AppPage))
          .overflow
          .firstWhere(
            (action) =>
                action.key == const ValueKey<String>('capture-manual-form'),
          )
          .onTap();
      await tester.pumpAndSettle();
      await _search(tester, 'business');
      final FieldEditor editor = tester.widget<FieldEditor>(
        _editor('business'),
      );
      expect(editor.value.value, isNull);
      expect(editor.value.source, ValueSource.manual);
      expect(
        tester
            .widget<AppListTile>(
              find.byKey(
                const ValueKey<String>('capture-field-source-business'),
              ),
            )
            .title,
        Copy.captureFieldManual,
      );
      await _search(tester, 'manual');
      expect(
        tester.widget<FieldEditor>(_editor('manual')).value.value,
        'Restarted typed value',
      );
      expect(ScreenProbe.layoutIssues(tester), isEmpty);
    },
    variant: platforms,
  );
}

Future<void> _search(WidgetTester tester, String key) async {
  final Finder input = find.descendant(
    of: find.byType(AppSearchField),
    matching: find.byType(TextField),
  );
  await _revealRow(tester, input, backwards: true);
  await Scrollable.ensureVisible(tester.element(input));
  await tester.enterText(input, key);
  await tester.pump(AppConstants.interaction.debounce);
  await tester.pumpAndSettle();
}

Future<void> _revealRow(
  WidgetTester tester,
  Finder row, {
  bool backwards = false,
}) async {
  final Finder scroll = find.byKey(
    const ValueKey<String>('capture-manual-form-scroll'),
  );
  final ScrollPosition position = tester
      .widget<CustomScrollView>(scroll)
      .controller!
      .position;
  if (backwards && row.evaluate().isEmpty) {
    position.jumpTo(position.minScrollExtent);
    await tester.pumpAndSettle();
    return;
  }
  while (row.evaluate().isEmpty && position.pixels < position.maxScrollExtent) {
    final double before = position.pixels;
    final Rect viewport = tester.getRect(scroll);
    final bool rtl =
        Directionality.of(tester.element(scroll)) == TextDirection.rtl;
    await tester.dragFrom(
      Offset(
        rtl ? viewport.right - Space.x2 : viewport.left + Space.x2,
        viewport.center.dy,
      ),
      Offset(0, -position.viewportDimension),
    );
    await tester.pumpAndSettle();
    if (position.pixels == before) break;
  }
}

Finder _editor(String key) => find.descendant(
  of: find.byKey(ValueKey<String>('manual-row-$key')),
  matching: find.byType(FieldEditor),
);

const List<FieldDef> _fields = <FieldDef>[
  FieldDef(
    fieldKey: 'network_address',
    label: 'Local network address',
    type: FieldType.text,
    autoFill: AutoFill.localAddress,
    requiredness: Requiredness.required,
  ),
  FieldDef(
    fieldKey: 'opaque_source',
    label: 'Unavailable stored source',
    type: FieldType.text,
    inputMode: InputMode.any,
    requiredness: Requiredness.required,
    validation: <String, Object?>{
      '_tapture': <String, Object?>{'autoFill': 'FUTURE_SENSOR'},
    },
  ),
  FieldDef(
    fieldKey: 'manual',
    label: 'Manual business value',
    type: FieldType.text,
    inputMode: InputMode.manualOnly,
    requiredness: Requiredness.required,
  ),
  FieldDef(
    fieldKey: 'district',
    label: 'District',
    type: FieldType.text,
    contextLevel: 0,
    requiredness: Requiredness.required,
  ),
  FieldDef(
    fieldKey: 'business',
    label: 'Automatic business value',
    type: FieldType.text,
    inputMode: InputMode.auto,
    requiredness: Requiredness.required,
  ),
  FieldDef(
    fieldKey: 'processing',
    label: 'Read from approved evidence',
    type: FieldType.text,
    requiredness: Requiredness.required,
  ),
  FieldDef(
    fieldKey: 'ticket_number',
    label: 'Ticket number',
    type: FieldType.number,
    autoFill: AutoFill.sequence,
    inputMode: InputMode.auto,
    requiredness: Requiredness.required,
  ),
  FieldDef(
    fieldKey: 'record_status',
    label: 'Record status',
    type: FieldType.text,
    inputMode: InputMode.auto,
    requiredness: Requiredness.required,
  ),
  FieldDef(
    fieldKey: 'device_id',
    label: 'App device ID',
    type: FieldType.text,
    group: 'record_admin',
    inputMode: InputMode.auto,
    requiredness: Requiredness.required,
  ),
  FieldDef(
    fieldKey: 'gps_latitude',
    label: 'Latitude',
    type: FieldType.gpsLocation,
    autoFill: AutoFill.gps,
    requiredness: Requiredness.required,
  ),
];
