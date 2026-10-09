import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/barcode/barcode_scanner_service.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/copy/l10n/app_localizations.g.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/photo_picker.dart';
import 'package:tapture/core/files/text_store.dart';
import 'package:tapture/core/location/location_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_photo_thumb.dart';
import 'package:tapture/core/widgets/app_search_field.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/fields/app_date_field.dart';
import 'package:tapture/core/widgets/fields/field_editor.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/capture/data/capture_persistence_impl.dart';
import 'package:tapture/features/capture/domain/capture_persistence.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/domain/capture_session_key.dart';
import 'package:tapture/features/capture/presentation/capture_controller.dart';
import 'package:tapture/features/capture/presentation/capture_manual_form.dart';
import 'package:tapture/features/capture/presentation/capture_screen.dart';
import 'package:tapture/features/capture/presentation/document_picker.dart';
import 'package:tapture/features/capture/presentation/inline_fields_section.dart';
import 'package:tapture/features/capture/presentation/photo_tray.dart';
import 'package:tapture/features/context/context.dart'
    show contextRepositoryProvider;
import 'package:tapture/features/context/domain/context_state.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/settings.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/a11y_matchers.dart';
import '../../../support/factories.dart';
import '../../../support/fakes/fake_barcode_scanner_service.dart';
import '../../../support/fakes/fake_capture_photo_repository.dart';
import '../../../support/fakes/fake_capture_record_persistence.dart';
import '../../../support/fakes/fake_context_repository.dart';
import '../../../support/pump_external_work.dart';
import '../../../support/screen_fonts.dart';
import '../../../support/screen_matrix.dart';
import '../../../support/tracked_photo_file.dart';
import '../../projects/fakes/fake_project_repository.dart';

