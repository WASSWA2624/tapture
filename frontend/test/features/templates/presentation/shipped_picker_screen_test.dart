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
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/settings.dart';
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

  testWidgets('lists under area and category headings in catalogue order', (
    WidgetTester tester,
  ) async {
    _tall(tester);
    await _pump(
      tester,
      overrides: <Override>[
        shippedLibraryProvider.overrideWith((Ref _) async => _catalogue),
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
    expect(
      <String>[
        for (final AppListTile tile in tester.widgetList<AppListTile>(
          find.byType(AppListTile),
        ))
          tile.title,
      ],
      <String>['General observation', 'Voice field note', 'Invoice OCR intake'],
    );
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
    final double search = tester.getBottomLeft(find.byType(EditableText)).dy;
    final double firstHeading = tester
        .getTopLeft(find.byType(AppSectionHeader).first)
        .dy;
    expect(firstHeading, greaterThan(search));
  });

  testWidgets('search matches code, record type, category and fields', (
    WidgetTester tester,
  ) async {
    _tall(tester);
    await _pump(
      tester,
      overrides: <Override>[
        shippedLibraryProvider.overrideWith((Ref _) async => _catalogue),
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

    expect(await shownFor('uni-004'), <String>['Voice field note']);
    expect(await shownFor('transaction'), <String>['Invoice OCR intake']);
    expect(await shownFor('finance'), <String>['Invoice OCR intake']);
    expect(await shownFor('transcript language'), <String>['Voice field note']);
    expect(await shownFor('observation foundations'), <String>[
      'General observation',
      'Voice field note',
    ]);
  });

  testWidgets('a search that matches nothing says so under the field', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      overrides: <Override>[
        shippedLibraryProvider.overrideWith((Ref _) async => _catalogue),
      ],
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText), 'audit');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(Copy.shippedLibraryNoMatch('audit')), findsOneWidget);
    expect(find.byType(AppListTile), findsNothing);
    expect(find.byType(Checkbox), findsNothing);
    expect(find.byType(EditableText), findsOneWidget);
    final double search = tester.getBottomLeft(find.byType(EditableText)).dy;
    final double empty = tester.getTopLeft(find.byType(AppEmptyState)).dy;
    expect(empty - search, lessThan(64));
  });

  testWidgets('filters narrow by area, record type and tier', (
    WidgetTester tester,
  ) async {
    _tall(tester);
    await _pump(
      tester,
      overrides: <Override>[
        shippedLibraryProvider.overrideWith((Ref _) async => _catalogue),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('search-filter')));
    await tester.pumpAndSettle();
    for (final String facet in <String>[
      'shipped-area-filter',
      'shipped-record-type-filter',
      'shipped-tier-filter',
    ]) {
      expect(find.byKey(ValueKey<String>(facet)), findsOneWidget);
    }
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
    expect(
      find.widgetWithText(AppListTile, 'Invoice OCR intake'),
      findsNothing,
    );

    filter
      ..clear()
      ..setAreas(<String>{'02'});
    await tester.pumpAndSettle();
    expect(find.byType(AppListTile), findsOneWidget);
    expect(
      find.widgetWithText(AppListTile, 'Invoice OCR intake'),
      findsOneWidget,
    );

    filter
      ..clear()
      ..setTiers(<String>{'p0'});
    await tester.pumpAndSettle();
    expect(find.byType(AppListTile), findsNWidgets(2));
  });

  testWidgets('preview shows what the template is and adds it by title', (
    WidgetTester tester,
  ) async {
    _tall(tester);
    final FakeShippedTemplateLoader loader = FakeShippedTemplateLoader()
      ..catalogue.add(_catalogue.first)
      ..rows.add(_observationTemplate);
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
    expect(find.text('Observation subject'), findsOneWidget);
    expect(find.text('Observation category'), findsOneWidget);
    expect(
      find.text(Copy.shippedFieldSubtitle('text', Copy.fieldRequired)),
      findsOneWidget,
    );
    expect(find.text(Copy.templatesAddToProject), findsOneWidget);

    await tester.tap(find.byType(AppPrimaryAction));
    await tester.pumpAndSettle();

    expect(loader.copies, hasLength(1));
    expect(loader.copies.single.name, 'General observation');
    expect(loader.copies.single.templateKey, 'uni_general_observation');
    expect(loader.copies.single.projectId, 'project-1');
    expect(loader.copies.single.version, 1);
    expect(find.text('fields'), findsOneWidget);
  });

  testWidgets('selected templates save onto the project', (
    WidgetTester tester,
  ) async {
    _tall(tester);
    final FakeShippedTemplateLoader loader = FakeShippedTemplateLoader()
      ..catalogue.addAll(_catalogue)
      ..rows.addAll(<TemplateDef>[
        for (final ShippedTemplateEntry entry in _catalogue)
          TemplateDef(
            id: '',
            templateKey: entry.templateKey,
            name: 'templates.${entry.templateKey}.name',
            version: 1,
            fields: const <FieldDef>[],
            identityFieldKeys: const <String>[],
            rows: const <TemplateRow>[],
            kind: entry.kind,
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
    await tester.pumpAndSettle();

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
    await tester.longPress(find.byType(AppListTile).at(2));
    await tester.pump();
    await tester.tap(find.text(Copy.save));
    await tester.pumpAndSettle();

    expect(<String>[
      for (final TemplateDef row in loader.copies) row.name,
    ], unorderedEquals(<String>['General observation', 'Invoice OCR intake']));
    expect(
      loader.copies.every((TemplateDef row) => row.projectId == 'project-1'),
      isTrue,
    );
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

/// Three templates across two areas, two record types and two tiers.
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
    code: 'UNI-004',
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

/// The resolved General observation, trimmed to one pack and one own field.
const TemplateDef _observationTemplate = TemplateDef(
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
);

/// A surface tall enough that the builder lays out every row.
void _tall(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(393, 4000);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
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
