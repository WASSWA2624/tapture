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
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/templates/domain/template_def.dart';
import 'package:tapture/features/templates/presentation/template_list_screen.dart';

import '../../../support/factories.dart';

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
    expect(find.text(Copy.templatesEmptyMessage), findsOneWidget);
    expect(find.text(Copy.templatesPickLibrary), findsOneWidget);
    expect(find.byType(AppPrimaryAction), findsOneWidget);

    await tester.tap(find.text(Copy.templatesPickLibrary));
    await tester.pumpAndSettle();
    expect(find.text('library'), findsOneWidget);
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
    expect(find.text(Copy.templatesDelete), findsNothing);
  });
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
