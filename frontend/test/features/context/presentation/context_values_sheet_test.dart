import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/copy/l10n/app_localizations.g.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/context/context.dart';
import 'package:tapture/features/context/presentation/context_picker_sheet.dart';
import 'package:tapture/features/context/presentation/context_providers.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/settings.dart' show SettingsStore;
import 'package:tapture/features/templates/templates.dart';

import '../../../support/a11y_matchers.dart';
import '../../../support/empty_state_matchers.dart';
import '../../../support/factories.dart';
import '../../../support/fakes/fake_context_repository.dart';
import '../../../support/fakes/fake_template_repository.dart';
import '../../../support/pump_app.dart';
import '../../../support/screen_fonts.dart';
import '../../../support/screen_matrix.dart';
import '../../../support/screen_probe.dart';

const ScreenMatrix _phone = ScreenMatrix(
  Size(393, 886),
  1,
  Brightness.light,
  false,
);

void main() {
  setUpAll(ScreenFonts.loadForApp);

  testWidgets(
    'a stale overview selection opens no editor and changes no project',
    (tester) async {
      final _Overview fixture = await _pump(tester);
      fixture.container.read(currentProjectProvider.notifier).open('p2');
      await tester.tap(
        find.byKey(const ValueKey<String>('context-values-level-region')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ContextPickerSheet), findsNothing);
      expect(find.byType(AppBottomSheet), findsNothing);
      expect(_ok(await fixture.repo.load('p1')).values['region'], 'North');
      expect(_ok(await fixture.repo.load('p2')).isEmpty, isTrue);
    },
  );

  testWidgets(
    'cascade decline keeps values and acceptance uses the existing writer',
    (tester) async {
      final _Overview fixture = await _pump(tester);
      await _edit(tester, 'level-region');
      expect(
        tester
            .widget<ContextPickerSheet>(find.byType(ContextPickerSheet))
            .currentValue,
        'North',
      );
      await tester.enterText(find.byType(TextField), 'South');
      await tester.tap(
        find.widgetWithText(AppPrimaryAction, Copy.contextUseValue),
      );
      await pumpUntil(
        tester,
        () => find
            .text(Copy.contextCascadeTitle)
            .hitTestable()
            .evaluate()
            .isNotEmpty,
      );
      expect(find.text(Copy.contextCascadeTitle), findsOneWidget);
      expect(find.textContaining('Facility'), findsWidgets);
      await tester.tap(find.text(Copy.cancel));
      await tester.pumpAndSettle();
      expect(_ok(await fixture.repo.load('p1')).values, <String, String>{
        'region': 'North',
        'facility': 'Clinic',
      });
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'South',
      );
      await tester.tap(
        find.widgetWithText(AppPrimaryAction, Copy.contextUseValue),
      );
      await pumpUntil(
        tester,
        () => find
            .text(Copy.contextCascadeConfirm)
            .hitTestable()
            .evaluate()
            .isNotEmpty,
      );
      await tester.tap(find.text(Copy.contextCascadeConfirm));
      await tester.pumpAndSettle();
      expect(find.byType(ContextPickerSheet), findsNothing);
      expect(_ok(await fixture.repo.load('p1')).values, <String, String>{
        'region': 'South',
      });
      expect(
        _ok(await fixture.repo.load('p1')).pinned['operator'],
        'Field team',
      );
    },
  );

  testWidgets('overview pins retain clear and failed-write recovery', (
    tester,
  ) async {
    final _Overview fixture = await _pump(tester);
    await _edit(tester, 'pin-operator');
    expect(find.byType(AppBottomSheet), findsOneWidget);
    fixture.repo.pinnedFailure = const StorageFailure(
      message: 'Pin write refused',
      recoveryAction: 'retry',
    );
    await tester.tap(find.text(Copy.contextClearPin));
    await tester.pumpAndSettle();
    expect(find.textContaining('Pin write refused'), findsWidgets);
    expect(_ok(await fixture.repo.load('p1')).pinned['operator'], 'Field team');
    fixture.repo.pinnedFailure = null;
    await tester.tap(find.text(Copy.contextClearPin));
    await tester.pumpAndSettle();
    expect(_ok(await fixture.repo.load('p1')).pinned, isEmpty);
    expect(find.byType(ContextPickerSheet), findsNothing);
  });

  testWidgets(
    'context loading and failure recover without losing setup access',
    (tester) async {
      final StreamController<ContextState> states =
          StreamController<ContextState>();
      addTearDown(states.close);
      await _pump(
        tester,
        extra: <Override>[
          projectContextProvider.overrideWith(
            (Ref _, String _) => states.stream,
          ),
          contextTemplatesProvider.overrideWith(
            (Ref _, String _) =>
                Stream<List<TemplateDef>>.value(const <TemplateDef>[]),
          ),
        ],
      );
      expect(find.byType(AppSkeleton), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('context-values-manage')),
        findsOneWidget,
      );
      states.addError(
        const StorageFailure(
          message: 'Context unavailable',
          recoveryAction: 'retry',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppErrorState), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('context-values-presets')),
        findsOneWidget,
      );
      states.add(const ContextState());
      await tester.pumpAndSettle();
      expect(find.text(Copy.contextHierarchyEmptyHeadline), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('context-values-pins')),
        findsOneWidget,
      );
    },
  );

  for (final String command in <String>['manage', 'presets']) {
    testWidgets('overview $command navigates with the explicit project', (
      tester,
    ) async {
      final _Overview fixture = await _pump(tester);
      final Finder action = find.byKey(
        ValueKey<String>('context-values-$command'),
      );
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
      final Finder destination = find.text(
        command == 'manage' ? 'Manage' : 'Presets',
      );
      expect(destination, findsOneWidget);
      expect(
        GoRouterState.of(tester.element(destination)).pathParameters['id'],
        'p1',
      );
      expect(fixture.router.canPop(), isTrue);
      expect(find.byType(AppBottomSheet), findsNothing);
    });
  }

  for (final ({String name, ScreenMatrix cell}) corner
      in ScreenMatrix.corners) {
    for (final Locale locale in const <Locale>[
      Locale('en'),
      Locale('en', 'XA'),
    ]) {
      testWidgets('context overview ${corner.name} $locale', (tester) async {
        await _pump(tester, cell: corner.cell, locale: locale);
        final SemanticsHandle semantics = tester.ensureSemantics();
        try {
          await tester.pump();
          for (final String key in <String>[
            'level-region',
            'level-facility',
            'pin-operator',
            'manage',
            'presets',
            'pins',
          ]) {
            final Finder row = find.byKey(
              ValueKey<String>('context-values-$key'),
            );
            await tester.ensureVisible(row);
            await tester.pumpAndSettle();
            expect(row, meetsTapTarget());
            expect(ScreenProbe.layoutIssues(tester), isEmpty);
            expect(
              await ScreenProbe.accessibilityIssues(
                tester,
                targets: <Finder>[row],
                within: find.byType(AppBottomSheet),
              ),
              isEmpty,
            );
          }
          final Finder facility = find.byKey(
            const ValueKey<String>('context-values-level-facility'),
          );
          await tester.scrollUntilVisible(
            facility,
            -100,
            scrollable: find.descendant(
              of: find.byKey(const ValueKey<String>('context-values-overview')),
              matching: find.byType(Scrollable),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tapAt(
            ScreenProbe.targetViewport(
              tester,
              facility,
            ).intersect(tester.getRect(facility)).center,
          );
          await tester.pumpAndSettle();
          expect(find.byType(AppBottomSheet), findsOneWidget);
          expect(find.byType(ContextPickerSheet), findsOneWidget);
          await revealScrollableBody(tester, find.byType(AppTextField));
          expect(find.byType(AppTextField), findsOneWidget);
          expect(
            Directionality.of(tester.element(find.byType(ContextPickerSheet))),
            locale.countryCode == 'XA' ? TextDirection.rtl : TextDirection.ltr,
          );
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      });
    }
  }

  for (final (String, Brightness, bool) theme in <(String, Brightness, bool)>[
    ('light', Brightness.light, false),
    ('dark', Brightness.dark, false),
    ('outdoor', Brightness.light, true),
  ]) {
    testWidgets('context overview visual ${theme.$1}', (tester) async {
      await _pump(
        tester,
        cell: ScreenMatrix(const Size(393, 886), 1, theme.$2, theme.$3),
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/task158_context_overview_${theme.$1}.png'),
      );
    });
  }
}

Future<void> _edit(WidgetTester tester, String field) async {
  final Finder row = find.byKey(ValueKey<String>('context-values-$field'));
  await tester.ensureVisible(row);
  await tester.tap(row);
  await tester.pumpAndSettle();
  expect(find.byType(AppBottomSheet), findsOneWidget);
  expect(
    find.byKey(const ValueKey<String>('context-values-overview')),
    findsNothing,
  );
}

final class _Overview {
  const _Overview(this.container, this.repo, this.router);
  final ProviderContainer container;
  final FakeContextRepository repo;
  final GoRouter router;
}

Future<_Overview> _pump(
  WidgetTester tester, {
  ScreenMatrix cell = _phone,
  Locale locale = const Locale('en'),
  List<Override> extra = const <Override>[],
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = cell.size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  final FakeContextRepository repo = FakeContextRepository();
  final FakeTemplateRepository templates = FakeTemplateRepository();
  addTearDown(repo.dispose);
  addTearDown(templates.dispose);
  _ok(
    await repo.saveHierarchy('p1', const <ContextLevel>[
      ContextLevel(fieldKey: 'region', order: 0, label: 'Region'),
      ContextLevel(fieldKey: 'facility', order: 1, label: 'Facility'),
    ]),
  );
  _ok(
    await repo.setLevelValue(
      projectId: 'p1',
      fieldKey: 'region',
      value: 'North',
    ),
  );
  _ok(
    await repo.setLevelValue(
      projectId: 'p1',
      fieldKey: 'facility',
      value: 'Clinic',
    ),
  );
  _ok(
    await repo.savePinned('p1', const <String, String>{
      'operator': 'Field team',
    }),
  );
  await templates.save(
    aTemplate(
      id: 't1',
      projectId: 'p1',
      fields: const <FieldDef>[
        FieldDef(
          fieldKey: 'operator',
          label: 'Operator',
          type: FieldType.text,
          stickable: true,
        ),
      ],
    ),
  );
  late BuildContext caller;
  final GoRouter router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          body: Builder(
            builder: (context) {
              caller = context;
              return FilledButton(
                onPressed: () => unawaited(
                  showContextValuesSheet(context: context, projectId: 'p1'),
                ),
                child: const Text('Open values'),
              );
            },
          ),
        ),
      ),
      GoRoute(
        path: '/projects/:id/context',
        builder: (_, _) => const Scaffold(body: Text('Manage')),
        routes: <RouteBase>[
          GoRoute(
            path: 'presets',
            builder: (_, _) => const Scaffold(body: Text('Presets')),
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
        contextRepositoryProvider.overrideWithValue(repo),
        templateRepositoryProvider.overrideWithValue(templates),
        projectSettingsStoreProvider.overrideWithValue(SettingsStore.fake()),
        ...extra,
      ],
      child: MaterialApp.router(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: ScreenFonts.theme(
          buildTheme(brightness: cell.brightness, outdoor: cell.outdoor),
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(cell.textScale)),
          child: Directionality(
            textDirection: locale.countryCode == 'XA'
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: child!,
          ),
        ),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  final ProviderContainer container = ProviderScope.containerOf(caller);
  await tester.tap(find.text('Open values'));
  await tester.pumpAndSettle();
  return _Overview(container, repo, router);
}

T _ok<T>(Result<T> result) => switch (result) {
  Success<T>(:final T value) => value,
  FailureResult<T>(:final Failure failure) => throw TestFailure(
    failure.message,
  ),
};
