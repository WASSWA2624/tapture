import 'package:flutter/foundation.dart' show kIsWeb, precisionErrorTolerance;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/app.dart';
import 'package:tapture/app/feedback_host.dart';
import 'package:tapture/app/locale_controller.dart';
import 'package:tapture/app/nav_shell.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/widgets/status_line.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/photo_picker.dart';
import 'package:tapture/core/files/storage_guard.dart';
import 'package:tapture/core/files/text_store.dart';
import 'package:tapture/core/location/location_service.dart';
import 'package:tapture/core/network/network.dart';
import 'package:tapture/core/permissions/permissions_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_header_title.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_search_field.dart';
import 'package:tapture/core/widgets/error_boundary.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/fields/dictation_scope.dart';
import 'package:tapture/core/widgets/fields/field_editor.dart';
import 'package:tapture/features/capture/data/capture_persistence_impl.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/domain/capture_session_key.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/presentation/capture_controller.dart';
import 'package:tapture/features/capture/presentation/capture_guide_card.dart';
import 'package:tapture/features/capture/presentation/capture_manual_form.dart';
import 'package:tapture/features/capture/presentation/capture_screen.dart';
import 'package:tapture/features/capture/presentation/photo_tray.dart';
import 'package:tapture/features/capture/presentation/record_caption_field.dart';
import 'package:tapture/features/context/context.dart';
import 'package:tapture/features/context/presentation/context_bar.dart';
import 'package:tapture/features/context/presentation/context_providers.dart';
import 'package:tapture/features/processing/processing.dart'
    show JobStatus, processingRepositoryProvider;
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/records/records.dart'
    show recordRepositoryProvider;
import 'package:tapture/features/settings/domain/setting_keys.dart';
import 'package:tapture/features/settings/settings.dart' show SettingsStore;
import 'package:tapture/features/templates/templates.dart';

import '../../../support/a11y_matchers.dart';
import '../../../support/empty_state_matchers.dart';
import '../../../support/factories.dart';
import '../../../support/fakes/fake_capture_record_persistence.dart';
import '../../../support/fakes/fake_capture_storage_guard.dart';
import '../../../support/fakes/fake_context_repository.dart';
import '../../../support/fakes/fake_photo_repository.dart';
import '../../../support/fakes/fake_processing_repository.dart';
import '../../../support/fakes/fake_record_repository.dart';
import '../../../support/rtl_tapture_app.dart';
import '../../../support/screen_fonts.dart';
import '../../../support/screen_matrix.dart';
import '../../../support/screen_probe.dart';
import '../../projects/fakes/fake_project_repository.dart';
import '../../templates/fakes/fake_template_repository.dart';

