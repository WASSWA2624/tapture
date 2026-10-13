import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/import/import.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_section.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/import/presentation/import_providers.dart';
import 'package:tapture/features/import/presentation/record_mapping_screen.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/data/settings_store.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';
import '../../../support/pump_app.dart';
import '../../../support/screen_matrix.dart';
import '../../../support/screen_probe.dart';

import '../../projects/fakes/fake_project_repository.dart';

void main() {
  for (final ScreenMatrix cell in ScreenMatrix.cells) {
    testWidgets(
      'mapping keeps editable columns and three preview rows ${cell.description}',
      (WidgetTester tester) async {
        tester.view.physicalSize = cell.size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = cell.textScale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final TemplateDef template = aTemplate(
          projectId: 'p1',
          fields: const <FieldDef>[
            FieldDef(fieldKey: 'serial', label: 'Serial', type: FieldType.text),
          ],
        );
        await pumpApp(
          tester,
          const RecordMappingScreen(),
          brightness: cell.brightness,
          outdoor: cell.outdoor,
          overrides: [
            currentProjectProvider.overrideWithBuild((_, _) => 'p1'),
            importSheetProvider.overrideWith((Ref _) async => _sheet),
            importTemplatesProvider('p1').overrideWith(
              (Ref _) =>
                  Stream<List<TemplateDef>>.value(<TemplateDef>[template]),
            ),
          ],
        );
        await tester.pumpAndSettle();
        expect(
          tester.widget<AppPage>(find.byType(AppPage)).layout,
          AppPageLayout.compact,
        );
        expect(find.byType(AppSection), findsNWidgets(2));
        expect(
          find.byKey(const ValueKey<String>('import-map-Serial')),
          findsOneWidget,
        );
        expect(find.text(Copy.importRun(3)), findsOneWidget);
        final Finder submit = find.byType(AppPrimaryAction);
        expect(
          await ScreenProbe.accessibilityIssues(
            tester,
            reachableTargets: <Finder>[submit],
          ),
          isEmpty,
        );
        final Finder third = find.byKey(
          const ValueKey<String>('import-preview-4'),
        );
        await tester.ensureVisible(third);
        await tester.pumpAndSettle();
        expect(ScreenProbe.layoutIssues(tester), isEmpty);
        expect(find.text('A-3'), findsOneWidget);
      },
    );
  }
  testWidgets('no held sheet is the empty state', (WidgetTester tester) async {
    final FakeProjectRepository projects = FakeProjectRepository();
    addTearDown(projects.dispose);
    await tester.pumpWidget(
      ProviderScope(
        retry: (int _, Object _) => null,
        overrides: <Override>[
          projectRepositoryProvider.overrideWith((Ref _) => projects),
          projectSettingsStoreProvider.overrideWith(
            (Ref _) => SettingsStore.fake(),
          ),
        ],
        child: MaterialApp(
          theme: buildTheme(brightness: Brightness.light),
          home: const RecordMappingScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(AppEmptyState), findsOneWidget);
  });
}

const WorkbookSheet _sheet = (
  name: 'Equipment',
  rowCount: 4,
  columnCount: 1,
  usedRange: 'A1:A4',
  mergedCells: <String>[],
  rows: <List<String>>[
    <String>['Serial'],
    <String>['A-1'],
    <String>['A-2'],
    <String>['A-3'],
  ],
  header: (rowNumber: 1, labels: <String>['Serial'], isSuggestion: true),
  columns: <ColumnSuggestion>[],
);
