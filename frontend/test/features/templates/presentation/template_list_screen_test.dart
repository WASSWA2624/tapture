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
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/projects/domain/project_repository.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/settings.dart';
import 'package:tapture/features/templates/domain/template_def.dart';
import 'package:tapture/features/templates/presentation/template_list_filter.dart';
import 'package:tapture/features/templates/presentation/template_list_screen.dart';

import '../../../support/factories.dart';
import '../../projects/fakes/fake_project_repository.dart';

void main() {
  testWidgets('loading renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    final StreamController<List<TemplateDef>> pending =
        StreamController<List<TemplateDef>>();
    addTearDown(pending.close);
    await _pump(
      tester,
      overrides: <Override>[
        templateListProvider.overrideWith((Ref _) => pending.stream),
      ],
    );
    await tester.pump();

    expect(find.byType(AppSkeleton), findsOneWidget);
  });

  testWidgets('an empty list renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      overrides: <Override>[
        templateListProvider.overrideWith(
          (Ref _) => Stream<List<TemplateDef>>.value(const <TemplateDef>[]),
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text(Copy.templatesEmptyHeadline), findsOneWidget);
    expect(find.text(Copy.templatesAddEmptyMessage), findsOneWidget);
    expect(find.text(Copy.templatesPickLibrary), findsNothing);
    expect(find.byType(AppPrimaryAction), findsOneWidget);
    expect(find.text(Copy.templatesAddChoices), findsOneWidget);
    expect(find.text(Copy.templatesAddMore), findsNothing);

    await tester.tap(find.text(Copy.templatesAddChoices));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.templatesUseExisting));
    await tester.pumpAndSettle();
    expect(find.text('library'), findsOneWidget);
  });

  for (final ({String name, Size size, double scale}) layout
      in <({String name, Size size, double scale})>[
        (name: 'portrait', size: const Size(393, 886), scale: 1),
        (name: '200 percent text', size: const Size(393, 886), scale: 2),
        (name: 'landscape', size: const Size(886, 393), scale: 1),
      ]) {
    testWidgets('with a template, the footer stacks two full-width actions '
        'in ${layout.name}', (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = layout.size;
      tester.platformDispatcher.textScaleFactorTestValue = layout.scale;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      await _pump(
        tester,
        overrides: <Override>[
          templateListProvider.overrideWith(
            (Ref _) => Stream<List<TemplateDef>>.value(<TemplateDef>[
              aTemplate(name: 'Assets'),
            ]),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(Copy.templatesAddMore), findsOneWidget);
      expect(find.text(Copy.templatesAddChoices), findsNothing);
      final Rect add = tester.getRect(
        find.descendant(
          of: find.widgetWithText(AppButton, Copy.templatesAddMore),
          matching: find.byType(OutlinedButton),
        ),
      );
      final Rect create = tester.getRect(find.byType(AppPrimaryAction));
      expect(add.width, closeTo(create.width, 1));
      expect(add.left, closeTo(create.left, 1));
      expect(add.bottom, lessThanOrEqualTo(create.top));
    });
  }

  testWidgets('a failed load renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      overrides: <Override>[
        templateListProvider.overrideWith(
          (Ref _) => Stream<List<TemplateDef>>.error(
            const StorageFailure(
              message: 'The template list could not be read.',
              recoveryAction: 'Try again.',
            ),
          ),
        ),
      ],
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text('The template list could not be read.'), findsOneWidget);
  });

  testWidgets('offline renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      overrides: <Override>[
        templateListProvider.overrideWith(
          (Ref _) => Stream<List<TemplateDef>>.error(const NetworkFailure()),
        ),
      ],
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text(const NetworkFailure().message), findsOneWidget);
  });

  testWidgets('a populated list shows counts and hides delete when used', (
    WidgetTester tester,
  ) async {
    final TemplateDef unused = aTemplate(id: 'template-1', name: 'Blank');
    final TemplateDef used = aTemplate(id: 'template-2', name: 'Assets');
    await _pump(
      tester,
      overrides: <Override>[
        templateListProvider.overrideWith(
          (Ref _) =>
              Stream<List<TemplateDef>>.value(<TemplateDef>[unused, used]),
        ),
        templateRecordCountsProvider.overrideWith(
          (Ref _) => const <String, int>{'template-2': 3},
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppListTile), findsNWidgets(2));
    expect(find.text('Blank'), findsOneWidget);
    expect(find.text('Assets'), findsOneWidget);
    expect(
      find.text(Copy.templateListSubtitle(fields: 0, records: 0)),
      findsOneWidget,
    );
    expect(
      find.text(Copy.templateListSubtitle(fields: 0, records: 3)),
      findsOneWidget,
    );

    await tester.tap(find.byType(AppOverflowMenu).first);
    await tester.pumpAndSettle();
    expect(find.text(Copy.templatesDelete), findsOneWidget);
    await tester.tap(find.text(Copy.templatesOpen));
    await tester.pumpAndSettle();
    expect(find.text('fields'), findsOneWidget);
  });

  testWidgets('each row counts the live records the project holds for it', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    await repo.create(aProject());
    repo.seedRecords('project-1', <ProjectRecordRow>[
      _record('r1', 'template-2', 'captured'),
      _record('r2', 'template-2', 'approved'),
      _record('r3', 'template-1', 'archived'),
    ]);
    await _pump(
      tester,
      overrides: <Override>[
        projectRepositoryProvider.overrideWith((Ref _) => repo),
        projectSettingsStoreProvider.overrideWith(
          (Ref _) => SettingsStore.fake(
            stored: <String, Object?>{
              SettingKeys.openProjectId.name: 'project-1',
            },
          ),
        ),
        templateListProvider.overrideWith(
          (Ref _) => Stream<List<TemplateDef>>.value(<TemplateDef>[
            aTemplate(id: 'template-1', name: 'Blank'),
            aTemplate(id: 'template-2', name: 'Assets'),
          ]),
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(
      find.text(Copy.templateListSubtitle(fields: 0, records: 2)),
      findsOneWidget,
    );
    expect(
      find.text(Copy.templateListSubtitle(fields: 0, records: 0)),
      findsOneWidget,
    );

    await tester.tap(find.byType(AppOverflowMenu).last);
    await tester.pumpAndSettle();
    expect(find.text(Copy.templatesDelete), findsNothing);
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AppOverflowMenu).first);
    await tester.pumpAndSettle();
    expect(find.text(Copy.templatesDelete), findsOneWidget);
  });

  testWidgets('delete is omitted when a record uses the template', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      overrides: <Override>[
        templateListProvider.overrideWith(
          (Ref _) => Stream<List<TemplateDef>>.value(<TemplateDef>[
            aTemplate(name: 'Assets'),
          ]),
        ),
        templateRecordCountsProvider.overrideWith(
          (Ref _) => const <String, int>{'template-1': 2},
        ),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AppOverflowMenu));
    await tester.pumpAndSettle();
    expect(find.text(Copy.templatesOpen), findsOneWidget);
    expect(find.text(Copy.projectsDuplicate), findsOneWidget);
    expect(find.text(Copy.templatesExport), findsOneWidget);
    expect(find.text(Copy.templatesImport), findsOneWidget);
    expect(find.text(Copy.templatesDelete), findsNothing);
  });

  group('kind filter', () {
    final List<TemplateDef> templates = <TemplateDef>[
      aTemplate(id: 't-1', name: 'Water meter').copyWith(kind: 'meter'),
      aTemplate(id: 't-2', name: 'Gas meter').copyWith(kind: 'meter'),
      aTemplate(id: 't-3', name: 'Water pump').copyWith(kind: 'equipment'),
      aTemplate(id: 't-4', name: 'Blank').copyWith(kind: ''),
    ];
    List<Override> listed() => <Override>[
      templateListProvider.overrideWith(
        (Ref _) => Stream<List<TemplateDef>>.value(templates),
      ),
    ];
    Finder filterButton() =>
        find.byKey(const ValueKey<String>('search-filter'));

    testWidgets('choosing a kind in the sheet lists only that kind', (
      WidgetTester tester,
    ) async {
      await _pump(tester, overrides: listed());
      await tester.pumpAndSettle();
      expect(find.byType(AppListTile), findsNWidgets(4));
      expect(find.byTooltip(Copy.searchFilters(0)), findsOneWidget);

      await tester.tap(filterButton());
      await tester.pumpAndSettle();
      expect(find.text(Copy.templateFiltersTitle), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey<String>('template-kind-filter')),
      );
      await tester.pumpAndSettle();
      // The kinds present, sorted, with a name for the template without one.
      expect(find.text('equipment'), findsOneWidget);
      expect(find.text(Copy.templateKindNone), findsOneWidget);
      await tester.tap(find.text('meter'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byType(AppListTile), findsNWidgets(2));
      expect(find.text('Water meter'), findsOneWidget);
      expect(find.text('Gas meter'), findsOneWidget);
      expect(find.text('Water pump'), findsNothing);
      expect(find.byTooltip(Copy.searchFilters(1)), findsOneWidget);
    });

    testWidgets('search and the kind filter combine', (
      WidgetTester tester,
    ) async {
      await _pump(tester, overrides: listed());
      await tester.pumpAndSettle();
      _container(tester).read(templateListFilterProvider.notifier).set(<String>{
        'meter',
        'equipment',
      });
      _container(tester).read(templateListQueryProvider.notifier).set('water');
      await tester.pumpAndSettle();

      expect(find.byType(AppListTile), findsNWidgets(2));
      expect(find.text('Water meter'), findsOneWidget);
      expect(find.text('Water pump'), findsOneWidget);
      expect(find.byTooltip(Copy.searchFilters(2)), findsOneWidget);

      _container(
        tester,
      ).read(templateListFilterProvider.notifier).set(<String>{''});
      await tester.pumpAndSettle();
      expect(find.byType(AppListTile), findsNothing);
      expect(find.text(Copy.templatesNoMatch), findsOneWidget);
      expect(find.text(Copy.searchFilterNoMatchMessage), findsOneWidget);
    });

    testWidgets('clear filters lists every template again', (
      WidgetTester tester,
    ) async {
      await _pump(tester, overrides: listed());
      await tester.pumpAndSettle();
      _container(
        tester,
      ).read(templateListFilterProvider.notifier).set(<String>{'equipment'});
      await tester.pumpAndSettle();
      expect(find.byType(AppListTile), findsOneWidget);

      await tester.tap(filterButton());
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('filter-sheet-clear')),
      );
      await tester.pumpAndSettle();

      expect(find.text(Copy.templateFiltersTitle), findsNothing);
      expect(find.byType(AppListTile), findsNWidgets(4));
      expect(find.byTooltip(Copy.searchFilters(0)), findsOneWidget);
    });
  });
}