/// Registers the same production-shell assertions for native and Chrome.
void registerCaptureWorkflowTests({required bool browser}) {
  setUpAll(ScreenFonts.loadForApp);
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
  testWidgets(
    'retired movement stays inert through shell entry edit resize and branch return',
    (tester) async {
      final SettingsStore settings = SettingsStore.fake(
        stored: <String, Object?>{
          SettingKeys.contextMovementPromptEnabled.name: true,
          SettingKeys.contextMovementMetres.name: 100,
          SettingKeys.gpsEnabled.name: true,
        },
      );
      final _ReminderLocation location = _ReminderLocation();
      final CaptureWorkflowFixture fixture = await CaptureWorkflowFixture.open(
        tester,
        cell: const ScreenMatrix(Size(393, 886), 1, Brightness.light, false),
        savedRecord: _savedRecord,
        settings: settings,
        extraOverrides: <Override>[
          locationServiceProvider.overrideWithValue(location),
          contextPermissionsProvider.overrideWithValue(
            PermissionsService.fake(
              states: const <AppPermission, PermissionState>{
                AppPermission.location: PermissionState.granted,
              },
              gpsEnabled: () => true,
            ),
          ),
        ],
      );
      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(CaptureScreen)),
      );
      final ContextRepository contexts = container.read(
        contextRepositoryProvider,
      );
      final Result<ContextState> before = await contexts.load('p1');
      final Map<String, String> snapshot = Map<String, String>.of(
        fixture.session(tester).contextSnapshot,
      );
      final GoRouter router = container.read(routerProvider);
      for (final String route in <String>[
        RoutePaths.projects,
        RoutePaths.captureRoot,
        RoutePaths.projectCapture('p1'),
        RoutePaths.projectRecordEdit('p1', 'r1'),
      ]) {
        router.go(route);
        await tester.pumpAndSettle();
        final int captureReads = location.calls;
        location.latitude += 1;
        await tester.pump(AppConstants.context.checkEvery * 3);
        tester.view.physicalSize = const Size(800, 600);
        await tester.pumpAndSettle();
        expect(find.text(Copy.contextMovementTitle), findsNothing);
        expect(find.text(Copy.contextPickerTitle('Facility')), findsNothing);
        expect(
          location.calls,
          captureReads,
          reason:
              'movement ticks do not add reminder reads to independent capture GPS',
        );
        expect(
          (await contexts.load(
            'p1',
          )).getOrElse(() => throw TestFailure('Context load failed')),
          before.getOrElse(() => throw TestFailure('Context load failed')),
        );
      }
      expect(fixture.session(tester).contextSnapshot, snapshot);
      expect(settings.read(SettingKeys.contextMovementPromptEnabled), isTrue);
      expect(settings.read(SettingKeys.contextMovementMetres), 100);
      await tester.pumpWidget(const SizedBox.shrink());
    },
    variant: platforms,
  );

  testWidgets(
    'nested Capture binds its header to the route and releases it between branches',
    (tester) async {
      await CaptureWorkflowFixture.open(
        tester,
        cell: const ScreenMatrix(Size(393, 886), 1, Brightness.light, false),
        nestedCapture: true,
      );
      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(CaptureScreen)),
      );
      container.read(currentProjectProvider.notifier).open('different-project');
      await tester.pumpAndSettle();
      AppHeaderTitle header() => tester.widget<AppHeaderTitle>(
        find.descendant(
          of: find.byType(StatusLine),
          matching: find.byType(AppHeaderTitle),
        ),
      );
      expect(header().title, 'Field project');
      expect(header().detail, 'Assets');
      expect(
        tester
            .widget<AppPage>(
              find.byKey(const ValueKey<String>('route-capture')),
            )
            .title,
        Copy.navCapture,
      );
      final GoRouter router = container.read(routerProvider);
      router.go(RoutePaths.projects);
      await tester.pumpAndSettle();
      await revealScrollableBody(
        tester,
        find.byKey(const ValueKey<String>('route-projects')),
      );
      await tester.pumpAndSettle();
      expect(header().title, Copy.navProjects);
      expect(header().detail, isNull);
      container.read(currentProjectProvider.notifier).open('p1');
      router.go(RoutePaths.captureRoot);
      await tester.pumpAndSettle();
      expect(header().title, 'Field project');
      expect(header().detail, 'Assets');
      expect(find.byType(ContextBar), findsNothing);
    },
    variant: platforms,
  );

  testWidgets(
    'RTL adapter preserves router configuration and builder subtree',
    (WidgetTester tester) async {
      final GoRouter router = GoRouter(
        routes: <RouteBase>[
          GoRoute(path: '/', builder: (_, _) => const SizedBox.shrink()),
        ],
      );
      addTearDown(router.dispose);
      const Widget input = SizedBox(key: ValueKey<String>('router-input'));
      const Widget output = SizedBox(key: ValueKey<String>('builder-output'));
      BuildContext? passedContext;
      Widget? passedChild;
      int calls = 0;
      final MaterialApp original = MaterialApp.router(
        key: const ValueKey<String>('original-router'),
        routerConfig: router,
        scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
        builder: (BuildContext context, Widget? child) {
          passedContext = context;
          passedChild = child;
          calls++;
          return output;
        },
        title: 'Fixture application',
        onGenerateTitle: (_) => 'Generated fixture title',
        onNavigationNotification: (_) => true,
        color: Colors.blue,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        highContrastTheme: ThemeData.light(),
        highContrastDarkTheme: ThemeData.dark(),
        themeMode: ThemeMode.dark,
        themeAnimationDuration: const Duration(milliseconds: 123),
        themeAnimationCurve: Curves.easeIn,
        themeAnimationStyle: AnimationStyle.noAnimation,
        locale: const Locale('en', 'XA'),
        localizationsDelegates: const <LocalizationsDelegate<Object>>[],
        localeListResolutionCallback: (_, _) => const Locale('en'),
        localeResolutionCallback: (_, _) => const Locale('en'),
        supportedLocales: const <Locale>[Locale('en'), Locale('en', 'XA')],
        debugShowMaterialGrid: true,
        showPerformanceOverlay: true,
        checkerboardRasterCacheImages: true,
        checkerboardOffscreenLayers: true,
        showSemanticsDebugger: true,
        debugShowCheckedModeBanner: false,
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.keyA): DoNothingIntent(),
        },
        actions: <Type, Action<Intent>>{
          DoNothingIntent: CallbackAction<Intent>(onInvoke: (_) => null),
        },
        restorationScopeId: 'fixture-restoration',
        scrollBehavior: const MaterialScrollBehavior(),
      );
      final MaterialApp adapted = withRtlDirectionality(original);
      final Map<String, Object?> before = _routerConfiguration(original);
      final Map<String, Object?> after = _routerConfiguration(adapted);
      expect(after.keys, orderedEquals(before.keys));
      for (final String property in before.keys) {
        expect(after[property], same(before[property]), reason: property);
      }
      BuildContext? builderContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              builderContext = context;
              return adapted.builder!(context, input);
            },
          ),
        ),
      );
      expect(calls, 1);
      expect(passedContext, same(builderContext));
      expect(passedChild, same(input));
      final Directionality direction = tester.widget<Directionality>(
        find
            .ancestor(
              of: find.byWidget(output),
              matching: find.byType(Directionality),
            )
            .first,
      );
      expect(direction.textDirection, TextDirection.rtl);
      expect(direction.child, same(output));
    },
  );
  testWidgets('font adapter preserves production theme and router contracts', (
    WidgetTester tester,
  ) async {
    final GoRouter router = GoRouter(
      routes: <RouteBase>[
        GoRoute(path: '/', builder: (_, _) => const SizedBox.shrink()),
      ],
    );
    addTearDown(router.dispose);
    final MaterialApp original = MaterialApp.router(
      routerConfig: router,
      builder: (_, Widget? child) => child ?? const SizedBox.shrink(),
      theme: buildTheme(brightness: Brightness.light),
      darkTheme: buildTheme(brightness: Brightness.dark),
      highContrastTheme: buildTheme(
        brightness: Brightness.light,
        outdoor: true,
      ),
      highContrastDarkTheme: buildTheme(
        brightness: Brightness.dark,
        outdoor: true,
      ),
    );
    final MaterialApp adapted = withTestApplicationConfiguration(
      original,
      screenFonts: true,
    );
    final Map<String, Object?> before = _routerConfiguration(original);
    final Map<String, Object?> after = _routerConfiguration(adapted);
    for (final String property in before.keys) {
      if (const <String>{
        'theme',
        'darkTheme',
        'highContrastTheme',
        'highContrastDarkTheme',
      }.contains(property)) {
        _expectFontOnlyTheme(
          before[property]! as ThemeData,
          after[property]! as ThemeData,
        );
      } else {
        expect(after[property], same(before[property]), reason: property);
      }
    }
    expect(adapted.builder, same(original.builder));
  });
  for (final Locale locale in const <Locale>[
    Locale('en'),
    Locale('en', 'XA'),
  ]) {
    for (final ScreenMatrix cell in const <ScreenMatrix>[
      ScreenMatrix(Size(393, 886), 1, Brightness.light, false),
      ScreenMatrix(Size(393, 320), 2, Brightness.light, false),
      ScreenMatrix(Size(800, 1280), 1, Brightness.light, false),
      ScreenMatrix(Size(1200, 800), 2, Brightness.light, false),
    ]) {
      testWidgets(
        'production target and guide flow ${cell.description} ${locale.toLanguageTag()}',
        (WidgetTester tester) async {
          final CaptureWorkflowFixture fixture =
              await CaptureWorkflowFixture.open(
                tester,
                cell: cell,
                locale: locale,
                direction: locale.countryCode == 'XA'
                    ? TextDirection.rtl
                    : null,
              );
          final Finder guide = find.byKey(
            const ValueKey<String>('capture-guide'),
          );
          final LocalizedCopy copy = Copy.of(
            tester.element(find.byType(CaptureScreen)),
          );
          await _verifySetupCommands(tester, fixture, copy);
          await revealScrollableBody(tester, guide);

          final SemanticsHandle semantics = tester.ensureSemantics();
          try {
            await _revealControl(tester, guide, header: false);
            await _verifyPassiveGuide(tester, copy);
            expect(ScreenProbe.layoutIssues(tester), isEmpty);
          } finally {
            semantics.dispose();
          }
        },
        variant: platforms,
      );
    }
  }
  for (final Locale locale in const <Locale>[
    Locale('en'),
    Locale('en', 'XA'),
  ]) {
    for (final ScreenMatrix cell in <ScreenMatrix>[
      ...ScreenMatrix.cells,
      for (final double scale in <double>[1, 2])
        for (final (Brightness, bool) theme in <(Brightness, bool)>[
          (Brightness.light, false),
          (Brightness.dark, false),
          (Brightness.light, true),
        ])
          ScreenMatrix(const Size(320, 740), scale, theme.$1, theme.$2),
    ]) {
      testWidgets(
        'production Capture ${cell.description} ${locale.toLanguageTag()}',
        (WidgetTester tester) async {
          final CaptureWorkflowFixture fixture =
              await CaptureWorkflowFixture.open(
                tester,
                cell: cell,
                locale: locale,
                direction: locale.countryCode == 'XA'
                    ? TextDirection.rtl
                    : null,
              );
          expect(
            find.byWidgetPredicate((Widget app) => app is TaptureApp),
            findsOneWidget,
          );
          expect(find.byType(NavShell), findsOneWidget);
          expect(find.byType(StatusLine), findsOneWidget);
          expect(find.byType(ContextBar), findsNothing);
          await revealScrollableBody(tester, find.byType(PhotoTray));
          expect(find.byType(PhotoTray), findsOneWidget);
          final LocalizedCopy localCopy = Copy.of(
            tester.element(find.byType(CaptureScreen)),
          );
          _expectAppDirection(tester, locale);
          final SemanticsHandle semantics = tester.ensureSemantics();
          try {
            await _verifySetupCommands(tester, fixture, localCopy);
            await _verifyPassiveGuide(tester, localCopy);
            for (final (Finder control, bool header) in <(Finder, bool)>[
              (
                find.byKey(const ValueKey<String>('empty-state-icon-action')),
                false,
              ),
              (_caption, false),
              (find.widgetWithText(AppButton, localCopy.captureSaveRaw), false),
              (find.byType(AppPrimaryAction), false),
            ]) {
              await _revealControl(tester, control, header: header);
              expect(control, meetsTapTarget());
              final Rect rect = tester.getRect(control);
              final Rect viewport = ScreenProbe.targetViewport(tester, control);
              final bool tall = rect.height > viewport.height;
              if (!tall) {
                expect(rect.top, greaterThanOrEqualTo(0));
                expect(rect.bottom, lessThanOrEqualTo(cell.size.height));
                final List<String> issues =
                    await ScreenProbe.accessibilityIssues(
                      tester,
                      targets: <Finder>[control],
                      within: find.byType(NavShell),
                    );
                expect(issues, isEmpty, reason: control.toString());
              } else {
                expect(
                  await ScreenProbe.accessibilityIssues(
                    tester,
                    reachableTargets: <Finder>[control],
                    within: find.byType(NavShell),
                  ),
                  isEmpty,
                  reason: control.toString(),
                );
                await _verifyReadableEnds(tester, control);
              }
              await _verifyInteraction(tester, control, fixture, localCopy);
            }
            expect(ScreenProbe.layoutIssues(tester), isEmpty);
            expect(fixture.session(tester).templateVersion, 1);
          } finally {
            semantics.dispose();
          }
        },
        variant: platforms,
      );
      testWidgets(
        'production Manual ${cell.description} ${locale.toLanguageTag()}',
        (WidgetTester tester) async {
          final CaptureWorkflowFixture fixture =
              await CaptureWorkflowFixture.open(
                tester,
                cell: cell,
                locale: locale,
                direction: locale.countryCode == 'XA'
                    ? TextDirection.rtl
                    : null,
              );
          await revealScrollableBody(tester, find.byType(AppPage));
          await _verifyManual(tester, fixture);
        },
        variant: platforms,
      );
      testWidgets(
        'production saved Capture ${cell.description} ${locale.toLanguageTag()}',
        (WidgetTester tester) async {
          final CaptureWorkflowFixture fixture =
              await CaptureWorkflowFixture.open(
                tester,
                cell: cell,
                locale: locale,
                direction: locale.countryCode == 'XA'
                    ? TextDirection.rtl
                    : null,
                savedRecord: _savedRecord,
              );
          await _revealControl(tester, find.byType(ContextBar), header: true);
          expect(find.byType(StatusLine), findsOneWidget);
          expect(find.byType(ContextBar), findsOneWidget);
          await revealScrollableBody(tester, find.byType(CaptureScreen));
          _expectAppDirection(tester, locale);
          expect(
            find.byKey(const ValueKey<String>('capture-project-field')),
            findsNothing,
          );
          expect(
            find.byKey(const ValueKey<String>('capture-template-field')),
            findsNothing,
          );
          final LocalizedCopy localCopy = Copy.of(
            tester.element(find.byType(CaptureScreen)),
          );
          final SemanticsHandle semantics = tester.ensureSemantics();
          try {
            await _revealControl(tester, find.byType(PhotoTray), header: false);
            final PhotoTray tray = tester.widget<PhotoTray>(
              find.byType(PhotoTray),
            );
            expect(
              tray.photos.map((PhotoDraft photo) => photo.id),
              orderedEquals(<String>['f1', 'f2']),
            );
            final Finder strip = find.descendant(
              of: find.byType(PhotoTray),
              matching: find.byType(ListView),
            );
            expect(
              tester.widget<ListView>(strip).scrollDirection,
              Axis.horizontal,
            );
            expect(tester.getSize(strip).height, 96);
            for (final String photoId in <String>['f1', 'f2']) {
              final Finder photo = find.byKey(
                ValueKey<String>('photo-thumb-$photoId'),
              );
              await _revealControl(tester, photo, header: false);
              for (final String action in <String>[
                'photo-corner-select-target',
                'photo-corner-remove-target',
              ]) {
                final Finder paintTarget = find.descendant(
                  of: photo,
                  matching: find.byKey(ValueKey<String>(action)),
                );
                final String label = action == 'photo-corner-select-target'
                    ? localCopy.photoSelect
                    : localCopy.captureRemovePhoto;
                final Finder target = find.ancestor(
                  of: paintTarget,
                  matching: find.byWidgetPredicate(
                    (Widget widget) =>
                        widget is Semantics &&
                        widget.properties.button == true &&
                        widget.properties.label == label &&
                        widget.properties.onTap != null,
                  ),
                );
                expect(target, findsOneWidget);
                await _revealControl(tester, target, header: false);
                await _verifyReachableControl(tester, target);
                expect(tester.getRect(target), tester.getRect(paintTarget));
                final SemanticsNode node = tester.getSemantics(target);
                expect(node.label, label);
                expect(
                  node.getSemanticsData().hasAction(SemanticsAction.tap),
                  isTrue,
                );
                await _tapPainted(tester, target);
                if (action == 'photo-corner-select-target') {
                  expect(
                    tester
                        .widget<PhotoTray>(find.byType(PhotoTray))
                        .selectedIds,
                    contains(photoId),
                  );
                  await _tapPainted(tester, target);
                  expect(
                    tester
                        .widget<PhotoTray>(find.byType(PhotoTray))
                        .selectedIds,
                    isNot(contains(photoId)),
                  );
                } else {
                  expect(
                    find.text(localCopy.captureDeletePhotoMessage),
                    findsOneWidget,
                  );
                  final Finder cancel = find.widgetWithText(
                    AppButton,
                    localCopy.cancel,
                  );
                  await tester.ensureVisible(cancel);
                  await tester.pumpAndSettle();
                  await tester.tap(cancel);
                  await tester.pumpAndSettle();
                  expect(
                    find.text(localCopy.captureDeletePhotoMessage),
                    findsNothing,
                  );
                  expect(
                    fixture
                        .session(tester)
                        .photos
                        .map((PhotoDraft photo) => photo.id),
                    orderedEquals(<String>['f1', 'f2']),
                  );
                }
              }
            }
            await _verifyPassiveGuide(tester, localCopy);
            for (final Finder control in <Finder>[
              _populatedPhotoAdd(localCopy),
              _caption,
              find.byKey(const ValueKey<String>('record-edit-save')),
            ]) {
              await _revealControl(tester, control, header: false);
              await _verifyReachableControl(tester, control);
              if (control == _caption) {
                expect(
                  tester.widget<TextField>(_caption).controller?.text,
                  'Original record caption',
                );
                await _verifyInteraction(tester, control, fixture, localCopy);
              } else if (tester.widget(control) is IndexedSemantics) {
                final SemanticsNode node = tester.getSemantics(control);
                expect(node.label, localCopy.captureAddPhoto);
                expect(
                  node.getSemanticsData().hasAction(SemanticsAction.tap),
                  isTrue,
                );
                await _tapPainted(tester, control);
                expect(
                  find.text(localCopy.captureAddSheetTitle),
                  findsOneWidget,
                );
                expect(ScreenProbe.layoutIssues(tester), isEmpty);
                Navigator.of(tester.element(find.byType(AppBottomSheet))).pop();
                await tester.pumpAndSettle();
              }
            }
            expect(fixture.session(tester).editing, isTrue);
            expect(fixture.session(tester).templateVersion, 1);
            expect(
              fixture.session(tester).captions['f1'],
              'Original photo caption',
            );
            expect(
              fixture.records.records['r1']!.recordCaption,
              'Original record caption',
            );
            expect(fixture.records.updates, isEmpty);
            expect(ScreenProbe.layoutIssues(tester), isEmpty);
          } finally {
            semantics.dispose();
          }
        },
        variant: platforms,
      );
    }
  }

  for (final Locale locale in const <Locale>[
    Locale('en'),
    Locale('en', 'XA'),
  ]) {
    for (final (Brightness, bool) theme in <(Brightness, bool)>[
      (Brightness.light, false),
      (Brightness.dark, false),
      (Brightness.light, true),
    ]) {
      testWidgets(
        'production keyboard reaches every short200 control ${theme.$1.name} ${theme.$2} ${locale.toLanguageTag()}',
        (WidgetTester tester) async {
          final CaptureWorkflowFixture fixture =
              await CaptureWorkflowFixture.open(
                tester,
                cell: ScreenMatrix(const Size(393, 320), 2, theme.$1, theme.$2),
                locale: locale,
                direction: locale.countryCode == 'XA'
                    ? TextDirection.rtl
                    : null,
              );
          await revealScrollableBody(tester, find.byType(CaptureScreen));
          _expectAppDirection(tester, locale);
          final LocalizedCopy localCopy = Copy.of(
            tester.element(find.byType(CaptureScreen)),
          );
          final String owner = fixture.session(tester).id;
          final SemanticsHandle semantics = tester.ensureSemantics();
          try {
            await _verifySetupCommands(
              tester,
              fixture,
              localCopy,
              keyboard: true,
            );
            await _verifyPassiveGuide(tester, localCopy);
            for (final (Finder control, bool header) in <(Finder, bool)>[
              (
                find.byKey(const ValueKey<String>('empty-state-icon-action')),
                false,
              ),
              (_caption, false),
              (find.widgetWithText(AppButton, localCopy.captureSaveRaw), false),
              (find.byType(AppPrimaryAction), false),
            ]) {
              await _revealControl(tester, control, header: header);
              await _focusUsingTab(tester, control);
              await _revealControl(tester, control, header: header);
              expect(_focusIsInside(control), isTrue);
              await _verifyReachableControl(tester, control);
              await _verifyKeyboardAction(tester, control, localCopy);
            }
            expect(fixture.session(tester).id, owner);
            expect(fixture.session(tester).templateVersion, 1);
            expect(ScreenProbe.layoutIssues(tester), isEmpty);
          } finally {
            semantics.dispose();
          }
        },
        variant: platforms,
      );
      testWidgets(
        'production footer keyboard saves short200 ${theme.$1.name} ${theme.$2} ${locale.toLanguageTag()}',
        (WidgetTester tester) async {
          for (final bool process in <bool>[false, true]) {
            final FakeProcessingRepository queue = FakeProcessingRepository();
            addTearDown(queue.dispose);
            final CaptureWorkflowFixture
            fixture = await CaptureWorkflowFixture.open(
              tester,
              cell: ScreenMatrix(const Size(393, 320), 2, theme.$1, theme.$2),
              locale: locale,
              direction: locale.countryCode == 'XA' ? TextDirection.rtl : null,
              extraOverrides: <Override>[
                processingRepositoryProvider.overrideWithValue(queue),
              ],
            );
            await revealScrollableBody(tester, find.byType(CaptureScreen));
            _expectAppDirection(tester, locale);
            final LocalizedCopy localCopy = Copy.of(
              tester.element(find.byType(CaptureScreen)),
            );
            final String owner = fixture.session(tester).id;
            final String caption = process
                ? 'Process keyboard evidence'
                : 'Raw keyboard evidence';
            await _revealControl(tester, _caption, header: false);
            await tester.enterText(_caption, caption);
            await tester.pumpAndSettle();
            expect(fixture.session(tester).recordCaption, caption);
            final String label = process
                ? localCopy.captureSaveAndAnalyse
                : localCopy.captureSaveRaw;
            final Finder control = process
                ? find.byType(AppPrimaryAction)
                : find.widgetWithText(AppButton, label);
            final SemanticsHandle semantics = tester.ensureSemantics();
            try {
              await _revealControl(tester, control, header: false);
              await _focusUsingTab(tester, control);
              await _verifyReachableControl(tester, control);
              await _verifyCompleteActionLabel(tester, control, label);
              expect(_focusIsInside(control), isTrue);
              await tester.sendKeyEvent(LogicalKeyboardKey.enter);
              await tester.pumpAndSettle();
              expect(fixture.records.persisted, hasLength(1));
              final CaptureSession saved = fixture.records.persisted.single;
              expect(saved.id, owner);
              expect(saved.projectId, 'p1');
              expect(saved.templateId, 't1');
              expect(saved.templateVersion, 1);
              expect(saved.recordCaption, caption);
              expect(saved.contextSnapshot, containsPair('district', 'North'));
              expect(saved.contextSnapshot, containsPair('facility', 'Clinic'));
              expect(
                saved.contextSnapshot,
                containsPair('operator', 'Field team'),
              );
              final String recordId = fixture.records.records.keys.single;
              expect(fixture.records.records[recordId]!.recordCaption, caption);
              expect(queue.stored, hasLength(process ? 1 : 0));
              if (process) {
                expect(queue.stored.single.recordId, recordId);
                expect(queue.stored.single.status, JobStatus.queued);
              }
              expect(fixture.session(tester).id, isNot(owner));
              expect(fixture.session(tester).templateId, 't1');
              expect(fixture.session(tester).templateVersion, 1);
              expect(find.text(localCopy.captureSaved), findsOneWidget);
              expect(ScreenProbe.layoutIssues(tester), isEmpty);
            } finally {
              semantics.dispose();
            }
          }
        },
        variant: platforms,
      );
    }
  }

  testWidgets(
    'reported 393x886 shell exposes six lines and primary save before scrolling',
    (WidgetTester tester) async {
      await CaptureWorkflowFixture.open(
        tester,
        cell: const ScreenMatrix(Size(393, 886), 1, Brightness.light, false),
      );
      final TextField editor = tester.widget<TextField>(_caption);
      _expectProportionalActions(tester);
      final TextStyle style = Theme.of(
        tester.element(_caption),
      ).textTheme.bodyMedium!;
      double measured(String text) {
        final TextPainter painter = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: TextDirection.ltr,
        )..layout();
        final double width = painter.width;
        painter.dispose();
        return width;
      }

      expect(
        measured('iiii'),
        lessThan(measured('MMMM')),
        reason:
            'Real metrics for ${style.fontFamily}/${style.fontFamilyFallback}',
      );
      expect(editor.minLines, 6);
      expect(editor.maxLines, isNull);
      final Rect caption = tester.getRect(_caption);
      final Rect save = tester.getRect(find.byType(AppPrimaryAction));
      final Rect navigation = tester.getRect(
        find.byKey(const ValueKey<String>('nav-bar')),
      );
      expect(caption.top, greaterThan(0));
      expect(caption.bottom, lessThanOrEqualTo(navigation.top));
      expect(save.bottom, lessThanOrEqualTo(navigation.top));
      expect(ScreenProbe.layoutIssues(tester), isEmpty);
    },
    variant: platforms,
  );

  testWidgets(
    'production draft/version survives keyboard resize and keyboard traversal',
    (WidgetTester tester) async {
      final CaptureWorkflowFixture fixture = await CaptureWorkflowFixture.open(
        tester,
        cell: const ScreenMatrix(Size(393, 886), 1, Brightness.light, false),
      );
      await tester.enterText(_caption, 'Retained caption');
      await tester.pumpAndSettle();
      final String owner = fixture.session(tester).id;
      tester.view.physicalSize = const Size(800, 600);
      tester.view.viewInsets = const FakeViewPadding(bottom: 220);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      await tester.pumpAndSettle();
      await Scrollable.ensureVisible(tester.element(_caption), alignment: 0.5);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(_caption).controller?.text,
        'Retained caption',
      );
      expect(fixture.session(tester).id, owner);
      expect(fixture.session(tester).templateVersion, 1);
      FocusManager.instance.primaryFocus?.unfocus();
      bool captionReached = false;
      for (int index = 0; index < 30; index++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        final BuildContext? focused =
            FocusManager.instance.primaryFocus?.context;
        if (focused?.findAncestorWidgetOfExactType<RecordCaptionField>() !=
            null) {
          captionReached = true;
          break;
        }
      }
      expect(captionReached, isTrue);
      expect(ScreenProbe.layoutIssues(tester), isEmpty);
    },
    variant: platforms,
  );

  testWidgets(
    'production shell retains failed caption input and retries local writes',
    (WidgetTester tester) async {
      final _SessionStore store = _SessionStore();
      final CaptureWorkflowFixture fixture = await CaptureWorkflowFixture.open(
        tester,
        cell: const ScreenMatrix(Size(393, 886), 1, Brightness.light, false),
        store: store,
      );
      await tester.enterText(_caption, 'Original caption');
      await tester.pumpAndSettle();
      store.refusesWrites = true;
      await tester.enterText(_caption, 'Pending caption');
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(_caption).controller?.text,
        'Pending caption',
      );
      expect(fixture.session(tester).recordCaption, 'Original caption');
      tester.view.physicalSize = const Size(800, 600);
      tester.view.viewInsets = const FakeViewPadding(bottom: 220);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(_caption).controller?.text,
        'Pending caption',
      );
      expect(find.text(Copy.captureSaved), findsNothing);
      store.refusesWrites = false;
      await tester.enterText(_caption, 'Pending caption ');
      await tester.pumpAndSettle();
      expect(fixture.session(tester).recordCaption, 'Pending caption ');
    },
    variant: platforms,
  );

  testWidgets('production shell saves raw offline without a template', (
    WidgetTester tester,
  ) async {
    final CaptureWorkflowFixture fixture = await CaptureWorkflowFixture.open(
      tester,
      cell: const ScreenMatrix(Size(393, 886), 1, Brightness.light, false),
      offline: true,
      shownTemplates: const <TemplateDef>[],
    );
    await Scrollable.ensureVisible(tester.element(_caption));
    await tester.enterText(_caption, 'Offline caption');
    await tester.pumpAndSettle();
    final LocalizedCopy localCopy = Copy.of(
      tester.element(find.byType(CaptureScreen)),
    );
    final Finder raw = find.widgetWithText(AppButton, localCopy.captureSaveRaw);
    await Scrollable.ensureVisible(tester.element(raw));
    await tester.pumpAndSettle();
    await tester.tap(raw);
    await tester.pumpAndSettle();
    expect(fixture.records.persisted.single.recordCaption, 'Offline caption');
    expect(fixture.records.persisted.single.templateId, isEmpty);
  }, variant: platforms);

  if (!browser) {
    for (final ({String name, ScreenMatrix cell}) corner
        in ScreenMatrix.corners) {
      testWidgets('production Capture visual ${corner.name}', (
        WidgetTester tester,
      ) async {
        await CaptureWorkflowFixture.open(tester, cell: corner.cell);
        // A short shell scrolls its natural-height context header before its
        // deferred production branch is mounted. Snapshot the reachable page.
        await revealScrollableBody(tester, find.byType(CaptureScreen));
        expect(ScreenProbe.layoutIssues(tester), isEmpty);
        _expectProportionalActions(tester);
        await expectLater(
          find.byWidgetPredicate((Widget app) => app is TaptureApp),
          matchesGoldenFile('goldens/capture_workflow_${corner.name}.png'),
        );
      });
    }
    testWidgets('production Capture visual reported_light', (
      WidgetTester tester,
    ) async {
      await CaptureWorkflowFixture.open(
        tester,
        cell: const ScreenMatrix(Size(393, 886), 1, Brightness.light, false),
      );
      expect(ScreenProbe.layoutIssues(tester), isEmpty);
      _expectProportionalActions(tester);
      await expectLater(
        find.byWidgetPredicate((Widget app) => app is TaptureApp),
        matchesGoldenFile('goldens/capture_workflow_reported_light.png'),
      );
    });
  }
}

