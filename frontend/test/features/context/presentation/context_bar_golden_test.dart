import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/context/context.dart';
import 'package:tapture/features/context/presentation/context_bar.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/domain/setting_keys.dart';
import 'package:tapture/features/settings/settings.dart' show SettingsStore;

import '../../../support/factories.dart';
import '../../../support/fakes/fake_context_repository.dart';
import '../../projects/fakes/fake_project_repository.dart';

void main() {
  testWidgets('context bar at three widths and at 200 percent text', (
    WidgetTester tester,
  ) async {
    final List<String> failures = <String>[];
    final FakeContextRepository repo = FakeContextRepository();
    final FakeProjectRepository projects = FakeProjectRepository();
    addTearDown(repo.dispose);
    addTearDown(projects.dispose);
    _ok(await projects.create(aProject(id: 'p1', name: 'Inventory')));
    await repo.saveHierarchy('p1', const <ContextLevel>[
      ContextLevel(fieldKey: 'district', order: 0, label: 'District'),
      ContextLevel(fieldKey: 'facility', order: 1, label: 'Facility'),
      ContextLevel(fieldKey: 'dept', order: 2, label: 'Department'),
    ]);
    await repo.setLevelValue(
      projectId: 'p1',
      fieldKey: 'district',
      value: 'Kampala',
    );
    await repo.setLevelValue(
      projectId: 'p1',
      fieldKey: 'facility',
      value: 'Kasubi Health Centre IV Outpatient Wing',
    );
    await repo.setLevelValue(
      projectId: 'p1',
      fieldKey: 'dept',
      value: 'Theatre',
    );
    await repo.savePinned('p1', const <String, String>{'surveyor': 'Sam'});

    const List<({double width, double scale, String name})> cases =
        <({double width, double scale, String name})>[
          (width: 320, scale: 1, name: 'context_bar_320'),
          (width: 600, scale: 1, name: 'context_bar_600'),
          (width: 1024, scale: 1, name: 'context_bar_1024'),
          (width: 320, scale: 2, name: 'context_bar_320_text2'),
        ];
    for (final ({double width, double scale, String name}) item in cases) {
      await _pump(
        tester,
        repo: repo,
        projects: projects,
        width: item.width,
        scale: item.scale,
      );
      try {
        await expectLater(
          find.byType(ContextBar),
          matchesGoldenFile('goldens/${item.name}.png'),
        );
      } catch (error) {
        failures.add('${item.name}: $error');
      }
    }
    if (failures.isNotEmpty) {
      fail('golden moved:\n${failures.join('\n')}');
    }
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required FakeContextRepository repo,
  required FakeProjectRepository projects,
  required double width,
  required double scale,
}) async {
  debugDisableShadows = true;
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 240);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(() {
    debugDisableShadows = false;
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: <Override>[
        contextRepositoryProvider.overrideWith((Ref _) => repo),
        projectRepositoryProvider.overrideWith((Ref _) => projects),
        projectSettingsStoreProvider.overrideWith(
          (Ref _) => SettingsStore.fake(
            stored: <String, Object?>{SettingKeys.openProjectId.name: 'p1'},
          ),
        ),
      ],
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: const Scaffold(body: Align(child: ContextBar())),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
