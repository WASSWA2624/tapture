import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/copy/l10n/app_localizations.g.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_chip.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/features/context/context.dart';
import 'package:tapture/features/context/presentation/context_bar.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/domain/setting_keys.dart';
import 'package:tapture/features/settings/settings.dart' show SettingsStore;
import 'package:tapture/features/templates/templates.dart';

import '../../../support/a11y_matchers.dart';
import '../../../support/factories.dart';
import '../../../support/fakes/fake_context_repository.dart';
import '../../../support/fakes/fake_template_repository.dart';
import '../../../support/screen_fonts.dart';
import '../../../support/screen_matrix.dart';
import '../../../support/screen_probe.dart';
import '../../projects/fakes/fake_project_repository.dart';

void main() {
  setUpAll(ScreenFonts.load);
  testWidgets('on Capture every level shows, set or not, with Manage', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _pump(tester, showsEmptyLevels: true);

    expect(
      find.text(Copy.contextLevelValue('District', 'Kampala')),
      findsOneWidget,
    );
    expect(find.text(Copy.contextSetLevel('Sub-county')), findsOneWidget);
    expect(find.text(Copy.contextManage), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('context-bar-level-subcounty')),
      meetsTapTarget(),
    );
    expect(harness.router, isNotNull);
  });

  testWidgets('a Set chip opens the picker for its level', (
    WidgetTester tester,
  ) async {
    await _pump(tester, showsEmptyLevels: true);

    final Finder subcounty = find.byKey(
      const ValueKey<String>('context-bar-level-subcounty'),
    );
    await tester.ensureVisible(subcounty);
    await tester.tap(subcounty);
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('Manage opens the project context levels', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _pump(
      tester,
      showsEmptyLevels: true,
      width: 1200,
    );

    await tester.tap(find.byKey(const ValueKey<String>('context-bar-manage')));
    await tester.pumpAndSettle();

    expect(harness.router.state.uri.path, RoutePaths.projectContext('p1'));
  });

  testWidgets('with no levels Capture offers Set up context', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _pump(
      tester,
      showsEmptyLevels: true,
      levels: const <ContextLevel>[],
      width: 1200,
    );

    expect(find.text(Copy.contextSetUp), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('context-bar-set-up')));
    await tester.pumpAndSettle();
    expect(harness.router.state.uri.path, RoutePaths.projectContext('p1'));
  });

  testWidgets('elsewhere an empty level stays hidden, as before', (
    WidgetTester tester,
  ) async {
    await _pump(tester, showsEmptyLevels: false);

    expect(find.text(Copy.contextSetLevel('Sub-county')), findsNothing);
    expect(find.text(Copy.contextManage), findsNothing);
    expect(find.textContaining('Kampala'), findsOneWidget);
  });

  testWidgets('at 200 percent text on a phone the chips scroll, not clip', (
    WidgetTester tester,
  ) async {
    await _pump(tester, showsEmptyLevels: true, width: 320, scale: 2);

    expect(tester.takeException(), isNull);
    final Finder manage = find.byKey(
      const ValueKey<String>('context-bar-manage'),
    );
    await tester.dragUntilVisible(
      manage,
      _hierarchyScroll(),
      const Offset(-120, 0),
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(manage).right, lessThanOrEqualTo(320));
  });

  testWidgets('a project with no hierarchy shows no bar away from Capture', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      showsEmptyLevels: false,
      levels: const <ContextLevel>[],
    );

    expect(find.byType(AppChip), findsNothing);
    expect(tester.getSize(find.byType(ContextBar)).height, 0);
  });

  testWidgets('moving between two room presets costs one tap each way', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _pump(
      tester,
      showsEmptyLevels: false,
      width: 1200,
    );
    _ok(
      await harness.repo.savePreset(
        projectId: 'p1',
        name: 'Ward A',
        values: const <String, String>{'district': 'Kampala', 'subcounty': 'A'},
        pinned: const <String, String>{},
      ),
    );
    final ContextPreset wardB = _ok(
      await harness.repo.savePreset(
        projectId: 'p1',
        name: 'Ward B',
        values: const <String, String>{'district': 'Kampala', 'subcounty': 'B'},
        pinned: const <String, String>{},
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(AppChip, 'Ward B'));
    await tester.pumpAndSettle();
    expect(_ok(await harness.repo.load('p1')).values, <String, String>{
      'district': 'Kampala',
      'subcounty': 'B',
    });
    expect(find.text(Copy.contextPresetApplied('Ward B')), findsOneWidget);
    expect(
      tester
          .widget<AppChip>(
            find.byKey(ValueKey<String>('context-bar-preset-${wardB.id}')),
          )
          .selected,
      isTrue,
    );

    await tester.tap(find.widgetWithText(AppChip, 'Ward A'));
    await tester.pumpAndSettle();
    expect(_ok(await harness.repo.load('p1')).values, <String, String>{
      'district': 'Kampala',
      'subcounty': 'A',
    });
  });

  testWidgets('the Presets chip opens the preset list', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _pump(tester, showsEmptyLevels: true);

    await tester.dragUntilVisible(
      find.byKey(const ValueKey<String>('context-bar-presets')),
      _hierarchyScroll(),
      const Offset(-120, 0),
    );
    await tester.tap(find.byKey(const ValueKey<String>('context-bar-presets')));
    await tester.pumpAndSettle();

    expect(
      harness.router.state.uri.path,
      RoutePaths.projectContextPresets('p1'),
    );
  });

  testWidgets('a pin chip names its field and opens its own picker', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _pump(
      tester,
      showsEmptyLevels: true,
      width: 1200,
    );
    _ok(
      await harness.repo.savePinned('p1', const <String, String>{
        'surveyor': 'Sam',
      }),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(Copy.contextPinnedValue('Surveyor', 'Sam')),
      findsOneWidget,
    );
    expect(find.text(Copy.contextSetLevel('Survey date')), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('context-bar-pin-surveyor')),
    );
    await tester.pumpAndSettle();
    expect(find.text(Copy.contextPickerTitle('Surveyor')), findsOneWidget);
  });

  testWidgets('under right-to-left the first level starts on the right', (
    WidgetTester tester,
  ) async {
    await _pump(tester, showsEmptyLevels: true, rtl: true);

    final Rect first = tester.getRect(
      find.byKey(const ValueKey<String>('context-bar-level-district')),
    );
    final Rect second = tester.getRect(
      find.byKey(const ValueKey<String>('context-bar-level-subcounty')),
    );
    expect(first.left, greaterThan(second.left));
  });

  testWidgets('a wide window shows levels as a path and fills a set value', (
    WidgetTester tester,
  ) async {
    await _pump(tester, showsEmptyLevels: true, width: 1200);

    expect(find.byIcon(AppIcons.open), findsOneWidget);
    expect(
      tester
          .widget<AppChip>(
            find.byKey(const ValueKey<String>('context-bar-level-district')),
          )
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<AppChip>(
            find.byKey(const ValueKey<String>('context-bar-level-subcounty')),
          )
          .selected,
      isFalse,
    );
  });

  for (final ScreenMatrix cell in ScreenMatrix.cells) {
    for (final Locale locale in <Locale>[
      const Locale('en'),
      const Locale('en', 'XA'),
    ]) {
      testWidgets(
        'readable hierarchy and separate pins at ${cell.description} $locale',
        (WidgetTester tester) async {
          final _Harness harness = await _pump(
            tester,
            showsEmptyLevels: true,
            levels: const <ContextLevel>[
              ContextLevel(fieldKey: 'district', order: 0, label: 'District'),
              ContextLevel(fieldKey: 'facility', order: 1, label: 'Facility'),
              ContextLevel(fieldKey: 'room', order: 2, label: 'Room'),
            ],
            width: cell.size.width,
            height: cell.size.height,
            scale: cell.textScale,
            brightness: cell.brightness,
            outdoor: cell.outdoor,
            locale: locale,
          );
          await harness.repo.setLevelValue(
            projectId: 'p1',
            fieldKey: 'facility',
            value: 'Complete facility name and outpatient wing',
          );
          await harness.repo.setLevelValue(
            projectId: 'p1',
            fieldKey: 'room',
            value: 'Room with a complete readable name',
          );
          await harness.repo.savePinned('p1', const <String, String>{
            'surveyor': 'Complete surveyor value',
          });
          await tester.pumpAndSettle();
          expect(find.byIcon(AppIcons.open), findsNWidgets(2));
          final Finder hierarchy = find.byKey(
            const ValueKey<String>('context-bar-hierarchy'),
          );
          final Finder pins = find.byKey(
            const ValueKey<String>('context-bar-pins'),
          );
          expect(
            tester.getTopLeft(pins).dy,
            greaterThan(tester.getTopLeft(hierarchy).dy),
          );
          for (final String key in <String>[
            'context-bar-level-district',
            'context-bar-level-facility',
            'context-bar-level-room',
            'context-bar-manage',
            'context-bar-presets',
            'context-bar-pin-surveyor',
            'context-bar-pin-survey_date',
          ]) {
            final Finder chip = find.byKey(ValueKey<String>(key));
            await tester.ensureVisible(chip);
            await tester.pumpAndSettle();
            final List<String> issues = await ScreenProbe.accessibilityIssues(
              tester,
              targets: <Finder>[chip],
            );
            expect(
              issues,
              isEmpty,
              reason: '$key at ${cell.description} $locale',
            );
            expect(
              tester.widget<AppChip>(chip).maxLabelWidth,
              lessThanOrEqualTo(cell.size.width),
            );
          }
          final AppChip facility = tester.widget<AppChip>(
            find.byKey(const ValueKey<String>('context-bar-level-facility')),
          );
          expect(
            facility.semanticLabel,
            contains('Complete facility name and outpatient wing'),
          );
        },
        variant: const TargetPlatformVariant(
          kIsWeb
              ? <TargetPlatform>{TargetPlatform.android}
              : <TargetPlatform>{
                  TargetPlatform.android,
                  TargetPlatform.iOS,
                  TargetPlatform.windows,
                  TargetPlatform.macOS,
                  TargetPlatform.linux,
                },
        ),
      );
    }
  }
}