Map<String, Object?> _routerConfiguration(MaterialApp app) => <String, Object?>{
  'key': app.key,
  'scaffoldMessengerKey': app.scaffoldMessengerKey,
  'routeInformationProvider': app.routeInformationProvider,
  'routeInformationParser': app.routeInformationParser,
  'routerDelegate': app.routerDelegate,
  'routerConfig': app.routerConfig,
  'backButtonDispatcher': app.backButtonDispatcher,
  'title': app.title,
  'onGenerateTitle': app.onGenerateTitle,
  'onNavigationNotification': app.onNavigationNotification,
  'color': app.color,
  'theme': app.theme,
  'darkTheme': app.darkTheme,
  'highContrastTheme': app.highContrastTheme,
  'highContrastDarkTheme': app.highContrastDarkTheme,
  'themeMode': app.themeMode,
  'themeAnimationDuration': app.themeAnimationDuration,
  'themeAnimationCurve': app.themeAnimationCurve,
  'themeAnimationStyle': app.themeAnimationStyle,
  'locale': app.locale,
  'localizationsDelegates': app.localizationsDelegates,
  'localeListResolutionCallback': app.localeListResolutionCallback,
  'localeResolutionCallback': app.localeResolutionCallback,
  'supportedLocales': app.supportedLocales,
  'debugShowMaterialGrid': app.debugShowMaterialGrid,
  'showPerformanceOverlay': app.showPerformanceOverlay,
  'checkerboardRasterCacheImages': app.checkerboardRasterCacheImages,
  'checkerboardOffscreenLayers': app.checkerboardOffscreenLayers,
  'showSemanticsDebugger': app.showSemanticsDebugger,
  'debugShowCheckedModeBanner': app.debugShowCheckedModeBanner,
  'shortcuts': app.shortcuts,
  'actions': app.actions,
  'restorationScopeId': app.restorationScopeId,
  'scrollBehavior': app.scrollBehavior,
  'navigatorKey': app.navigatorKey,
  'navigatorObservers': app.navigatorObservers,
  'onGenerateRoute': app.onGenerateRoute,
  'onGenerateInitialRoutes': app.onGenerateInitialRoutes,
  'onUnknownRoute': app.onUnknownRoute,
  'home': app.home,
  'routes': app.routes,
  'initialRoute': app.initialRoute,
};

