import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/router.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/fields/app_checkbox_group.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/settings.dart';
import 'package:tapture/features/templates/domain/shipped_template_category.dart';
import 'package:tapture/features/templates/presentation/shipped_library_filter.dart';
import 'package:tapture/features/templates/presentation/shipped_picker_screen.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';
import '../../projects/fakes/fake_project_repository.dart';
import '../fakes/fake_shipped_template_loader.dart';

void main() {
  testWidgets('loading renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    final Completer<List<ShippedTemplateEntry>> pending =
        Completer<List<ShippedTemplateEntry>>();
    await _pump(
      tester,
      overrides: <Override>[
        shippedLibraryProvider.overrideWith((Ref _) => pending.future),
      ],
    );
    await tester.pump();

    expect(find.byType(AppSkeleton), findsOneWidget);
  });

  testWidgets('an empty library renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      overrides: <Override>[
        shippedLibraryProvider.overrideWith(
          (Ref _) async => const <ShippedTemplateEntry>[],
        ),
      ],
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text(Copy.templatesLibraryEmptyHeadline), findsOneWidget);
    expect(find.text(Copy.templatesLibraryEmptyMessage), findsOneWidget);
  });

  testWidgets('a failed load renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      overrides: <Override>[
        shippedLibraryProvider.overrideWith(
          (Ref _) => Future<List<ShippedTemplateEntry>>.error(
            const StorageFailure(
              message: 'The shipped templates could not be read.',
              recoveryAction: 'Try again.',
            ),
          ),
        ),
      ],
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(
      find.text('The shipped templates could not be read.'),
      findsOneWidget,
    );
  });

  testWidgets('offline renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      overrides: <Override>[
        shippedLibraryProvider.overrideWith(
          (Ref _) =>
              Future<List<ShippedTemplateEntry>>.error(const NetworkFailure()),
        ),
      ],
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text(const NetworkFailure().message), findsOneWidget);
  });

  testWidgets('pick, preview and add copies the resolved fields', (
    WidgetTester tester,
  ) async {
    final FakeShippedTemplateLoader loader = FakeShippedTemplateLoader()
      ..rows.add(
        const TemplateDef(
          id: '',
          templateKey: 'generic_item',
          name: 'templates.generic_item.name',
          version: 1,
          fields: <FieldDef>[
            FieldDef(
              fieldKey: 'item_name',
              label: 'templates.generic_item.item_name',
              type: FieldType.text,
            ),
            FieldDef(
              fieldKey: 'site_code',
              label: 'templates.groups.location_context.site_code',
              type: FieldType.text,
            ),
          ],
          identityFieldKeys: <String>['item_name'],
          rows: <TemplateRow>[],
          kind: 'generic',
          source: 'shipped',
        ),
      );
    await _pump(
      tester,
      openProject: true,
      withRouter: true,
      overrides: <Override>[
        shippedTemplateLoaderProvider.overrideWith((Ref _) => loader),
      ],
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(AppSectionHeader), findsOneWidget);
    expect(find.text(Copy.shippedCategoryTitle('general')), findsOneWidget);
    expect(find.byType(AppListTile), findsOneWidget);
    expect(find.byType(AppCheckboxGroup<String>), findsNothing);
    expect(find.text(Copy.shippedTemplateName('generic_item')), findsOneWidget);
    expect(find.text(Copy.fieldsCount(2)), findsOneWidget);

    await tester.tap(find.byType(AppListTile));
    await tester.pump();
    await tester.pump();

    expect(
      find.text(Copy.shippedLabel('templates.generic_item.item_name')),
      findsWidgets,
    );
    expect(
      find.text(
        Copy.shippedLabel('templates.groups.location_context.site_code'),
      ),
      findsOneWidget,
    );
    expect(find.text(Copy.templatesAddToProject), findsOneWidget);

    await tester.tap(find.byType(AppPrimaryAction));
    await tester.pump();
    await tester.pump();

    expect(loader.copies, hasLength(1));
    expect(loader.copies.single.name, Copy.shippedTemplateName('generic_item'));
    expect(loader.copies.single.projectId, 'project-1');
    expect(loader.copies.single.version, 1);
    expect(find.text('fields'), findsOneWidget);
  });

  testWidgets('selected shipped templates save onto the project', (
    WidgetTester tester,
  ) async {
    final FakeShippedTemplateLoader loader = FakeShippedTemplateLoader()
      ..rows.addAll(<TemplateDef>[
        const TemplateDef(
          id: '',
          templateKey: 'generic_item',
          name: 'templates.generic_item.name',
          version: 1,
          fields: <FieldDef>[],
          identityFieldKeys: <String>[],
          rows: <TemplateRow>[],
          kind: 'generic',
          source: 'shipped',
        ),
        const TemplateDef(
          id: '',
          templateKey: 'equipment_asset',
          name: 'templates.equipment_asset.name',
          version: 1,
          fields: <FieldDef>[],
          identityFieldKeys: <String>[],
          rows: <TemplateRow>[],
          kind: 'asset',
          source: 'shipped',
        ),
      ]);
    await _pump(
      tester,
      openProject: true,
      withRouter: true,
      overrides: <Override>[
        shippedTemplateLoaderProvider.overrideWith((Ref _) => loader),
      ],
    );
    await tester.pump();
    await tester.pump();

    expect(
      tester
          .widget<AppPrimaryAction>(
            find.ancestor(
              of: find.text(Copy.save),
              matching: find.byType(AppPrimaryAction),
            ),
          )
          .onPressed,
      isNull,
    );
    await tester.longPress(find.byType(AppListTile).at(0));
    await tester.longPress(find.byType(AppListTile).at(1));
    await tester.pump();
    await tester.tap(find.text(Copy.save));
    await tester.pump();
    await tester.pump();

    expect(loader.copies, hasLength(2));
    expect(
      loader.copies.map((TemplateDef row) => row.templateKey),
      containsAll(<String>['generic_item', 'equipment_asset']),
    );
    expect(
      loader.copies.every((TemplateDef row) => row.projectId == 'project-1'),
      isTrue,
    );
  });

  testWidgets('the library is one list grouped under seven categories', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 20000);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _pump(
      tester,
      overrides: <Override>[
        shippedLibraryProvider.overrideWith(
          (Ref _) async => <ShippedTemplateEntry>[
            for (final ShippedTemplateCategory category
                in ShippedTemplateCategory.values.reversed)
              for (final String key in category.templateKeys) _shipped(key),
          ],
        ),
      ],
    );
    await tester.pumpAndSettle();

    final List<String> headings = <String>[
      for (final AppSectionHeader header in tester.widgetList<AppSectionHeader>(
        find.byType(AppSectionHeader),
      ))
        header.title,
    ];
    expect(headings, <String>[
      for (final ShippedTemplateCategory category
          in ShippedTemplateCategory.values)
        Copy.shippedCategoryTitle(category.name),
    ]);
    expect(find.byType(AppCheckboxGroup<String>), findsNothing);
    expect(find.byType(AppListTile), findsNWidgets(23));
    final double search = tester.getBottomLeft(find.byType(EditableText)).dy;
    final double firstHeading = tester
        .getTopLeft(find.byType(AppSectionHeader).first)
        .dy;
    expect(firstHeading, greaterThan(search));
  });

  testWidgets(
    'search matches names and categories, and a miss sits at the top',
    (WidgetTester tester) async {
      await _pump(
        tester,
        overrides: <Override>[
          shippedLibraryProvider.overrideWith(
            (Ref _) async => <ShippedTemplateEntry>[
              _shipped('generic_item'),
              _shipped('meter_reading'),
              _shipped('livestock_animal'),
              _shipped('plant_tree'),
            ],
          ),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppListTile, 'Generic'), findsOneWidget);
      expect(find.widgetWithText(AppListTile, 'Meter reading'), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'meter');
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.widgetWithText(AppListTile, 'Meter reading'), findsOneWidget);
      expect(find.widgetWithText(AppListTile, 'Generic'), findsNothing);

      await tester.enterText(find.byType(EditableText), 'animals');
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.widgetWithText(AppListTile, 'Livestock / Animal'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(AppListTile, 'Plant / Tree survey'),
        findsOneWidget,
      );
      expect(find.widgetWithText(AppListTile, 'Meter reading'), findsNothing);

      await tester.enterText(find.byType(EditableText), 'audit');
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(Copy.shippedLibraryNoMatch('audit')), findsOneWidget);
      expect(find.byType(AppListTile), findsNothing);
      expect(find.byType(Checkbox), findsNothing);
      expect(find.byType(EditableText), findsOneWidget);
      final double search = tester.getBottomLeft(find.byType(EditableText)).dy;
      final double empty = tester.getTopLeft(find.byType(AppEmptyState)).dy;
      expect(empty - search, lessThan(64));
    },
  );

  group('the full catalogue', () {
    testWidgets('lists under area and category headings after the starters', (
      WidgetTester tester,
    ) async {
      _tall(tester);
      await _pump(
        tester,
        overrides: <Override>[
          shippedLibraryProvider.overrideWith(
            (Ref _) async => <ShippedTemplateEntry>[
              _shipped('generic_item'),
              ..._catalogue,
            ],
          ),
        ],
      );
      await tester.pumpAndSettle();

      final List<String> headings = <String>[
        for (final AppSectionHeader header
            in tester.widgetList<AppSectionHeader>(
              find.byType(AppSectionHeader),
            ))
          header.title,
      ];
      expect(headings, <String>[
        Copy.shippedStarterArea,
        Copy.shippedCategoryTitle('general'),
        Copy.shippedAreaTitle('01', 'Cross-sector foundations'),
        Copy.shippedCatalogueCategoryTitle(
          'UNI',
          'Universal capture and records',
        ),
        Copy.shippedAreaTitle('02', 'Business and governance'),
        Copy.shippedCatalogueCategoryTitle(
          'FIN',
          'Finance accounting and expenses',
        ),
      ]);
      expect(find.byType(AppListTile), findsNWidgets(4));
      expect(
        find.text(
          Copy.shippedCatalogueSubtitle(
            'UNI-001',
            'Observation / evidence capture',
            67,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('search matches code, record type, category and fields', (
      WidgetTester tester,
    ) async {
      _tall(tester);
      await _pump(
        tester,
        overrides: <Override>[
          shippedLibraryProvider.overrideWith(
            (Ref _) async => <ShippedTemplateEntry>[
              _shipped('generic_item'),
              ..._catalogue,
            ],
          ),
        ],
      );
      await tester.pumpAndSettle();

      Future<List<String>> shownFor(String query) async {
        await tester.enterText(find.byType(EditableText), query);
        await tester.pump(const Duration(milliseconds: 400));
        return <String>[
          for (final AppListTile tile in tester.widgetList<AppListTile>(
            find.byType(AppListTile),
          ))
            tile.title,
        ];
      }

      expect(await shownFor('uni-002'), <String>['Voice field note']);
      expect(await shownFor('transaction'), <String>['Invoice OCR intake']);
      expect(await shownFor('finance'), <String>['Invoice OCR intake']);
      expect(await shownFor('transcript language'), <String>[
        'Voice field note',
      ]);
      expect(await shownFor('observation foundations'), <String>[
        'General observation',
        'Voice field note',
      ]);
    });

    testWidgets('filters narrow by area, record type and tier', (
      WidgetTester tester,
    ) async {
      _tall(tester);
      await _pump(
        tester,
        overrides: <Override>[
          shippedLibraryProvider.overrideWith(
            (Ref _) async => <ShippedTemplateEntry>[
              _shipped('generic_item'),
              ..._catalogue,
            ],
          ),
        ],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('search-filter')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('shipped-area-filter')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('shipped-record-type-filter')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('shipped-tier-filter')),
        findsOneWidget,
      );
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(ShippedPickerScreen)),
      );
      final ShippedLibraryFilter filter = container.read(
        shippedLibraryFilterProvider.notifier,
      );
      filter.setRecordTypes(<String>{'OBS'});
      await tester.pumpAndSettle();
      expect(find.byType(AppListTile), findsNWidgets(2));
      expect(find.widgetWithText(AppListTile, 'Generic'), findsNothing);

      filter
        ..clear()
        ..setAreas(<String>{starterArea});
      await tester.pumpAndSettle();
      expect(find.byType(AppListTile), findsOneWidget);
      expect(find.widgetWithText(AppListTile, 'Generic'), findsOneWidget);

      filter
        ..clear()
        ..setTiers(<String>{'p2'});
      await tester.pumpAndSettle();
      expect(find.byType(AppListTile), findsOneWidget);
      expect(
        find.widgetWithText(AppListTile, 'Invoice OCR intake'),
        findsOneWidget,
      );
    });

    testWidgets('preview shows what the template is and adds it by title', (
      WidgetTester tester,
    ) async {
      _tall(tester);
      final FakeShippedTemplateLoader loader = FakeShippedTemplateLoader()
        ..rows.add(
          const TemplateDef(
            id: '',
            templateKey: 'uni_general_observation',
            name: 'templates.uni_general_observation.name',
            version: 1,
            fields: <FieldDef>[
              FieldDef(
                fieldKey: 'observation_subject',
                label: 'templates.catalogue.observation_subject',
                type: FieldType.text,
                requiredness: Requiredness.required,
                group: 'observation',
              ),
              FieldDef(
                fieldKey: 'observation_category',
                label: 'templates.catalogue.observation_category',
                type: FieldType.text,
                requiredness: Requiredness.recommended,
                group: 'specific_details',
              ),
            ],
            identityFieldKeys: <String>['observation_subject'],
            rows: <TemplateRow>[],
            kind: 'observation',
            source: 'shipped',
          ),
        )
        ..catalogue.add(_catalogue.first);
      await _pump(
        tester,
        openProject: true,
        withRouter: true,
        overrides: <Override>[
          shippedTemplateLoaderProvider.overrideWith((Ref _) => loader),
        ],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(AppListTile, 'General observation'));
      await tester.pumpAndSettle();

      expect(find.text('UNI-001 · Universal capture and records'), findsOne);
      expect(find.text('Observation / evidence capture'), findsOneWidget);
      expect(
        find.text(Copy.shippedPrivacyTier('internal', 'p0')),
        findsOneWidget,
      );
      expect(find.text(_observation.capture), findsOneWidget);
      expect(find.text(_observation.review), findsOneWidget);
      expect(
        find.text(Copy.requiredColumnGroup('specific_details')),
        findsOneWidget,
      );
      expect(find.text('Observation category'), findsOneWidget);
      expect(
        find.text(Copy.shippedFieldSubtitle('text', Copy.fieldRequired)),
        findsOneWidget,
      );

      await tester.tap(find.byType(AppPrimaryAction));
      await tester.pumpAndSettle();

      expect(loader.copies, hasLength(1));
      expect(loader.copies.single.name, 'General observation');
      expect(loader.copies.single.templateKey, 'uni_general_observation');
    });
  });
}

const ShippedRecordType _observation = ShippedRecordType(
  code: 'OBS',
  title: 'Observation / evidence capture',
  kind: 'observation',
  capture: 'Photos; explicit audio captions; video; optional GPS and time',
  aiAssistance: 'OCR or transcribe visible evidence',
  outputs: 'Observation record; photo sheet',
  review: 'Observed, reported and inferred details must remain distinguishable',
);

const ShippedCatalogueCategory _universal = ShippedCatalogueCategory(
  code: 'UNI',
  title: 'Universal capture and records',
  supergroupCode: '01',
  supergroupTitle: 'Cross-sector foundations',
);

/// Three catalogue rows across two areas, two record types and two tiers.
const List<ShippedTemplateEntry> _catalogue = <ShippedTemplateEntry>[
  ShippedTemplateEntry(
    templateKey: 'uni_general_observation',
    kind: 'observation',
    fieldCount: 67,
    title: 'General observation',
    code: 'UNI-001',
    category: _universal,
    recordType: _observation,
    privacy: 'internal',
    rollout: 'p0',
    fieldKeys: <String>['observation_category', 'observed_details'],
  ),
  ShippedTemplateEntry(
    templateKey: 'uni_voice_field_note',
    kind: 'observation',
    fieldCount: 66,
    title: 'Voice field note',
    code: 'UNI-002',
    category: _universal,
    recordType: _observation,
    privacy: 'internal',
    rollout: 'p0',
    fieldKeys: <String>['spoken_note', 'transcript_language'],
  ),
  ShippedTemplateEntry(
    templateKey: 'fin_invoice_ocr_intake',
    kind: 'transaction',
    fieldCount: 70,
    title: 'Invoice OCR intake',
    code: 'FIN-001',
    category: ShippedCatalogueCategory(
      code: 'FIN',
      title: 'Finance accounting and expenses',
      supergroupCode: '02',
      supergroupTitle: 'Business and governance',
    ),
    recordType: ShippedRecordType(
      code: 'TRANS',
      title: 'Transaction / repeated line items',
      kind: 'transaction',
    ),
    privacy: 'confidential',
    rollout: 'p2',
    fieldKeys: <String>['invoice_number', 'supplier_name'],
  ),
];

/// A surface tall enough that the builder lays out every row.
void _tall(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(393, 4000);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

ShippedTemplateEntry _shipped(String key) {
  return ShippedTemplateEntry.starter(
    TemplateDef(
      id: key,
      templateKey: key,
      name: key,
      version: 1,
      fields: const <FieldDef>[],
      identityFieldKeys: const <String>[],
      rows: const <TemplateRow>[],
      kind: key,
    ),
  );
}

Future<void> _pump(
  WidgetTester tester, {
  List<Override> overrides = const <Override>[],
  bool openProject = false,
  bool withRouter = false,
}) async {
  final FakeProjectRepository projects = FakeProjectRepository();
  addTearDown(projects.dispose);
  if (openProject) {
    switch (await projects.create(aProject())) {
      case FailureResult<Project>(:final Failure failure):
        throw TestFailure(failure.message);
      case Success<Project>():
        break;
    }
  }
  final SettingsStore store = SettingsStore.fake(
    stored: <String, Object?>{
      if (openProject) SettingKeys.openProjectId.name: 'project-1',
    },
  );
  final List<Override> all = <Override>[
    projectRepositoryProvider.overrideWith((Ref _) => projects),
    projectSettingsStoreProvider.overrideWith((Ref _) => store),
    ...overrides,
  ];
  if (withRouter) {
    final GoRouter router = GoRouter(
      initialLocation: AppRoutes.templateLibrary,
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.templates,
          builder: (BuildContext _, GoRouterState _) {
            return const SizedBox.shrink();
          },
          routes: <RouteBase>[
            GoRoute(
              path: 'library',
              builder: (BuildContext _, GoRouterState _) {
                return const ShippedPickerScreen();
              },
            ),
            GoRoute(
              path: ':templateId',
              builder: (BuildContext _, GoRouterState _) {
                return const Text('fields');
              },
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        retry: (int _, Object _) => null,
        overrides: all,
        child: MaterialApp.router(
          theme: buildTheme(brightness: Brightness.light),
          routerConfig: router,
        ),
      ),
    );
    return;
  }
  await tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: all,
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: const ShippedPickerScreen(),
      ),
    ),
  );
}
