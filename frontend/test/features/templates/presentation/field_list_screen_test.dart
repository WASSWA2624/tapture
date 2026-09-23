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
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/settings.dart';
import 'package:tapture/features/templates/presentation/field_list_screen.dart';
import 'package:tapture/features/templates/presentation/template_list_screen.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';
import '../../projects/fakes/fake_project_repository.dart';
import '../fakes/fake_template_repository.dart';

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

  testWidgets('an empty field list renders through AsyncValueView', (
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
      ],
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text(Copy.templatesFieldsEmptyHeadline), findsOneWidget);
    expect(find.text(Copy.templatesFieldsEmptyMessage), findsOneWidget);
    expect(find.text(Copy.templatesAddField), findsNWidgets(2));
    expect(find.byType(AppPrimaryAction), findsOneWidget);

    await tester.tap(find.text(Copy.templatesAddField).first);
    await tester.pumpAndSettle();
    expect(find.text('add'), findsOneWidget);
  });

  testWidgets('a failed load renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      overrides: <Override>[
        templateListProvider.overrideWith(
          (Ref _) => Stream<List<TemplateDef>>.error(
            const StorageFailure(
              message: 'The field list could not be read.',
              recoveryAction: 'Try again.',
            ),
          ),
        ),
      ],
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text('The field list could not be read.'), findsOneWidget);
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

  testWidgets('move down reorders fields and leaves output columns', (
    WidgetTester tester,
  ) async {
    final FakeTemplateRepository templates = FakeTemplateRepository();
    addTearDown(templates.dispose);
    final TemplateDef stored = _ok(
      await templates.save(
        aTemplate(
          fields: const <FieldDef>[
            FieldDef(
              fieldKey: 'serial',
              label: 'Serial',
              type: FieldType.text,
              requiredness: Requiredness.required,
              outputColumn: 'B',
            ),
            FieldDef(
              fieldKey: 'asset_name',
              label: 'Name',
              type: FieldType.text,
              requiredness: Requiredness.optional,
              outputColumn: 'C',
            ),
          ],
        ),
      ),
    );

    await _pump(
      tester,
      templateId: stored.id,
      overrides: <Override>[
        templateRepositoryProvider.overrideWith((Ref _) => templates),
      ],
      openProject: true,
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widgetList<AppListTile>(find.byType(AppListTile))
          .map((AppListTile tile) => tile.title),
      <String>['Serial', 'Name'],
    );
    expect(find.text(Copy.fieldRequired), findsOneWidget);
    expect(find.text(Copy.fieldOptional), findsOneWidget);
    expect(find.textContaining(Copy.fieldTypeLabel('text')), findsNWidgets(2));

    await tester.tap(find.byTooltip(Copy.fieldMoveDown('Serial')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widgetList<AppListTile>(find.byType(AppListTile))
          .map((AppListTile tile) => tile.title),
      <String>['Name', 'Serial'],
    );
    final TemplateDef reordered = _ok(await templates.byId(stored.id))!;
    expect(reordered.fields.map((FieldDef field) => field.fieldKey), <String>[
      'asset_name',
      'serial',
    ]);
    expect(
      reordered.fields.map((FieldDef field) => field.outputColumn),
      <String?>['C', 'B'],
    );
  });
}

Future<void> _pump(
  WidgetTester tester, {
  List<Override> overrides = const <Override>[],
  String templateId = 'template-1',
  bool openProject = false,
}) async {
  final FakeProjectRepository projects = FakeProjectRepository();
  addTearDown(projects.dispose);
  if (openProject) {
    _ok(await projects.create(aProject()));
  }
  final SettingsStore store = SettingsStore.fake(
    stored: <String, Object?>{
      if (openProject) SettingKeys.openProjectId.name: 'project-1',
    },
  );
  final GoRouter router = GoRouter(
    initialLocation: AppRoutes.template(templateId),
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.templates,
        builder: (BuildContext _, GoRouterState _) {
          return const SizedBox.shrink();
        },
        routes: <RouteBase>[
          GoRoute(
            path: ':templateId',
            builder: (BuildContext _, GoRouterState state) {
              return FieldListScreen(
                templateId: state.pathParameters['templateId']!,
              );
            },
            routes: <RouteBase>[
              GoRoute(
                path: 'fields/new',
                builder: (BuildContext _, GoRouterState _) {
                  return const Text('add');
                },
              ),
              GoRoute(
                path: 'fields/:fieldKey',
                builder: (BuildContext _, GoRouterState _) {
                  return const Text('edit');
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        projectRepositoryProvider.overrideWith((Ref _) => projects),
        projectSettingsStoreProvider.overrideWith((Ref _) => store),
        ...overrides,
      ],
      child: MaterialApp.router(
        theme: buildTheme(brightness: Brightness.light),
        routerConfig: router,
      ),
    ),
  );
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