void _expectFontOnlyTheme(ThemeData before, ThemeData after) {
  // ThemeData equality covers every unchanged field, including colours,
  // spacing, shapes, density, extensions and non-text component behavior.
  expect(
    after,
    before.copyWith(
      textTheme: after.textTheme,
      primaryTextTheme: after.primaryTextTheme,
      appBarTheme: after.appBarTheme,
      filledButtonTheme: after.filledButtonTheme,
      outlinedButtonTheme: after.outlinedButtonTheme,
      textButtonTheme: after.textButtonTheme,
    ),
  );
  expect(after.textTheme, before.textTheme.apply(fontFamily: 'Roboto'));
  expect(
    after.primaryTextTheme,
    before.primaryTextTheme.apply(fontFamily: 'Roboto'),
  );
  expect(
    after.appBarTheme,
    before.appBarTheme.copyWith(
      titleTextStyle: before.appBarTheme.titleTextStyle?.copyWith(
        fontFamily: 'Roboto',
      ),
    ),
  );
  for (final (ButtonStyle?, ButtonStyle?) styles
      in <(ButtonStyle?, ButtonStyle?)>[
        (before.filledButtonTheme.style, after.filledButtonTheme.style),
        (before.outlinedButtonTheme.style, after.outlinedButtonTheme.style),
        (before.textButtonTheme.style, after.textButtonTheme.style),
      ]) {
    expect(styles.$2, styles.$1!.copyWith(textStyle: styles.$2!.textStyle));
    for (final Set<WidgetState> states in <Set<WidgetState>>[
      <WidgetState>{},
      for (final WidgetState state in WidgetState.values) <WidgetState>{state},
      WidgetState.values.toSet(),
    ]) {
      expect(
        styles.$2!.textStyle!.resolve(states),
        styles.$1!.textStyle!.resolve(states)!.copyWith(fontFamily: 'Roboto'),
      );
    }
  }
}