ProjectRecordRow _record(String id, String templateId, String status) {
  return (
    id: id,
    templateId: templateId,
    status: status,
    photoCount: 0,
    thumb: null,
    fields: const <ProjectRecordFieldValue>[],
  );
}

Future<void> _pump(
  WidgetTester tester, {
  List<Override> overrides = const <Override>[],
}) async {
  final GoRouter router = GoRouter(
    initialLocation: AppRoutes.templates,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.templates,
        builder: (BuildContext _, GoRouterState _) {
          return const TemplateListScreen();
        },
        routes: <RouteBase>[
          GoRoute(
            path: 'new',
            builder: (BuildContext _, GoRouterState _) {
              return const Text('create');
            },
          ),
          GoRoute(
            path: 'library',
            builder: (BuildContext _, GoRouterState _) {
              return const Text('library');
            },
          ),
          GoRoute(
            path: 'import',
            builder: (BuildContext _, GoRouterState _) {
              return const Text('import');
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
      overrides: overrides,
      child: MaterialApp.router(
        theme: buildTheme(brightness: Brightness.light),
        routerConfig: router,
      ),
    ),
  );
}

ProviderContainer _container(WidgetTester tester) {
  return ProviderScope.containerOf(
    tester.element(find.byType(TemplateListScreen)),
  );
}
