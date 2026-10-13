import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_section.dart';
import 'package:tapture/features/merge/domain/domain.dart';
import 'package:tapture/features/merge/merge.dart';
import 'package:tapture/features/merge/presentation/merge_controller.dart';
import 'package:tapture/features/merge/presentation/merge_view.dart';

import '../../../support/fakes/fake_package_import_repository.dart';
import '../../../support/pump_app.dart';
import '../../../support/screen_matrix.dart';
import '../../../support/screen_probe.dart';

const FieldConflict _conflict = FieldConflict(
  kind: ConflictKind.value,
  table: 'record_fields',
  rowId: 'value-1',
  recordId: 'r1',
  fieldKey: 'serial',
  fieldLabel: 'Serial number from the equipment register',
  recordLabel: 'Field equipment for the northern inspection team',
  mine: 'This device value retained from the original capture',
  theirs: 'Incoming value proposed by the other field team',
  mineDevice: 'Field device one',
  theirsDevice: 'Field device two',
  mineAt: 100,
  theirsAt: 200,
);

MergeView _view() => MergeView(
  bundle: openedPackage(<String, List<Map<String, Object?>>>{
    'records': <Map<String, Object?>>[
      <String, Object?>{'id': 'new-record', 'number': 2},
    ],
    'captions': <Map<String, Object?>>[
      <String, Object?>{
        'owner_type': 'record',
        'owner_id': 'new-record',
        'text_raw': 'New incoming pump',
      },
    ],
  }),
  report: const CompatibilityReport(<TemplateMatch>[
    TemplateMatch(
      incomingId: 't1',
      localId: 't1',
      name: 'Inspection fields',
      templateKey: 'inspection',
      issues: <({CompatibilityIssue issue, String field})>[],
    ),
  ]),
  plan: const MergePlan(
    inserts: <String, List<Map<String, Object?>>>{},
    files: <({String entry, String target})>[],
    settled: [],
    conflicts: <FieldConflict>[_conflict],
    counts: (
      newRecords: 1,
      updatedRecords: 0,
      newPhotos: 0,
      photosHere: 0,
      deletions: 0,
      kept: 0,
      elsewhere: 0,
    ),
    insertedRecords: <String>['new-record'],
  ),
  local: const <String, List<Map<String, Object?>>>{},
);

void main() {
  for (final ScreenMatrix cell in ScreenMatrix.cells) {
    for (final bool preview in <bool>[true, false]) {
      testWidgets(
        'compact ${preview ? 'merge' : 'conflict'} ${cell.description}',
        (WidgetTester tester) async {
          tester.view.physicalSize = cell.size;
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = cell.textScale;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final FakePackageImportRepository repository =
              FakePackageImportRepository();
          final MergeView initial = _view();
          await pumpApp(
            tester,
            preview
                ? const MergePreviewScreen(projectId: 'p1')
                : const ConflictScreen(projectId: 'p1'),
            brightness: cell.brightness,
            outdoor: cell.outdoor,
            overrides: [
              packageImportRepositoryProvider.overrideWithValue(repository),
              mergeControllerProvider(
                'p1',
              ).overrideWithBuild((_, _) => initial),
            ],
          );
          await tester.pumpAndSettle();
          expect(repository.merges, isEmpty);
          final AppPage page = tester.widget<AppPage>(find.byType(AppPage));
          expect(page.layout, AppPageLayout.compact);
          expect(ScreenProbe.layoutIssues(tester), isEmpty);
          if (preview) {
            expect(find.byType(AppSection), findsNWidgets(2));
            expect(find.text('New incoming pump'), findsNothing);
            final Finder section = find.byKey(
              const ValueKey<String>('merge-count-newRecords'),
            );
            await tester.ensureVisible(section);
            await tester.tap(section);
            await tester.pumpAndSettle();
            expect(find.text('New incoming pump'), findsOneWidget);
            expect(find.text(Copy.mergeSettleConflicts(1)), findsOneWidget);
            expect(
              await ScreenProbe.accessibilityIssues(
                tester,
                reachableTargets: <Finder>[
                  find.byKey(MergePreviewScreen.applyKey),
                ],
              ),
              isEmpty,
            );
          } else {
            final Finder keep = find.byKey(ConflictScreen.keepMineKey);
            await tester.ensureVisible(keep);
            await tester.pumpAndSettle();
            expect(
              await ScreenProbe.accessibilityIssues(
                tester,
                reachableTargets: <Finder>[keep],
              ),
              isEmpty,
            );
            expect(find.byKey(ConflictScreen.keepBothKey), findsNothing);
            expect(find.byKey(ConflictScreen.typeValueKey), findsOneWidget);
          }
          expect(ScreenProbe.layoutIssues(tester), isEmpty);
          expect(repository.merges, isEmpty);
        },
      );
    }
  }
}