void _expectAppDirection(WidgetTester tester, Locale locale) {
  expect(find.byType(DictationScope), findsOneWidget);
  expect(find.byType(FeedbackHost), findsOneWidget);
  expect(find.byType(ErrorBoundary), findsOneWidget);
  final TextDirection direction = locale.countryCode == 'XA'
      ? TextDirection.rtl
      : TextDirection.ltr;
  expect(
    Directionality.of(tester.element(find.byType(CaptureScreen))),
    direction,
  );
  expect(Directionality.of(tester.element(find.byType(NavShell))), direction);
}

final Finder _caption = find.descendant(
  of: find.byType(RecordCaptionField),
  matching: find.byType(TextField),
);

Future<void> _verifyPassiveGuide(
  WidgetTester tester,
  LocalizedCopy copy,
) async {
  final Finder guide = find.byType(CaptureGuideCard);
  expect(guide, findsOneWidget);
  expect(
    find.byKey(const ValueKey<String>('capture-guide-toggle')),
    findsNothing,
  );
  expect(find.text(copy.captureGuideTitle), findsNothing);
  expect(
    find.descendant(of: guide, matching: find.text(copy.captureGuidePhotos)),
    findsOneWidget,
  );
  expect(
    find.descendant(of: guide, matching: find.text('Serial number')),
    findsOneWidget,
  );
  expect(
    find.descendant(of: guide, matching: find.text(copy.captureGuideCaption)),
    findsNothing,
  );
  await revealScrollableBody(tester, guide);
  await _verifyReadableEnds(tester, guide);
}

void _expectProportionalActions(WidgetTester tester) {
  final LocalizedCopy copy = Copy.of(
    tester.element(find.byType(CaptureScreen)),
  );
  for (final (Finder control, String label) in <(Finder, String)>[
    (find.widgetWithText(AppButton, copy.captureSaveRaw), copy.captureSaveRaw),
    (find.byType(AppPrimaryAction), copy.captureSaveAndAnalyse),
  ]) {
    _expectProportionalLabel(tester, control, label);
  }
}

void _expectProportionalLabel(
  WidgetTester tester,
  Finder control,
  String label,
) {
  final RenderParagraph paragraph = tester
      .renderObjectList<RenderParagraph>(
        find.descendant(of: control, matching: find.byType(RichText)),
      )
      .singleWhere(
        (RenderParagraph paragraph) => paragraph.text.toPlainText() == label,
      );
  double measured(String text) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: paragraph.text.style),
      textDirection: paragraph.textDirection,
      textScaler: paragraph.textScaler,
    )..layout();
    final double width = painter.width;
    painter.dispose();
    return width;
  }

  expect(
    measured('iiii'),
    lessThan(measured('MMMM')),
    reason:
        'Actual $label render style ${paragraph.text.style}; family ${paragraph.text.style?.fontFamily}; fallback ${paragraph.text.style?.fontFamilyFallback}',
  );
}

Finder _populatedPhotoAdd(LocalizedCopy copy) => find.ancestor(
  of: find.byWidgetPredicate(
    (Widget widget) =>
        widget is Semantics &&
        widget.properties.button == true &&
        widget.properties.label == copy.captureAddPhoto,
  ),
  matching: find.byType(IndexedSemantics),
);

Future<void> _verifyReachableControl(
  WidgetTester tester,
  Finder control,
) async {
  expect(control, meetsTapTarget());
  final Rect rect = tester.getRect(control);
  final Rect viewport = ScreenProbe.targetViewport(tester, control);
  final bool tall = rect.height > viewport.height;
  final List<String> issues = await ScreenProbe.accessibilityIssues(
    tester,
    targets: tall ? null : <Finder>[control],
    reachableTargets: tall ? <Finder>[control] : null,
    within: find.byType(AppBottomSheet).evaluate().isNotEmpty
        ? find.byType(AppBottomSheet)
        : find.byType(NavShell),
  );
  expect(
    issues,
    isEmpty,
    reason: issues.isEmpty
        ? control.toString()
        : '$control; paint=$rect; viewport=$viewport; semantics=${tester.getSemantics(control).toStringDeep()}',
  );
  if (tall) await _verifyReadableEnds(tester, control);
}

bool _focusIsInside(Finder control) {
  final BuildContext? focused = FocusManager.instance.primaryFocus?.context;
  if (focused == null) return false;
  final Set<Element> controls = control.evaluate().toSet();
  bool inside = controls.contains(focused);
  focused.visitAncestorElements((Element element) {
    if (controls.contains(element)) inside = true;
    return !inside;
  });
  return inside;
}

