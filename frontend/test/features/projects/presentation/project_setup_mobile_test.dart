import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/backend/relay_snapshot.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/features/account/presentation/relay_controller.dart';
import 'package:tapture/features/account/presentation/relay_route.dart';
import 'package:tapture/features/context/domain/context_state.dart';
import 'package:tapture/features/context/presentation/context_providers.dart';
import 'package:tapture/features/context/presentation/context_values_sheet.dart';
import 'package:tapture/features/projects/presentation/project_create_screen.dart';
import 'package:tapture/features/projects/presentation/project_edit_screen.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/settings.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';
import '../../../support/pump_app.dart';
import '../../../support/screen_fonts.dart';
import '../fakes/fake_project_repository.dart';

void main() {
  setUpAll(ScreenFonts.loadForApp);

  testWidgets('grouped project creation guards typed input when leaving', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository projects = FakeProjectRepository();
    addTearDown(projects.dispose);
    await _pump(
      tester,
      Builder(
        builder: (BuildContext context) => Scaffold(
          body: TextButton(
            onPressed: () => unawaited(
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const ProjectCreateScreen(),
                ),
              ),
            ),
            child: const Text('Open create'),
          ),
        ),
      ),
      projects,
    );
    await tester.tap(find.text('Open create'));
    await tester.pumpAndSettle();
    await tester.enterText(_field(Copy.projectName), 'Field inventory');
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text(Copy.unsavedChanges), findsOneWidget);
    await tester.tap(find.text(Copy.cancel));
    await tester.pumpAndSettle();
    expect(
      tester.widget<AppTextField>(_field(Copy.projectName)).controller.text,
      'Field inventory',
    );
    expect(projects.stored, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'grouped project editing keeps draft values after a failed save',
    (WidgetTester tester) async {
      final FakeProjectRepository projects = (await _seededProjects())
        ..updateFailure = const StorageFailure(message: 'The device is full.');
      addTearDown(projects.dispose);
      await _pump(
        tester,
        const ProjectEditScreen(projectId: 'project'),
        projects,
        scale: 2,
      );
      await tester.enterText(_field(Copy.projectName), 'Revised inventory');
      await tester.tap(_primary(Copy.save));
      await tester.pumpAndSettle();
      expect(
        tester.widget<AppTextField>(_field(Copy.projectName)).controller.text,
        'Revised inventory',
      );
      expect(projects.stored.single.name, 'Inventory');
      expect(find.text('The device is full.'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'relay keeps local counters visible without signed-in server actions',
    (WidgetTester tester) async {
      final FakeProjectRepository projects = (await _seededProjects());
      addTearDown(projects.dispose);
      await _pump(
        tester,
        const RelayRoute(projectId: 'project'),
        projects,
        scale: 2,
        overrides: <Override>[
          relaySnapshotProvider('project').overrideWith(
            (Ref _) async => const RelaySnapshot(
              queued: 2,
              sent: 3,
              purged: 1,
              hasKey: false,
              enabled: false,
              neverRelay: false,
              incoming: <String>[],
            ),
          ),
        ],
      );
      expect(find.text(Copy.relayQueued), findsOneWidget);
      expect(find.text(Copy.relaySent), findsOneWidget);
      expect(find.text(Copy.relayPurged), findsOneWidget);
      expect(_primary(Copy.relayAddKey), findsNothing);
      expect(_primary(Copy.relayQueueProject), findsNothing);
      expect(find.text(Copy.relaySync), findsNothing);
      expect(find.text(Copy.relaySignInNeeded), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'context overview keeps level names and values readable at large text',
    (WidgetTester tester) async {
      final FakeProjectRepository projects = (await _seededProjects());
      addTearDown(projects.dispose);
      const String label = 'District and facility location';
      const String value =
          'A long facility location description entered by the field worker';
      final SemanticsHandle semantics = tester.ensureSemantics();
      try {
        await _pump(
          tester,
          Builder(
            builder: (BuildContext context) => Scaffold(
              body: TextButton(
                onPressed: () => unawaited(
                  showContextValuesSheet(
                    context: context,
                    projectId: 'project',
                  ),
                ),
                child: const Text('Open context'),
              ),
            ),
          ),
          projects,
          scale: 2,
          overrides: <Override>[
            projectContextProvider('project').overrideWith(
              (Ref _) => Stream<ContextState>.value(
                const ContextState(
                  levels: <ContextLevel>[
                    ContextLevel(fieldKey: 'facility', order: 0, label: label),
                  ],
                  values: <String, String>{'facility': value},
                ),
              ),
            ),
            contextTemplatesProvider('project').overrideWith(
              (Ref _) => Stream<List<TemplateDef>>.value(const <TemplateDef>[]),
            ),
          ],
        );
        await tester.tap(find.text('Open context'));
        await tester.pumpAndSettle();
        expect(find.text(label), findsOneWidget);
        expect(find.text(value), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp(label)), findsWidgets);
        expect(tester.takeException(), isNull);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
      } finally {
        semantics.dispose();
      }
    },
  );
}

Future<FakeProjectRepository> _seededProjects() async {
  final FakeProjectRepository projects = FakeProjectRepository();
  await projects.create(aProject(id: 'project', name: 'Inventory'));
  return projects;
}

Finder _field(String label) => find.byWidgetPredicate(
  (Widget widget) => widget is AppTextField && widget.label == label,
);

Finder _primary(String label) => find.byWidgetPredicate(
  (Widget widget) => widget is AppPrimaryAction && widget.label == label,
);

Future<void> _pump(
  WidgetTester tester,
  Widget screen,
  FakeProjectRepository projects, {
  double scale = 1,
  List<Override> overrides = const <Override>[],
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final SettingsStore settings = SettingsStore.fake();
  if (projects.stored.isNotEmpty) {
    await settings.write(SettingKeys.openProjectId, projects.stored.first.id);
  }
  await pumpApp(
    tester,
    screen,
    useScreenFonts: true,
    overrides: <Override>[
      projectRepositoryProvider.overrideWithValue(projects),
      projectSettingsStoreProvider.overrideWithValue(settings),
      ...overrides,
    ],
  );
  await tester.pumpAndSettle();
}
