import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_page_layout_scope.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/features/quality/quality.dart';
import 'package:tapture/features/records/records.dart' show RecordPhoto;

import '../../../support/fakes/fake_quality_repository.dart';
import '../../../support/pump_app.dart';
import '../../../support/screen_matrix.dart';
import '../../../support/screen_probe.dart';

void main() {
  for (final ScreenMatrix cell in ScreenMatrix.cells) {
    testWidgets(
      'reading first merge needs a human field pick ${cell.description}',
      (WidgetTester tester) async {
        tester.view.physicalSize = cell.size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = cell.textScale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final FakeQualityRepository repository = FakeQualityRepository(
          pairs: <DuplicatePairView>[
            fakePair(
              'pair-1',
              incomingPhotos: const <RecordPhoto>[
                RecordPhoto(
                  id: 'photo-1',
                  sha256: 'sha-1',
                  storagePath: 'photos/1.jpg',
                ),
              ],
            ),
          ],
        );
        DuplicateResolution? resolution;
        await pumpApp(
          tester,
          Builder(
            builder: (BuildContext context) => AppPage(
              title: Copy.qualitySummaryTitle,
              body: const SizedBox.shrink(),
              footer: AppButton(
                label: Copy.duplicateMerge,
                onPressed: () => unawaited(() async {
                  resolution = await showDuplicateMergeSheet(context, 'pair-1');
                }()),
              ),
            ),
          ),
          brightness: cell.brightness,
          outdoor: cell.outdoor,
          overrides: [qualityRepositoryProvider.overrideWithValue(repository)],
        );
        await tester.tap(find.text(Copy.duplicateMerge));
        await tester.pumpAndSettle();
        expect(
          AppPageLayoutScope.of(
            tester.element(find.byType(DuplicateMergeSheet)),
          ),
          AppPageLayout.readingFirst,
        );
        final Finder apply = find.byKey(const ValueKey<String>('merge-apply'));
        expect(tester.widget<AppPrimaryAction>(apply).onPressed, isNull);
        final Finder choice = find.descendant(
          of: find.byKey(const ValueKey<String>('merge-pick-serial')),
          matching: find.text(Copy.duplicateMergeExisting),
        );
        await tester.ensureVisible(choice);
        await tester.tap(choice);
        await tester.pumpAndSettle();
        expect(tester.widget<AppPrimaryAction>(apply).onPressed, isNotNull);
        await tester.ensureVisible(apply);
        await tester.pumpAndSettle();
        expect(
          await ScreenProbe.accessibilityIssues(
            tester,
            reachableTargets: <Finder>[apply],
          ),
          isEmpty,
        );
        await tester.tap(apply);
        await tester.pumpAndSettle();
        expect(resolution?.picks, <String, MergePick>{
          'serial': MergePick.theirs,
        });
        expect(
          repository.resolved,
          isEmpty,
          reason: 'the sheet only proposes a decision',
        );
      },
    );
  }
}