Future<void> _verifySetupCommands(
  WidgetTester tester,
  CaptureWorkflowFixture fixture,
  LocalizedCopy copy, {
  bool keyboard = false,
}) async {
  expect(find.byType(ContextBar), findsNothing);
  expect(
    find.byKey(const ValueKey<String>('capture-project-field')),
    findsNothing,
  );
  expect(
    find.byKey(const ValueKey<String>('capture-template-field')),
    findsNothing,
  );
  final AppPage page = tester.widget<AppPage>(
    find.byKey(const ValueKey<String>('route-capture')),
  );
  expect(page.title, copy.navCapture);
  expect(page.headerTitle, 'Field project');
  expect(page.headerDetail, 'Assets');
  final AppHeaderTitle header = tester.widget<AppHeaderTitle>(
    find.descendant(
      of: find.byType(StatusLine),
      matching: find.byType(AppHeaderTitle),
    ),
  );
  expect(header.title, 'Field project');
  expect(header.detail, 'Assets');
  final CaptureSession before = fixture.session(tester);
  final Finder menu = find.descendant(
    of: find.byType(StatusLine),
    matching: find.byKey(const ValueKey<String>('app-page-overflow')),
  );
  expect(menu, meetsTapTarget());
  final List<(String, String)> commands = <(String, String)>[
    ('capture-change-project', copy.captureChangeProject),
    ('capture-change-template', copy.captureChangeTemplate),
    ('capture-context-values', copy.captureContextValues),
  ];
  for (final (String key, String label) in commands) {
    if (keyboard) {
      await _focusUsingTab(tester, menu);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
    } else {
      await _tapPainted(tester, menu);
    }
    final AppOverflowMenu overflow = tester.widget<AppOverflowMenu>(menu);
    expect(
      overflow.items.take(3).map((AppOverflowAction action) => action.key),
      commands.map(((String, String) command) => ValueKey<String>(command.$1)),
    );
    final Finder command = find.byKey(ValueKey<String>(key));
    await tester.ensureVisible(command);
    await tester.pumpAndSettle();
    await _verifyReachableControl(tester, command);
    expect(
      find.descendant(of: command, matching: find.text(label)),
      findsOneWidget,
    );
    await _verifyReadableEnds(tester, command);
    _expectProportionalLabel(tester, command, label);
    final SemanticsNode node = tester.getSemantics(command);
    expect(node.label, contains(label));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    if (keyboard) {
      // Native popup menus traverse commands with arrow keys.
      final int entries = tester
          .widgetList(find.byType(PopupMenuItem<int>))
          .length;
      for (
        int index = 0;
        index <= entries && !_focusIsInside(command);
        index++
      ) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
      }
      expect(
        _focusIsInside(command),
        isTrue,
        reason: 'Arrow keys must reach $command',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
    } else {
      await _tapPainted(tester, command);
    }
    expect(find.byType(AppBottomSheet), findsOneWidget);
    if (key == 'capture-context-values') {
      for (final String fieldKey in <String>['district', 'facility']) {
        final Finder row = find.byKey(
          ValueKey<String>('context-values-level-$fieldKey'),
        );
        await tester.ensureVisible(row);
        await tester.pumpAndSettle();
        await _verifyReachableControl(tester, row);
        await _verifyReadableEnds(tester, row);
      }
      final Finder pin = find.byKey(
        const ValueKey<String>('context-values-pin-operator'),
      );
      await tester.ensureVisible(pin);
      await tester.pumpAndSettle();
      await _verifyReachableControl(tester, pin);
      expect(tester.widget<AppListTile>(pin).leading, isA<Icon>());
      for (final String action in <String>['manage', 'presets', 'pins']) {
        final Finder row = find.byKey(
          ValueKey<String>('context-values-$action'),
        );
        await tester.ensureVisible(row);
        await tester.pumpAndSettle();
        await _verifyReachableControl(tester, row);
        if (keyboard) await _focusUsingTab(tester, row, reset: false);
      }
    } else {
      expect(find.byType(AppSearchField), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(AppSearchField))),
        Directionality.of(tester.element(find.byType(CaptureScreen))),
      );
      await tester.enterText(
        find.descendant(
          of: find.byType(AppSearchField),
          matching: find.byType(TextField),
        ),
        key == 'capture-change-project' ? 'Field' : 'Assets',
      );
      await tester.pump(AppConstants.interaction.debounce);
      await tester.pumpAndSettle();
      // The choice ListView's index owns this row's semantic node.
      final Finder option = find.widgetWithText(
        AppListTile,
        key == 'capture-change-project' ? 'Field project' : 'Assets',
      );
      await tester.scrollUntilVisible(
        option,
        80,
        scrollable: find
            .descendant(
              of: find.byType(AppBottomSheet),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(option, findsOneWidget);
      final Finder row = find.ancestor(
        of: option,
        matching: find.byType(IndexedSemantics),
      );
      expect(row, findsOneWidget);
      await tester.ensureVisible(row);
      await _verifyReachableControl(tester, row);
    }
    expect(ScreenProbe.layoutIssues(tester), isEmpty);
    Navigator.of(tester.element(find.byType(AppBottomSheet))).pop();
    await tester.pumpAndSettle();
    final CaptureSession after = fixture.session(tester);
    expect(after.id, before.id);
    expect(after.projectId, before.projectId);
    expect(after.templateId, before.templateId);
    expect(after.photos, before.photos);
    expect(after.captions, before.captions);
    expect(after.contextSnapshot, before.contextSnapshot);
  }
}

Future<void> _focusUsingTab(
  WidgetTester tester,
  Finder control, {
  bool reset = true,
}) async {
  if (reset) {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }
  final int available = FocusManager.instance.rootScope.descendants
      .where((FocusNode node) => node.canRequestFocus && !node.skipTraversal)
      .length;
  for (int index = 0; index <= available && !_focusIsInside(control); index++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
  }
  expect(_focusIsInside(control), isTrue, reason: 'Tab must reach $control');
}

Future<void> _verifyKeyboardAction(
  WidgetTester tester,
  Finder control,
  LocalizedCopy localCopy,
) async {
  final Key? key = tester.widget(control).key;
  final bool picker =
      key == const ValueKey<String>('capture-project-field') ||
      key == const ValueKey<String>('capture-template-field');
  if (picker || key == const ValueKey<String>('empty-state-icon-action')) {
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(AppBottomSheet), findsOneWidget);
    if (picker) {
      expect(find.byType(AppSearchField), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(AppSearchField))),
        Directionality.of(tester.element(find.byType(CaptureScreen))),
      );
    } else {
      expect(find.text(localCopy.captureAddSheetTitle), findsOneWidget);
    }
    expect(ScreenProbe.layoutIssues(tester), isEmpty);
    Navigator.of(tester.element(find.byType(AppBottomSheet))).pop();
    await tester.pumpAndSettle();
  } else if (control == _caption) {
    final EditableText editor = tester.widget<EditableText>(
      find.descendant(of: control, matching: find.byType(EditableText)),
    );
    expect(editor.focusNode.hasFocus, isTrue);
    await tester.enterText(control, 'Keyboard caption');
    await tester.pumpAndSettle();
    expect(editor.controller.text, 'Keyboard caption');
  }
}

const CaptureSession _savedRecord = CaptureSession(
  id: 'r1',
  recordId: 'r1',
  projectId: 'p1',
  templateId: 't1',
  templateVersion: 1,
  editing: true,
  contextSnapshot: <String, String>{
    'district': 'North',
    'facility': 'Clinic',
    'operator': 'Field team',
  },
  photos: <PhotoDraft>[
    PhotoDraft(
      id: 'f1',
      projectId: 'p1',
      recordId: 'r1',
      relativePath: 'photos/f1.jpg',
      sha256: 'f1-sha',
      sortOrder: 0,
    ),
    PhotoDraft(
      id: 'f2',
      projectId: 'p1',
      recordId: 'r1',
      relativePath: 'photos/f2.jpg',
      sha256: 'f2-sha',
      sortOrder: 1,
    ),
  ],
  captions: <String, String>{
    '': 'Original record caption',
    'f1': 'Original photo caption',
  },
);

Future<void> _revealControl(
  WidgetTester tester,
  Finder control, {
  required bool header,
}) async {
  void positionHeader() {
    for (final NestedScrollViewState state
        in tester.stateList<NestedScrollViewState>(
          find.byType(NestedScrollView),
        )) {
      if (state.outerController.hasClients) {
        state.outerController.jumpTo(
          header ? 0 : state.outerController.position.maxScrollExtent,
        );
      }
    }
  }

  positionHeader();
  await tester.pumpAndSettle();
  await revealScrollableBody(tester, control);
  expect(control, findsOneWidget);
  await Scrollable.ensureVisible(tester.element(control), alignment: 0.5);
  await tester.pumpAndSettle();
  if (!header) {
    positionHeader();
    await tester.pumpAndSettle();
    final ScrollableState? inner = Scrollable.maybeOf(tester.element(control));
    if (inner?.position.axis == Axis.vertical) {
      await inner!.position.ensureVisible(
        tester.renderObject(control),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
    }
  }
}

Future<void> _revealPortion(
  WidgetTester tester,
  Finder control,
  Rect Function() portion,
) async {
  final List<ScrollPosition> positions = <ScrollPosition>[];
  tester.element(control).visitAncestorElements((Element element) {
    if (element is StatefulElement && element.state is ScrollableState) {
      final ScrollPosition position =
          (element.state as ScrollableState).position;
      if (position.axis == Axis.vertical &&
          position.maxScrollExtent > position.minScrollExtent) {
        positions.add(position);
      }
    }
    return true;
  });
  bool contained() {
    final Rect viewport = ScreenProbe.targetViewport(tester, control);
    final Rect rect = portion();
    return rect.isFinite &&
        rect.left >= viewport.left - precisionErrorTolerance &&
        rect.right <= viewport.right + precisionErrorTolerance &&
        rect.top >= viewport.top - precisionErrorTolerance &&
        rect.bottom <= viewport.bottom + precisionErrorTolerance;
  }

  for (final ScrollPosition position in positions) {
    if (contained()) break;
    final Rect viewport = ScreenProbe.targetViewport(tester, control);
    final Rect rect = portion();
    final double next = (position.pixels + rect.center.dy - viewport.center.dy)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    position.jumpTo(next);
    await tester.pumpAndSettle();
  }
  expect(
    contained(),
    isTrue,
    reason:
        'Meaningful portion ${portion()} must be reachable inside '
        '${ScreenProbe.targetViewport(tester, control)}: $control',
  );
}

Future<void> _verifyReadableEnds(WidgetTester tester, Finder control) async {
  final List<RenderParagraph> paragraphs = <RenderParagraph>[];
  void visit(RenderObject render) {
    if (render is RenderParagraph) paragraphs.add(render);
    render.visitChildren(visit);
  }

  visit(tester.renderObject(control));
  for (final RenderParagraph paragraph in paragraphs) {
    expect(paragraph.didExceedMaxLines, isFalse);
    final String text = paragraph.text.toPlainText();
    final List<TextBox> boxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: text.length),
    );
    if (boxes.isEmpty) continue;
    for (final TextBox box in <TextBox>[boxes.first, boxes.last]) {
      await _revealPortion(
        tester,
        control,
        () => MatrixUtils.transformRect(
          paragraph.getTransformTo(null),
          box.toRect(),
        ),
      );
    }
  }
}