void main() {
  testWidgets(
    'Manual previews use injected app identity clock operator and committed date settings without location reads',
    (WidgetTester tester) async {
      final DateTime now = DateTime.utc(2026, 10, 9, 9, 30);
      final SettingsStore preferences = SettingsStore.fake();
      final List<String> locationCalls = <String>[];
      final _Capture capture = await _Capture.open(
        tester,
        templates: <TemplateDef>[
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
                fieldKey: 'device_id',
                label: 'App device ID',
                type: FieldType.text,
                group: 'record_admin',
                inputMode: InputMode.auto,
                requiredness: Requiredness.required,
              ),
              FieldDef(
                fieldKey: 'operator_business',
                label: 'Operator',
                type: FieldType.text,
                autoFill: AutoFill.operator,
                requiredness: Requiredness.required,
              ),
              FieldDef(
                fieldKey: 'gps_latitude',
                label: 'Latitude',
                type: FieldType.gpsLocation,
                autoFill: AutoFill.gps,
                requiredness: Requiredness.required,
              ),
            ],
          ),
        ],
        location: LocationService.fake(calls: locationCalls),
        extraOverrides: <Override>[
          captureClockProvider.overrideWithValue(FixedClock(now)),
          captureDeviceIdProvider.overrideWithValue('profile-app-id'),
          currentOperatorProvider.overrideWithValue(
            const OperatorProfile(name: '  Field worker  ', initials: 'FW'),
          ),
          projectSettingsStoreProvider.overrideWithValue(preferences),
        ],
      );
      final List<String> before = List<String>.of(locationCalls);
      await capture.openManualForm();
      await _searchForm(tester, 'captured_date');
      final AppDateField date = tester.widget<AppDateField>(
        find.byType(AppDateField),
      );
      final DateTime local = now.toLocal();
      expect(date.value, DateTime(local.year, local.month, local.day));
      expect(date.enabled, isFalse);
      expect(
        find.widgetWithText(AppListTile, Copy.captureFieldFilledAtSave),
        findsOneWidget,
      );
      (await preferences.write(SettingKeys.autoFillDates, false)).getOrThrow();
      await tester.pumpAndSettle();
      expect(find.byType(AppDateField), findsNothing);
      expect(
        find.widgetWithText(AppListTile, Copy.captureFieldUnavailable),
        findsOneWidget,
      );
      await _searchForm(tester, 'device_id');
      expect(find.text('profile-app-id'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('capture-field-correct-device_id')),
        findsNothing,
      );
      await _searchForm(tester, 'operator_business');
      expect(find.text('Field worker'), findsOneWidget);
      await _searchForm(tester, 'gps_latitude');
      expect(
        find.widgetWithText(AppListTile, Copy.captureFieldUnavailable),
        findsOneWidget,
      );
      expect(find.byType(FieldEditor), findsNothing);
      expect(locationCalls, before);
      expect(capture.session.values, isEmpty);
      expect(capture.records.persisted, isEmpty);
    },
  );

  testWidgets(
    'Manual source preview resolves the pinned older shape and unknown history remains empty',
    (WidgetTester tester) async {
      final TemplateDef older = aTemplate(
        id: 't1',
        projectId: 'p1',
        fields: const <FieldDef>[
          FieldDef(
            fieldKey: 'captured_date',
            label: 'Pinned capture date',
            type: FieldType.date,
            group: 'record_admin',
            inputMode: InputMode.auto,
            requiredness: Requiredness.required,
          ),
        ],
      );
      final TemplateDef current = TemplateVersioning.remember(
        from: older,
        to: older.copyWith(
          version: 2,
          fields: const <FieldDef>[
            FieldDef(
              fieldKey: 'captured_date',
              label: 'Current manual value',
              type: FieldType.text,
              inputMode: InputMode.manualOnly,
              requiredness: Requiredness.required,
            ),
          ],
        ),
      );
      final _Capture capture = await _Capture.open(
        tester,
        templates: <TemplateDef>[current],
      );
      final CaptureController controller = capture._container.read(
        captureControllerProvider('p1').notifier,
      );
      (await controller.setTemplate('t1', version: 1)).getOrThrow();
      await tester.pumpAndSettle();
      await capture.openManualForm();
      expect(find.text('Current manual value'), findsNothing);
      expect(
        tester.widget<AppDateField>(find.byType(AppDateField)).label,
        'Pinned capture date',
      );
      expect(
        find.widgetWithText(AppListTile, Copy.captureFieldFilledAtSave),
        findsOneWidget,
      );
      await capture.dismissManualForm();
      (await controller.setTemplate('t1', version: 0)).getOrThrow();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AppPage>(find.byType(AppPage))
            .overflow
            .where(
              (AppOverflowAction action) =>
                  action.key == const ValueKey<String>('capture-manual-form'),
            ),
        isEmpty,
      );
      expect(find.byType(CaptureManualForm), findsNothing);
      expect(find.byType(FieldEditor), findsNothing);
      expect(find.byType(AppDateField), findsNothing);
      expect(find.byType(InlineFieldsSection), findsNothing);
    },
  );
  group('nothing is mandatory but one piece of evidence', () {
    testWidgets('a project with no templates can add a photo and save raw', (
      WidgetTester tester,
    ) async {
      final _Capture capture = await _Capture.open(
        tester,
        templates: const <TemplateDef>[],
      );

      expect(
        find.byKey(const ValueKey<String>('capture-no-templates')),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(AppButton, Copy.templatesAddChoices),
        findsOneWidget,
      );
      await capture.addLibraryPhoto();
      await capture.saveRaw();

      expect(capture.records.persisted.single.photos, hasLength(1));
      expect(capture.records.persisted.single.templateId, isEmpty);
      expect(find.text(Copy.captureSaved), findsOneWidget);
    });

    testWidgets('Save raw succeeds with one photo and an empty required '
        'field', (WidgetTester tester) async {
      final _Capture capture = await _Capture.open(
        tester,
        templates: <TemplateDef>[
          aTemplate(
            id: 't1',
            projectId: 'p1',
            fields: const <FieldDef>[_requiredSerial],
          ),
        ],
      );
      expect(find.text('Serial'), findsNothing);

      await capture.addLibraryPhoto();
      await capture.saveRaw();

      final CaptureSession saved = capture.records.persisted.single;
      expect(saved.photos, hasLength(1));
      expect(saved.values.containsKey('serial'), isFalse);
      expect(find.text(Copy.captureSaved), findsOneWidget);
    });

    testWidgets('a manual project captures a typed value and a photo and '
        'saves raw on one screen', (WidgetTester tester) async {
      final _Capture capture = await _Capture.open(
        tester,
        templates: <TemplateDef>[
          aTemplate(
            id: 't1',
            projectId: 'p1',
            fields: const <FieldDef>[_requiredSerial],
          ),
        ],
        settings: const ProjectSettings(templateChoice: 'manual'),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('capture-template-field')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test template').last);
      await tester.pumpAndSettle();
      await capture.openManualForm();
      await tester.enterText(_fieldInput('serial'), 'SN-1');
      await tester.pumpAndSettle();
      await capture.dismissManualForm();
      await capture.addLibraryPhoto();
      capture.navigation.pushed.clear();
      await capture.saveRaw();

      final CaptureSession saved = capture.records.persisted.single;
      expect(saved.values['serial'], 'SN-1');
      expect(saved.valueSources['serial'], 'TYPED');
      expect(saved.photos, hasLength(1));
      expect(saved.templateId, 't1');
      // Saved from the capture page itself: no review or other page opened.
      expect(
        capture.navigation.pushed.whereType<PageRoute<Object?>>(),
        isEmpty,
      );
      expect(find.byType(CaptureScreen), findsOneWidget);
    });
  });

  group('manual form', () {
    testWidgets(
      'search uses the owning draft pinned version and preserves its keys',
      (WidgetTester tester) async {
        final TemplateDef original = aTemplate(
          id: 't1',
          projectId: 'p1',
          fields: const <FieldDef>[_requiredSerial],
        );
        final TemplateDef latest = TemplateVersioning.remember(
          from: original,
          to: original.copyWith(
            version: 2,
            fields: const <FieldDef>[
              FieldDef(
                fieldKey: 'new_key',
                label: 'New field',
                type: FieldType.text,
                requiredness: Requiredness.required,
              ),
            ],
          ),
        );
        final _Capture capture = await _Capture.open(
          tester,
          templates: <TemplateDef>[latest],
        );
        await capture._container
            .read(captureControllerProvider('p1').notifier)
            .setTemplate('t1', version: 1);
        await tester.pumpAndSettle();
        await capture.openManualForm();
        final Finder search = find.descendant(
          of: find.byType(AppSearchField),
          matching: find.byType(TextField),
        );
        await tester.enterText(search, 'serial');
        await tester.pumpAndSettle(AppConstants.interaction.debounce);
        expect(_fieldInput('serial'), findsOneWidget);
        expect(_fieldInput('new_key'), findsNothing);
        await tester.enterText(_fieldInput('serial'), 'Pinned value');
        await tester.pumpAndSettle();
        expect(capture.session.templateVersion, 1);
        expect((await capture.stored())?.values['serial'], 'Pinned value');
        expect((await capture.stored())?.valueSources['serial'], 'TYPED');
      },
    );

    testWidgets('required-only template shows no More fields', (
      WidgetTester tester,
    ) async {
      final _Capture capture = await _Capture.open(
        tester,
        templates: <TemplateDef>[
          aTemplate(
            id: 't1',
            projectId: 'p1',
            fields: const <FieldDef>[_requiredSerial],
          ),
        ],
      );

      expect(find.text('Serial'), findsNothing);
      await capture.openManualForm();
      expect(find.text('Serial'), findsOneWidget);
      expect(find.text(Copy.captureMoreFields), findsNothing);
    });

    for (final (String, Size, bool) layout in const <(String, Size, bool)>[
      ('a phone', Size(360, 780), false),
      ('a medium window', Size(900, 800), true),
      ('an expanded window', Size(1280, 800), true),
    ]) {
      testWidgets('on ${layout.$1} manual fields open only from the menu', (
        WidgetTester tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = layout.$2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final _Capture capture = await _Capture.open(
          tester,
          templates: <TemplateDef>[
            aTemplate(
              id: 't1',
              projectId: 'p1',
              fields: const <FieldDef>[_requiredSerial],
            ),
          ],
        );

        expect(find.byType(InlineFieldsSection), findsNothing);
        expect(find.byType(PhotoTray), findsOneWidget);
        await capture.openManualForm();
        expect(find.byType(InlineFieldsSection), findsOneWidget);
        expect(
          tester.widget<AppBottomSheet>(find.byType(AppBottomSheet)).sidePanel,
          layout.$2.width >= 1024,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('a value failing the registry validator shows its error', (
      WidgetTester tester,
    ) async {
      final _Capture capture = await _Capture.open(
        tester,
        templates: <TemplateDef>[
          aTemplate(
            id: 't1',
            projectId: 'p1',
            fields: const <FieldDef>[
              FieldDef(
                fieldKey: 'serial',
                label: 'Serial',
                type: FieldType.text,
                requiredness: Requiredness.required,
                validation: <String, Object?>{'pattern': r'^SN-\d+$'},
              ),
            ],
          ),
        ],
      );

      await capture.openManualForm();
      await tester.enterText(_fieldInput('serial'), 'abc');
      await tester.pumpAndSettle();
      expect(
        find.text('That value does not match the expected pattern.'),
        findsOneWidget,
      );

      await tester.enterText(_fieldInput('serial'), 'SN-42');
      await tester.pumpAndSettle();
      expect(
        find.text('That value does not match the expected pattern.'),
        findsNothing,
      );
    });
  });

  testWidgets('every keystroke is in the stored session before the page is '
      'left', (WidgetTester tester) async {
    final _Capture capture = await _Capture.open(
      tester,
      templates: <TemplateDef>[
        aTemplate(
          id: 't1',
          projectId: 'p1',
          fields: const <FieldDef>[_requiredSerial],
        ),
      ],
    );

    await tester.enterText(_captionInput, 'Pump');
    await tester.pump();
    await capture.openManualForm();
    await tester.enterText(_fieldInput('serial'), 'S');
    await tester.pump();
    await tester.enterText(_fieldInput('serial'), 'SN');
    await tester.pump();

    // Read while the page is still up: a kill now loses nothing typed.
    expect(find.byType(CaptureScreen), findsOneWidget);
    final CaptureSession? stored = await capture.stored();
    expect(stored?.recordCaption, 'Pump');
    expect(stored?.values['serial'], 'SN');
  });

  testWidgets('a captured photo shows its cached thumbnail', (
    WidgetTester tester,
  ) async {
    final _Capture capture = await _Capture.open(tester);

    await capture.addLibraryPhoto();

    final String id = capture.photos.drafts.keys.single;
    final AppPhotoThumb thumb = tester.widget<AppPhotoThumb>(
      find.byKey(ValueKey<String>('photo-thumb-$id')),
    );
    expect(thumb.photo.thumbPath, capture.photos.thumbPathFor(id));
  });

  testWidgets('a slow location fix does not hold up Save raw', (
    WidgetTester tester,
  ) async {
    final _Capture capture = await _Capture.open(
      tester,
      location: LocationService.fake(
        delay: const Duration(minutes: 1),
        fix: GeoFix(
          latitude: 0.3,
          longitude: 32.5,
          accuracyMetres: 5,
          capturedAt: DateTime.utc(2026, 9, 29),
        ),
      ),
    );

    await capture.addLibraryPhoto();
    await capture.saveRaw();

    expect(capture.records.persisted.single.photos, hasLength(1));
    expect(capture.records.persisted.single.location, isNull);
    expect(find.text(Copy.captureSaved), findsOneWidget);
    // The fix lands once it comes, too late to hold the save up; the saved
    // record keeps what it was saved with.
    await tester.pump(const Duration(minutes: 1));
    expect(capture.records.persisted.single.location, isNull);
  });

  group('templates', () {
    testWidgets('with no template there is no picker and adding one is '
        'offered', (WidgetTester tester) async {
      await _Capture.open(tester, templates: const <TemplateDef>[]);

      expect(
        find.byKey(const ValueKey<String>('capture-template-field')),
        findsNothing,
      );
      expect(find.byType(AppBanner), findsOneWidget);
    });

    testWidgets('one template is shown and in use', (
      WidgetTester tester,
    ) async {
      final _Capture capture = await _Capture.open(
        tester,
        templates: <TemplateDef>[
          aTemplate(id: 't1', projectId: 'p1', name: 'Assets'),
        ],
      );

      expect(find.text('Assets'), findsOneWidget);
      expect(capture.session.templateId, 't1');
    });

    testWidgets('several templates list the most recently used first, then '
        'by name', (WidgetTester tester) async {
      final _Capture capture = await _Capture.open(
        tester,
        templates: <TemplateDef>[
          aTemplate(id: 't1', projectId: 'p1', name: 'Beta'),
          aTemplate(id: 't2', projectId: 'p1', name: 'Alpha'),
          aTemplate(id: 't3', projectId: 'p1', name: 'Gamma'),
          aTemplate(id: 't4', projectId: 'p1', name: 'Delta'),
        ],
        recent: const <String>['t3', 't1'],
      );
      // The last used is the default.
      expect(capture.session.templateId, 't3');

      await tester.tap(
        find.byKey(const ValueKey<String>('capture-template-field')),
      );
      await tester.pumpAndSettle();
      final List<double> rows = <double>[
        for (final String name in <String>['Gamma', 'Beta', 'Alpha', 'Delta'])
          tester.getTopLeft(find.text(name).last).dy,
      ];
      expect(rows, orderedEquals(List<double>.of(rows)..sort()));
    });

    testWidgets('a pinned template is still in force after a save and after '
        'a restart', (WidgetTester tester) async {
      final TextStore store = TextStore.memory();
      final List<TemplateDef> templates = <TemplateDef>[
        aTemplate(id: 't1', projectId: 'p1', name: 'Computers'),
        aTemplate(id: 't2', projectId: 'p1', name: 'Furniture'),
      ];
      const ProjectSettings manual = ProjectSettings(templateChoice: 'manual');
      final _Capture first = await _Capture.open(
        tester,
        templates: templates,
        settings: manual,
        store: store,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('capture-template-field')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Furniture').last);
      await tester.pumpAndSettle();
      await first.addLibraryPhoto();
      await first.saveRaw();

      expect(first.records.persisted.single.templateId, 't2');
      expect(first.session.photos, isEmpty);
      expect(first.session.templateId, 't2');

      // A restart: a new app over the same stored sessions.
      await tester.pumpWidget(const SizedBox.shrink());
      final _Capture restarted = await _Capture.open(
        tester,
        templates: templates,
        settings: manual,
        store: store,
      );
      expect(restarted.session.templateId, 't2');
      expect(find.text('Furniture'), findsOneWidget);
    });
  });

  group('a template pinned to a place', () {
    Future<FakeContextRepository> rooms(String room) async {
      final FakeContextRepository contexts = FakeContextRepository();
      addTearDown(contexts.dispose);
      await contexts.saveHierarchy('p1', const <ContextLevel>[
        ContextLevel(fieldKey: 'room', order: 0, label: 'Room'),
      ]);
      await contexts.setLevelValue(
        projectId: 'p1',
        fieldKey: 'room',
        value: room,
      );
      return contexts;
    }

    final List<TemplateDef> templates = <TemplateDef>[
      aTemplate(id: 't1', projectId: 'p1', name: 'Computers'),
      aTemplate(id: 't2', projectId: 'p1', name: 'Furniture'),
    ];

    testWidgets('applies again whenever capture is back at that level', (
      WidgetTester tester,
    ) async {
      final FakeContextRepository contexts = await rooms('Office');
      final _Capture capture = await _Capture.open(
        tester,
        templates: templates,
        settings: const ProjectSettings(
          templateChoice: 'manual',
          templatePins: <String, String>{'room=Office': 't1', 'room=Lab': 't2'},
        ),
        contexts: contexts,
      );
      expect(capture.session.templateId, 't1');

      for (final (String room, String template) in <(String, String)>[
        ('Lab', 't2'),
        ('Office', 't1'),
        ('Lab', 't2'),
      ]) {
        await contexts.setLevelValue(
          projectId: 'p1',
          fieldKey: 'room',
          value: room,
        );
        await tester.pumpAndSettle();
        expect(capture.session.contextSnapshot['room'], room);
        expect(capture.session.templateId, template, reason: room);
      }
    });

    testWidgets('the menu pins the template in use to the current level', (
      WidgetTester tester,
    ) async {
      final FakeProjectRepository projects = FakeProjectRepository();
      addTearDown(projects.dispose);
      await projects.create(aProject(id: 'p1'));
      await _Capture.open(
        tester,
        templates: templates,
        contexts: await rooms('Lab'),
        projects: projects,
      );

      final AppOverflowAction pin = tester
          .widget<AppPage>(find.byType(AppPage))
          .overflow
          .singleWhere(
            (AppOverflowAction action) =>
                action.label == Copy.templateChoicePin,
          );
      pin.onTap();
      await tester.pumpAndSettle();

      final Project stored = projects.stored.singleWhere(
        (Project project) => project.id == 'p1',
      );
      expect(
        stored.settings.templatePinFor(const <String, String>{'room': 'Lab'}),
        't1',
      );
      expect(find.text(Copy.captureTemplatePinned), findsOneWidget);
    });
  });

  group('with no project', () {
    testWidgets('the page says so, offers to create one and shows no saves', (
      WidgetTester tester,
    ) async {
      final FakeProjectRepository projects = FakeProjectRepository();
      addTearDown(projects.dispose);
      await _Capture.open(tester, projectId: '', projects: projects);

      final AppEmptyState empty = tester.widget<AppEmptyState>(
        find.byKey(const ValueKey<String>('capture-no-project')),
      );
      expect(empty.headline, Copy.captureCreateProjectFirst);
      expect(empty.actionLabel, Copy.projectCreateTitle);
      expect(empty.onAction, isNotNull);
      expect(find.text(Copy.captureSaveRaw), findsNothing);
      expect(find.text(Copy.captureNoPhotosHeadline), findsNothing);
    });

    testWidgets('any active project can be chosen, with or without '
        'templates', (WidgetTester tester) async {
      final FakeProjectRepository projects = FakeProjectRepository();
      addTearDown(projects.dispose);
      await projects.create(aProject(id: 'p1', name: 'Alpha'));
      await projects.create(aProject(id: 'p2', name: 'Beta'));
      final _Capture capture = await _Capture.open(
        tester,
        projectId: '',
        projects: projects,
        templates: const <TemplateDef>[],
      );
      expect(find.text(Copy.captureChooseProject), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('capture-project-field')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      await tester.tap(find.text('Beta'));
      await tester.pumpAndSettle();

      expect(find.text(Copy.captureChooseProject), findsNothing);
      expect(
        tester
            .widget<AppButton>(
              find.widgetWithText(AppButton, Copy.captureSaveRaw),
            )
            .onPressed,
        isNotNull,
      );
      expect(capture.addPhoto, findsOneWidget);
    });
  });

  testWidgets('the capture menu has no standalone rapid mode', (
    WidgetTester tester,
  ) async {
    await _Capture.open(tester);
    final AppPage page = tester.widget<AppPage>(find.byType(AppPage));
    expect(
      page.overflow.any(
        (AppOverflowAction action) => action.label == Copy.captureRapidMode,
      ),
      isFalse,
    );
    expect(find.byKey(const ValueKey<String>('rapid-next')), findsNothing);
  });

  testWidgets('on a wide short window the long manual form scrolls in its '
      'panel while evidence stays separate', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 480);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final _Capture capture = await _Capture.open(
      tester,
      templates: <TemplateDef>[
        aTemplate(
          id: 't1',
          projectId: 'p1',
          fields: <FieldDef>[
            for (int i = 0; i < 12; i++)
              FieldDef(
                fieldKey: 'f$i',
                label: 'Field $i',
                type: FieldType.text,
                requiredness: Requiredness.required,
              ),
          ],
        ),
      ],
    );

    expect(find.byType(InlineFieldsSection), findsNothing);
    await capture.openManualForm();
    await tester.scrollUntilVisible(
      _fieldInput('f11'),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(
              const ValueKey<String>('capture-manual-form-scroll'),
            ),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.enterText(_fieldInput('f11'), 'Last field');
    await tester.pumpAndSettle();
    expect((await capture.stored())?.values['f11'], 'Last field');
    await capture.dismissManualForm();
    expect(find.byType(PhotoTray), findsOneWidget);
    expect(find.byType(InlineFieldsSection), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('manual form edits survive dismiss reopen and resize', (
    WidgetTester tester,
  ) async {
    final _Capture capture = await _Capture.open(
      tester,
      templates: <TemplateDef>[
        aTemplate(
          id: 't1',
          projectId: 'p1',
          fields: const <FieldDef>[_requiredSerial],
        ),
      ],
    );
    await capture.openManualForm();
    await tester.enterText(_fieldInput('serial'), 'SN-42');
    await tester.pumpAndSettle();
    expect((await capture.stored())?.values['serial'], 'SN-42');
    tester.view.physicalSize = const Size(1200, 700);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(_fieldInput('serial')).controller?.text,
      'SN-42',
    );
    await capture.dismissManualForm();
    await capture.openManualForm();
    expect(
      tester.widget<TextField>(_fieldInput('serial')).controller?.text,
      'SN-42',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('manual barcode intake writes only the sheet owning project', (
    WidgetTester tester,
  ) async {
    final FakeBarcodeScannerService scanner = FakeBarcodeScannerService(
      hits: const <BarcodeHit>[
        BarcodeHit(rawValue: 'SN-42', format: 'code128'),
      ],
    );
    addTearDown(scanner.dispose);
    final _Capture capture = await _Capture.open(
      tester,
      templates: <TemplateDef>[
        aTemplate(
          id: 't1',
          projectId: 'p1',
          fields: <FieldDef>[_requiredSerial.copyWith(type: FieldType.barcode)],
        ),
      ],
      extraOverrides: <Override>[
        barcodeScannerServiceProvider.overrideWithValue(scanner),
      ],
    );
    final CaptureController other = capture._container.read(
      captureControllerProvider('p2').notifier,
    );
    (await other.setValue('serial', 'OTHER')).getOrThrow();
    await capture.openManualForm();
    await tester.tap(find.text(Copy.barcodeRescan));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.barcodeConfirm));
    await tester.pumpAndSettle();
    expect((await capture.stored())?.values['serial'], 'SN-42');
    expect(capture.session.valueSources['serial'], 'BARCODE');
    expect(other.state.values['serial'], 'OTHER');
    expect(find.byType(InlineFieldsSection), findsOneWidget);
    expect(scanner.startCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'record editing keeps visible document intake and no manual menu',
    (WidgetTester tester) async {
      const CaptureSession record = CaptureSession(
        id: 'saved-session',
        projectId: 'p1',
        recordId: 'record-1',
        editing: true,
        templateId: 't1',
        templateVersion: 1,
        contextSnapshot: <String, String>{},
        captions: <String, String>{'': 'Saved caption'},
        values: <String, Object?>{'serial': 'SN-1'},
      );
      final _Capture capture = await _Capture.open(tester, editSession: record);
      final AppPage page = tester.widget<AppPage>(find.byType(AppPage));
      expect(page.overflow, isEmpty);
      expect(find.byType(DocumentPicker), findsOneWidget);
      expect(find.byType(InlineFieldsSection), findsNothing);
      await tester.ensureVisible(_captionInput);
      await tester.enterText(_captionInput, 'Updated caption');
      await tester.pumpAndSettle();
      final CaptureSession editing = capture._container.read(
        captureControllerProvider(CaptureSessionKey.edit('record-1')),
      );
      expect(editing.recordCaption, 'Updated caption');
      expect(editing.values, record.values);
      expect(capture.session.hasContent, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed manual write retains input and retries without replacing '
      'the durable value', (WidgetTester tester) async {
    final _WritableStore store = _WritableStore();
    final _Capture capture = await _Capture.open(
      tester,
      store: store,
      templates: <TemplateDef>[
        aTemplate(
          id: 't1',
          projectId: 'p1',
          fields: const <FieldDef>[_requiredSerial],
        ),
      ],
    );
    await capture.openManualForm();
    await tester.enterText(_fieldInput('serial'), 'SN-1');
    await tester.pumpAndSettle();
    store.refusesWrites = true;
    await tester.enterText(_fieldInput('serial'), 'SN-2');
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(_fieldInput('serial')).controller?.text,
      'SN-2',
    );
    expect((await capture.stored())?.values['serial'], 'SN-1');
    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.textContaining('Session write failed'), findsWidgets);
    final Finder searchInput = find.descendant(
      of: find.byType(AppSearchField),
      matching: find.byType(TextField),
    );
    await tester.enterText(searchInput, 'no match');
    await tester.pumpAndSettle(AppConstants.interaction.debounce);
    expect(_fieldInput('serial'), findsNothing);
    expect(find.text(Copy.fieldsNoMatch), findsOneWidget);
    await tester.enterText(searchInput, 'serial');
    await tester.pumpAndSettle(AppConstants.interaction.debounce);
    expect(
      tester.widget<TextField>(_fieldInput('serial')).controller?.text,
      'SN-2',
    );
    expect(find.byType(AppErrorState), findsOneWidget);
    store.refusesWrites = false;
    await tester.ensureVisible(find.text(Copy.tryAgain));
    await tester.tap(find.text(Copy.tryAgain));
    await tester.pumpAndSettle();
    expect((await capture.stored())?.values['serial'], 'SN-2');
  });

  testWidgets('manual sheet scrolls above the keyboard at 200 percent text', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final _Capture capture = await _Capture.open(
      tester,
      templates: <TemplateDef>[
        aTemplate(
          id: 't1',
          projectId: 'p1',
          fields: const <FieldDef>[_requiredSerial],
        ),
      ],
    );
    await capture.openManualForm();
    await tester.ensureVisible(_fieldInput('serial'));
    await tester.enterText(_fieldInput('serial'), 'SN-7');
    await tester.pumpAndSettle();
    expect((await capture.stored())?.values['serial'], 'SN-7');
    expect(tester.takeException(), isNull);
  });

  for (final Locale locale in const <Locale>[
    Locale('en'),
    Locale('en', 'XA'),
  ]) {
    for (final ScreenMatrix cell in ScreenMatrix.cells) {
      testWidgets('capture menu and manual form fit ${cell.description} '
          '${locale.toLanguageTag()}', (WidgetTester tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = cell.size;
        tester.platformDispatcher.textScaleFactorTestValue = cell.textScale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final _Capture capture = await _Capture.open(
          tester,
          locale: locale,
          brightness: cell.brightness,
          outdoor: cell.outdoor,
          templates: <TemplateDef>[
            aTemplate(
              id: 't1',
              projectId: 'p1',
              fields: const <FieldDef>[_requiredSerial],
            ),
          ],
        );
        final AppPage page = tester.widget<AppPage>(find.byType(AppPage));
        expect(
          page.overflow.map((AppOverflowAction action) => action.key),
          containsAll(const <ValueKey<String>>[
            ValueKey<String>('capture-manual-form'),
            ValueKey<String>('capture-import-document'),
          ]),
        );
        expect(find.byType(InlineFieldsSection), findsNothing);
        expect(find.byType(DocumentPicker), findsNothing);
        expect(
          find.byKey(const ValueKey<String>('capture-rapid-mode')),
          findsNothing,
        );
        expect(find.byType(PhotoTray), findsOneWidget);
        await capture.openManualForm();
        expect(find.byType(AppBottomSheet), findsOneWidget);
        final Finder searchInput = find.descendant(
          of: find.byType(AppSearchField),
          matching: find.byType(TextField),
        );
        await tester.ensureVisible(searchInput);
        await tester.enterText(searchInput, ' SERIAL ');
        await tester.pumpAndSettle(AppConstants.interaction.debounce);
        final LocalizedCopy localCopy = Copy.of(
          tester.element(find.byType(CaptureManualForm)),
        );
        expect(
          find.byWidgetPredicate(
            (Widget widget) =>
                widget is Semantics &&
                widget.properties.liveRegion == true &&
                widget.properties.label == localCopy.fieldsCount(1),
          ),
          findsOneWidget,
        );
        await tester.enterText(searchInput, 'unknown field');
        await tester.pumpAndSettle(AppConstants.interaction.debounce);
        final Finder formScroll = find
            .descendant(
              of: find.byKey(
                const ValueKey<String>('capture-manual-form-scroll'),
              ),
              matching: find.byWidgetPredicate(
                (Widget widget) =>
                    widget is Scrollable &&
                    widget.axisDirection == AxisDirection.down,
              ),
            )
            .first;
        await tester.scrollUntilVisible(
          find.text(localCopy.fieldsNoMatch),
          tester.getSize(formScroll).height / 2,
          scrollable: formScroll,
        );
        expect(find.text(localCopy.fieldsNoMatch), findsOneWidget);
        expect(find.text(localCopy.searchNoMatchMessage), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (Widget widget) =>
                widget is Semantics &&
                widget.properties.liveRegion == true &&
                widget.properties.label == localCopy.fieldsCount(0),
          ),
          findsOneWidget,
        );
        await tester.scrollUntilVisible(
          searchInput,
          -tester.getSize(formScroll).height / 2,
          scrollable: formScroll,
        );
        await tester.tap(
          find.byTooltip(localCopy.clearField(localCopy.captureSearchFields)),
        );
        await tester.pumpAndSettle(AppConstants.interaction.debounce);
        await tester.scrollUntilVisible(
          _fieldInput('serial'),
          tester.getSize(formScroll).height / 2,
          scrollable: formScroll,
        );
        await tester.enterText(_fieldInput('serial'), 'SN-42');
        await tester.pumpAndSettle();
        expect((await capture.stored())?.values['serial'], 'SN-42');
        expect(_fieldInput('serial'), meetsTapTarget());
        await capture.dismissManualForm();
        expect(find.byType(InlineFieldsSection), findsNothing);
        expect(tester.takeException(), isNull);
      }, variant: TargetPlatformVariant.all());
    }
  }

  for (final ({String name, ScreenMatrix cell}) corner
      in ScreenMatrix.corners) {
    testWidgets('capture composition golden ${corner.name}', (
      WidgetTester tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = corner.cell.size;
      tester.platformDispatcher.textScaleFactorTestValue =
          corner.cell.textScale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.runAsync(ScreenFonts.load);
      await _Capture.open(
        tester,
        brightness: corner.cell.brightness,
        outdoor: corner.cell.outdoor,
        templates: <TemplateDef>[
          aTemplate(
            id: 't1',
            projectId: 'p1',
            fields: const <FieldDef>[_requiredSerial],
          ),
        ],
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/capture_composition_${corner.name}.png'),
      );
    });
  }
}

const FieldDef _requiredSerial = FieldDef(
  fieldKey: 'serial',
  label: 'Serial',
  type: FieldType.text,
  requiredness: Requiredness.required,
);

Finder _fieldInput(String fieldKey) => find.descendant(
  of: find.byKey(ValueKey<String>('field-editor-text-$fieldKey')),
  matching: find.byType(TextField),
);

final Finder _captionInput = find.byWidgetPredicate(
  (Widget widget) =>
      widget is TextField &&
      widget.decoration?.labelText == Copy.captureRecordCaption,
);

/// Pages pushed while a test watches.
final class _Navigation extends NavigatorObserver {
  final List<Route<Object?>> pushed = <Route<Object?>>[];

  @override
  void didPush(Route<Object?> route, Route<Object?>? previousRoute) {
    pushed.add(route);
  }
}

/// A capture page over in-memory stores.
Future<void> _searchForm(WidgetTester tester, String query) async {
  final Finder input = find.descendant(
    of: find.byType(AppSearchField),
    matching: find.byType(TextField),
  );
  await tester.ensureVisible(input);
  await tester.enterText(input, query);
  await tester.pumpAndSettle(AppConstants.interaction.debounce);
}

final class _Capture {
  _Capture._(this._tester, this.photos, this.records, this.navigation);

  final WidgetTester _tester;

  /// Photo rows, bytes and thumbnails.
  final FakeCapturePhotoRepository photos;

  /// Records the saves froze.
  final FakeCaptureRecordPersistence records;

  /// Routes pushed.
  final _Navigation navigation;

  static Future<_Capture> open(
    WidgetTester tester, {
    String projectId = 'p1',
    List<TemplateDef>? templates,
    List<String> recent = const <String>[],
    ProjectSettings settings = const ProjectSettings(),
    TextStore? store,
    LocationService? location,
    FakeProjectRepository? projects,
    FakeContextRepository? contexts,
    GoRouter? router,
    Locale? locale,
    Brightness brightness = Brightness.light,
    bool outdoor = false,
    CaptureSession? editSession,
    List<Override> extraOverrides = const <Override>[],
  }) async {
    final Directory thumbs = Directory.systemTemp.createTempSync(
      'tapture-capture-thumbs-',
    );
    addTearDown(() => thumbs.deleteSync(recursive: true));
    final FakeCapturePhotoRepository photos = FakeCapturePhotoRepository(
      thumbs: thumbs,
    );
    final FakeCaptureRecordPersistence records = FakeCaptureRecordPersistence();
    if (editSession != null) {
      records.records[editSession.recordId!] = editSession;
    }
    final _Navigation navigation = _Navigation();
    final TextStore sessions = store ?? TextStore.memory();
    final List<TemplateDef> shown =
        templates ??
        <TemplateDef>[aTemplate(id: 't1', projectId: 'p1', name: 'Assets')];
    final List<Override> overrides = <Override>[
      fieldEditorBindingsProvider.overrideWithValue(
        templateFieldEditorBindings,
      ),
      captureProjectTemplatesProvider.overrideWith(
        (Ref _, String id) => Stream<List<TemplateDef>>.value(
          id == 'p1' || id == 'p2' ? shown : const <TemplateDef>[],
        ),
      ),
      captureRecentTemplatesProvider.overrideWith(
        (Ref _, String _) async => recent,
      ),
      photoRepositoryProvider.overrideWith((Ref _) => photos),
      capturePersistenceProvider.overrideWith(
        (Ref _) => CapturePersistenceImpl(photos: photos, store: sessions),
      ),
      captureRecordWriterProvider.overrideWith((Ref _) => records),
      photoPickerProvider.overrideWith(
        (Ref _) => PhotoPicker.fake(photos: <Uint8List>[_bytes]),
      ),
      if (projectId.isNotEmpty)
        currentProjectDetailsProvider.overrideWith(
          (Ref _) => aProject(id: projectId).copyWith(settings: settings),
        ),
      if (projects != null)
        projectRepositoryProvider.overrideWith((Ref _) => projects),
      if (location != null)
        locationServiceProvider.overrideWith((Ref _) => location),
      if (contexts != null)
        contextRepositoryProvider.overrideWith((Ref _) => contexts),
      ...extraOverrides,
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: router == null
            ? MaterialApp(
                locale: locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                theme: ScreenFonts.theme(
                  buildTheme(brightness: brightness, outdoor: outdoor),
                ),
                navigatorObservers: <NavigatorObserver>[navigation],
                home: Scaffold(
                  body: CaptureScreen(
                    projectId: projectId,
                    recordId: editSession?.recordId,
                  ),
                ),
              )
            : MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return _Capture._(tester, photos, records, navigation);
  }

  /// The empty tray's add action.
  Finder get addPhoto =>
      find.byKey(const ValueKey<String>('empty-state-icon-action'));

  ProviderContainer get _container =>
      ProviderScope.containerOf(_tester.element(find.byType(CaptureScreen)));

  /// The live session of project `p1`.
  CaptureSession get session =>
      _container.read(captureControllerProvider('p1'));

  /// The session as stored now.
  Future<CaptureSession?> stored() async {
    final CapturePersistence persistence = _container.read(
      capturePersistenceProvider,
    );
    final Result<CaptureSession?> loaded = await persistence.loadSession('p1');
    return loaded.getOrElse(() => null);
  }

  /// Adds one photo through the add sheet's library action.
  Future<void> addLibraryPhoto() async {
    final int before = session.photos.length;
    final Completer<void> added = Completer<void>();
    final subscription = _container.listen<CaptureSession>(
      captureControllerProvider('p1'),
      (CaptureSession? _, CaptureSession next) {
        if (next.photos.length > before && !added.isCompleted) added.complete();
      },
    );
    final Finder add = session.photos.isEmpty
        ? addPhoto
        : find.byTooltip(Copy.captureAddPhoto);
    await _tester.tap(add);
    await _tester.pumpAndSettle();
    try {
      await _tester.tap(find.text(Copy.captureChoosePhoto));
      await _tester.pumpAndSettle();
      await pumpExternalWork(_tester, () => added.isCompleted);
    } finally {
      subscription.close();
    }
    await _tester.pumpAndSettle();
  }

  /// Taps Save raw and lets the save land.
  Future<void> saveRaw() async {
    await _tester.tap(find.widgetWithText(AppButton, Copy.captureSaveRaw));
    await _tester.pumpAndSettle();
  }

  Future<void> openManualForm() async {
    final AppPage page = _tester.widget<AppPage>(find.byType(AppPage));
    page.overflow
        .singleWhere(
          (AppOverflowAction action) =>
              action.key == const ValueKey<String>('capture-manual-form'),
        )
        .onTap();
    await _tester.pumpAndSettle();
  }

  Future<void> dismissManualForm() async {
    Navigator.of(_tester.element(find.byType(CaptureManualForm))).pop();
    await _tester.pumpAndSettle();
  }
}

final class _WritableStore implements TextStore {
  final TextStore _backing = TextStore.memory();
  bool refusesWrites = false;

  @override
  String? read() => _backing.read();

  @override
  Future<void> write(String contents) async {
    if (refusesWrites) throw StateError('Session write failed');
    await _backing.write(contents);
  }
}

final Uint8List _bytes = pickedPhotoBytes();