Finder _hierarchyScroll() => find.descendant(
  of: find.byKey(const ValueKey<String>('context-bar-hierarchy')),
  matching: find.byType(SingleChildScrollView),
);

typedef _Harness = ({GoRouter router, FakeContextRepository repo});

Future<_Harness> _pump(
  WidgetTester tester, {
  required bool showsEmptyLevels,
  List<ContextLevel> levels = const <ContextLevel>[
    ContextLevel(fieldKey: 'district', order: 0, label: 'District'),
    ContextLevel(fieldKey: 'subcounty', order: 1, label: 'Sub-county'),
  ],
  double width = 400,
  double scale = 1,
  bool rtl = false,
  double height = 400,
  Brightness brightness = Brightness.light,
  bool outdoor = false,
  Locale? locale,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
  final FakeContextRepository repo = FakeContextRepository();
  final FakeProjectRepository projects = FakeProjectRepository();
  final FakeTemplateRepository templates = FakeTemplateRepository();
  addTearDown(repo.dispose);
  addTearDown(projects.dispose);
  addTearDown(templates.dispose);
  _ok(await templates.save(_template));
  _ok(await projects.create(aProject(id: 'p1', name: 'Inventory')));
  await repo.saveHierarchy('p1', levels);
  if (levels.isNotEmpty) {
    await repo.setLevelValue(
      projectId: 'p1',
      fieldKey: 'district',
      value: 'Kampala',
    );
  }
  final GoRouter router = GoRouter(
    initialLocation: '/capture',
    routes: <RouteBase>[
      GoRoute(
        path: '/capture',
        builder: (BuildContext _, GoRouterState _) => Scaffold(
          body: Directionality(
            textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
            child: SingleChildScrollView(
              child: ContextBar(showsEmptyLevels: showsEmptyLevels),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/projects/:projectId/context',
        builder: (BuildContext _, GoRouterState _) =>
            const Scaffold(body: Text('levels')),
        routes: <RouteBase>[
          GoRoute(
            path: 'presets',
            builder: (BuildContext _, GoRouterState _) =>
                const Scaffold(body: Text('presets')),
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
        contextRepositoryProvider.overrideWith((Ref _) => repo),
        projectRepositoryProvider.overrideWith((Ref _) => projects),
        templateRepositoryProvider.overrideWith((Ref _) => templates),
        projectSettingsStoreProvider.overrideWith(
          (Ref _) => SettingsStore.fake(
            stored: <String, Object?>{SettingKeys.openProjectId.name: 'p1'},
          ),
        ),
      ],
      child: MaterialApp.router(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: ScreenFonts.theme(
          buildTheme(brightness: brightness, outdoor: outdoor),
        ),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (router: router, repo: repo);
}

const TemplateDef _template = TemplateDef(
  id: 't1',
  templateKey: 'survey',
  name: 'Survey',
  version: 1,
  projectId: 'p1',
  fields: <FieldDef>[
    FieldDef(
      fieldKey: 'surveyor',
      label: 'Surveyor',
      type: FieldType.text,
      stickable: true,
    ),
    FieldDef(
      fieldKey: 'survey_date',
      label: 'Survey date',
      type: FieldType.date,
      stickable: true,
    ),
  ],
  identityFieldKeys: <String>[],
  rows: <TemplateRow>[],
);

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