Future<void> _verifyCompleteActionLabel(
  WidgetTester tester,
  Finder control,
  String label,
) async {
  final Finder text = find.descendant(
    of: control,
    matching: find.byWidgetPredicate(
      (Widget widget) =>
          widget is RichText &&
          widget.text.toPlainText(includeSemanticsLabels: false) == label,
    ),
  );
  expect(
    text,
    findsOneWidget,
    reason:
        'The painted label $label must be complete: ${tester.widgetList<RichText>(find.descendant(of: control, matching: find.byType(RichText))).map((RichText text) => text.text.toPlainText()).toList()}',
  );
  final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(text);
  expect(paragraph.didExceedMaxLines, isFalse);
  _expectProportionalLabel(tester, control, label);
  final List<TextBox> boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: label.length),
  );
  expect(boxes, isNotEmpty);
  for (final TextBox box in boxes) {
    await _revealPortion(
      tester,
      control,
      () => MatrixUtils.transformRect(
        paragraph.getTransformTo(null),
        box.toRect(),
      ),
    );
  }
  Rect fullParagraph() => MatrixUtils.transformRect(
    paragraph.getTransformTo(null),
    paragraph.paintBounds,
  );
  final Rect viewport = ScreenProbe.targetViewport(tester, control);
  if (fullParagraph().height <= viewport.height + precisionErrorTolerance) {
    await _revealPortion(tester, control, fullParagraph);
  }
  expect(ScreenProbe.reachabilityIssues(tester, control), isEmpty);
  final Finder button = find.descendant(
    of: control,
    matching: find.byWidgetPredicate(
      (Widget widget) => widget is ButtonStyleButton,
    ),
  );
  expect(button, findsOneWidget);
  final SemanticsNode node = tester.getSemantics(button);
  expect(node.label, label);
  expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
}

Future<void> _tapPainted(WidgetTester tester, Finder control) async {
  await _revealControl(tester, control, header: false);
  expect(ScreenProbe.reachabilityIssues(tester, control), isEmpty);
  final Rect region = tester
      .getRect(control)
      .intersect(ScreenProbe.targetViewport(tester, control));
  await tester.tapAt(region.center);
  await tester.pumpAndSettle();
}

Future<void> _verifyInteraction(
  WidgetTester tester,
  Finder control,
  CaptureWorkflowFixture fixture,
  LocalizedCopy localCopy,
) async {
  final Widget widget = tester.widget(control);
  if (widget.key == const ValueKey<String>('capture-project-field') ||
      widget.key == const ValueKey<String>('capture-template-field')) {
    await _tapPainted(tester, control);
    expect(find.byType(AppBottomSheet), findsOneWidget);
    expect(find.byType(AppSearchField), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(AppSearchField))),
      Directionality.of(tester.element(find.byType(CaptureScreen))),
    );
    expect(ScreenProbe.layoutIssues(tester), isEmpty);
    Navigator.of(tester.element(find.byType(AppSearchField))).pop();
    await tester.pumpAndSettle();
  } else if (widget.key == const ValueKey<String>('empty-state-icon-action')) {
    await _tapPainted(tester, control);
    expect(find.text(localCopy.captureAddSheetTitle), findsOneWidget);
    expect(
      find.widgetWithText(AppButton, localCopy.captureChoosePhoto),
      findsOneWidget,
    );
    expect(ScreenProbe.layoutIssues(tester), isEmpty);
    Navigator.of(tester.element(find.byType(AppBottomSheet))).pop();
    await tester.pumpAndSettle();
  } else if (control == _caption) {
    await _tapPainted(tester, control);
    const String text =
        'First caption line\nSecond caption line\n'
        'Third caption line\nFourth caption line\n'
        'Fifth caption line\nLast caption line';
    await tester.enterText(control, text);
    await tester.pumpAndSettle();
    expect(fixture.session(tester).recordCaption, text);
    final EditableTextState editable = tester.state<EditableTextState>(
      find.descendant(of: control, matching: find.byType(EditableText)),
    );
    expect(editable.widget.focusNode.hasFocus, isTrue);
    expect(
      tester.getSemantics(control).label,
      contains(localCopy.captureRecordCaption),
    );
    expect(tester.getSemantics(control).value, text);
    for (final int offset in <int>[0, text.length]) {
      editable.widget.controller.selection = TextSelection.collapsed(
        offset: offset,
      );
      await tester.pumpAndSettle();
      final RenderEditable render = editable.renderEditable;
      final Rect caret = render.getLocalRectForCaret(
        TextPosition(offset: offset),
      );
      render.showOnScreen(rect: caret);
      await tester.pumpAndSettle();
      await _revealPortion(
        tester,
        control,
        () => MatrixUtils.transformRect(render.getTransformTo(null), caret),
      );
    }
    final Finder panel = find.byKey(
      const ValueKey<String>('capture-caption-guide'),
    );
    expect(panel, findsNothing);
    expect(
      find.byKey(const ValueKey<String>('capture-caption-guide-close')),
      findsNothing,
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }
}

Future<void> _verifyManual(
  WidgetTester tester,
  CaptureWorkflowFixture fixture,
) async {
  final LocalizedCopy localCopy = Copy.of(
    tester.element(find.byType(CaptureScreen)),
  );
  final AppPage page = tester.widget<AppPage>(find.byType(AppPage));
  page.overflow
      .firstWhere(
        (action) => action.key == const ValueKey<String>('capture-manual-form'),
      )
      .onTap();
  await tester.pumpAndSettle();
  expect(
    Directionality.of(tester.element(find.byType(CaptureManualForm))),
    Directionality.of(tester.element(find.byType(CaptureScreen))),
  );
  final Finder search = find.descendant(
    of: find.byType(AppSearchField),
    matching: find.byType(TextField),
  );
  await Scrollable.ensureVisible(tester.element(search));
  await tester.enterText(search, ' SERIAL ');
  await tester.pump(AppConstants.interaction.debounce);
  await tester.pumpAndSettle();
  final Finder serial = find.descendant(
    of: find.byKey(const ValueKey<String>('field-editor-text-serial')),
    matching: find.byType(TextField),
  );
  await _revealManualRow(tester, serial);
  expect(serial, findsOneWidget);
  await Scrollable.ensureVisible(tester.element(serial));
  await tester.enterText(serial, 'Browser manual value');
  await tester.pumpAndSettle();
  expect(fixture.session(tester).values['serial'], 'Browser manual value');
  expect(fixture.session(tester).templateVersion, 1);
  await Scrollable.ensureVisible(tester.element(search));
  await tester.enterText(search, 'unknown field');
  await tester.pump(AppConstants.interaction.debounce);
  await tester.pumpAndSettle();
  expect(
    tester.widget<AppSearchField>(find.byType(AppSearchField)).resultCount,
    0,
  );
  final Finder empty = find.text(localCopy.fieldsNoMatch);
  await _revealManualRow(tester, empty);
  expect(empty, findsOneWidget);
  expect(
    find.byWidgetPredicate(
      (Widget widget) =>
          widget is Semantics &&
          widget.properties.liveRegion == true &&
          widget.properties.label == localCopy.fieldsCount(0),
    ),
    findsOneWidget,
  );
  final Finder clear = find.byTooltip(
    localCopy.clearField(localCopy.captureSearchFields),
  );
  await Scrollable.ensureVisible(tester.element(clear), alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.tap(clear);
  await tester.pump(AppConstants.interaction.debounce);
  await tester.pumpAndSettle();
  await _revealManualRow(tester, serial);
  expect(serial, findsOneWidget);
  expect(
    tester.widget<TextField>(serial).controller?.text,
    'Browser manual value',
  );
  expect(
    ScreenProbe.layoutIssues(tester),
    isEmpty,
    reason: _truncatedLabelDiagnostics(tester),
  );
  Navigator.of(tester.element(find.byType(CaptureManualForm))).pop();
  await tester.pumpAndSettle();
}

Future<void> _revealManualRow(WidgetTester tester, Finder row) async {
  final Finder scroll = find.byKey(
    const ValueKey<String>('capture-manual-form-scroll'),
  );
  final ScrollPosition position = tester
      .widget<CustomScrollView>(scroll)
      .controller!
      .position;
  while (row.evaluate().isEmpty && position.pixels < position.maxScrollExtent) {
    final double before = position.pixels;
    position.jumpTo(
      (before + position.viewportDimension).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
    );
    await tester.pumpAndSettle();
    if (position.pixels == before) break;
  }
}

String _truncatedLabelDiagnostics(WidgetTester tester) {
  final StringBuffer result = StringBuffer();
  for (final RenderParagraph paragraph
      in tester.allRenderObjects.whereType<RenderParagraph>()) {
    if (!paragraph.didExceedMaxLines) continue;
    result.writeln(
      '${paragraph.text.toPlainText()} maxLines=${paragraph.maxLines} overflow=${paragraph.overflow} style=${paragraph.text.style}',
    );
    int count = 0;
    for (
      RenderObject? parent = paragraph.parent;
      parent != null && count < 15;
      parent = parent.parent, count++
    ) {
      result.writeln(
        '${parent.runtimeType}${parent is RenderOpacity
            ? ' opacity=${parent.opacity}'
            : parent is RenderAnimatedOpacity
            ? ' opacity=${parent.opacity.value}'
            : ''}',
      );
    }
  }
  return result.toString();
}

/// Browser-safe owned providers around the real router and navigation shell.
final class CaptureWorkflowFixture {
  CaptureWorkflowFixture._(this.records, this.sessionKey);

  /// Captured records emitted through the production controller's writer port.
  final FakeCaptureRecordPersistence records;

  /// The production controller owner, including the separate saved-record key.
  final String sessionKey;

  static Future<CaptureWorkflowFixture> open(
    WidgetTester tester, {
    required ScreenMatrix cell,
    Locale locale = const Locale('en'),
    TextDirection? direction,
    bool offline = false,
    TextStore? store,
    SettingsStore? settings,
    List<TemplateDef>? shownTemplates,
    CaptureSession? savedRecord,
    bool nestedCapture = false,
    List<Override> extraOverrides = const <Override>[],
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = cell.size;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 16);
    tester.platformDispatcher.textScaleFactorTestValue = cell.textScale;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetPadding();
      tester.view.resetViewInsets();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    final FakeProjectRepository projects = FakeProjectRepository();
    final FakeTemplateRepository templates = FakeTemplateRepository();
    final FakeContextRepository contexts = FakeContextRepository();
    final FakePhotoRepository photos = FakePhotoRepository();
    final FakeRecordRepository recordRepository = FakeRecordRepository();
    addTearDown(projects.dispose);
    addTearDown(templates.dispose);
    addTearDown(contexts.dispose);
    addTearDown(photos.dispose);
    addTearDown(recordRepository.dispose);
    await projects.create(aProject(id: 'p1', name: 'Field project'));
    for (final TemplateDef template
        in shownTemplates ??
            <TemplateDef>[
              aTemplate(
                id: 't1',
                projectId: 'p1',
                name: 'Assets',
                fields: const <FieldDef>[
                  FieldDef(
                    fieldKey: 'serial',
                    label: 'Serial number',
                    type: FieldType.text,
                    identity: true,
                    requiredness: Requiredness.required,
                  ),
                  FieldDef(
                    fieldKey: 'condition',
                    label: 'Condition',
                    type: FieldType.text,
                    requiredness: Requiredness.recommended,
                  ),
                ],
              ),
            ]) {
      await templates.save(template);
    }
    await contexts.saveHierarchy('p1', const <ContextLevel>[
      ContextLevel(fieldKey: 'district', order: 0, label: 'District'),
      ContextLevel(fieldKey: 'facility', order: 1, label: 'Facility'),
    ]);
    await contexts.setLevelValue(
      projectId: 'p1',
      fieldKey: 'district',
      value: 'North',
    );
    await contexts.setLevelValue(
      projectId: 'p1',
      fieldKey: 'facility',
      value: 'Clinic',
    );
    await contexts.savePinned('p1', const <String, String>{
      'operator': 'Field team',
    });
    final AppThemeMode mode = cell.outdoor
        ? AppThemeMode.outdoor
        : cell.brightness == Brightness.dark
        ? AppThemeMode.dark
        : AppThemeMode.light;
    final FakeCaptureRecordPersistence records = FakeCaptureRecordPersistence();
    if (savedRecord != null) {
      final String recordId = savedRecord.recordId!;
      records.records[recordId] = savedRecord;
      recordRepository.seedEntry(
        aRecordEntry(
          id: recordId,
          projectId: savedRecord.projectId,
          templateId: savedRecord.templateId,
          caption: savedRecord.recordCaption,
          context: savedRecord.contextSnapshot,
          photos: savedRecord.photos.length,
        ),
      );
      for (final PhotoDraft photo in savedRecord.photos) {
        await photos.save(photo.asAsset);
      }
    }
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        retry: (int _, Object _) => null,
        overrides: <Override>[
          networkStateProvider.overrideWith(
            (Ref _) => Stream<NetworkState>.value(
              offline ? NetworkState.offline : NetworkState.online,
            ),
          ),
          offlineNowProvider.overrideWithValue(offline),
          projectSettingsStoreProvider.overrideWithValue(
            settings ?? SettingsStore.fake(),
          ),
          projectRepositoryProvider.overrideWith((Ref _) => projects),
          templateRepositoryProvider.overrideWith((Ref _) => templates),
          contextRepositoryProvider.overrideWith((Ref _) => contexts),
          photoRepositoryProvider.overrideWith((Ref _) => photos),
          recordRepositoryProvider.overrideWith((Ref _) => recordRepository),
          photoPickerProvider.overrideWithValue(
            const PhotoPicker.fake(canTakePhoto: true),
          ),
          storageGuardProvider.overrideWithValue(FakeCaptureStorageGuard()),
          fieldEditorBindingsProvider.overrideWithValue(
            templateFieldEditorBindings,
          ),
          capturePersistenceProvider.overrideWith(
            (Ref _) => CapturePersistenceImpl(
              photos: photos,
              store: store ?? TextStore.memory(),
            ),
          ),
          captureRecordWriterProvider.overrideWithValue(records),
          captureClockProvider.overrideWithValue(
            FixedClock(DateTime.utc(2026, 10, 9, 9)),
          ),
          themeModeProvider.overrideWith(
            () => ThemeModeController.withStore(
              TextStore.memory(<String, String>{
                AppConstants.preferences.themeMode: mode.name,
              }),
            ),
          ),
          ...extraOverrides,
        ],
        child: !kIsWeb
            ? ScreenTaptureApp(direction: direction)
            : direction == TextDirection.rtl
            ? const RtlTaptureApp()
            : const TaptureApp(receiveIncomingBundles: false),
      ),
    );
    await tester.pumpAndSettle();
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byWidgetPredicate((Widget app) => app is TaptureApp)),
    );
    container.read(appLocaleProvider.notifier).select(locale);
    container.read(openProjectIdProvider.notifier).open('p1');
    final GoRouter router = container.read(routerProvider);
    router.go(
      savedRecord == null
          ? nestedCapture
                ? RoutePaths.projectCapture('p1')
                : RoutePaths.captureRoot
          : RoutePaths.projectRecordEdit(
              savedRecord.projectId,
              savedRecord.recordId!,
            ),
    );
    await tester.pumpAndSettle();
    return CaptureWorkflowFixture._(
      records,
      savedRecord == null
          ? 'p1'
          : CaptureSessionKey.edit(savedRecord.recordId!),
    );
  }

  CaptureSession session(WidgetTester tester) => ProviderScope.containerOf(
    tester.element(find.byType(CaptureScreen)),
  ).read(captureControllerProvider(sessionKey));
}

final class _SessionStore implements TextStore {
  final TextStore _backing = TextStore.memory();
  bool refusesWrites = false;

  @override
  String? read() => _backing.read();

  @override
  Future<void> write(String contents) async {
    if (refusesWrites) {
      throw const StorageFailure(message: 'Session write failed');
    }
    await _backing.write(contents);
  }
}

/// Granted, moving GPS which would have activated the retired reminder.
final class _ReminderLocation implements LocationService {
  int calls = 0;
  double latitude = 0;
  @override
  Future<Result<GeoFix?>> currentFix({
    Duration timeout = AppConstants.locationTimeout,
  }) async {
    calls++;
    return Success<GeoFix?>(
      GeoFix(
        latitude: latitude,
        longitude: 0,
        accuracyMetres: 5,
        capturedAt: DateTime.utc(2026, 10, 9),
      ),
    );
  }
}
