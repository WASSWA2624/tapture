import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/record_thumb.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/quality/quality.dart';
import 'package:tapture/features/records/records.dart' show RecordPhoto;

import '../../../support/fakes/fake_quality_repository.dart';
import '../../../support/screen_matrix.dart';
import '../../../support/screen_probe.dart';
import 'quality_routes.dart';

const Failure _failed = StorageFailure(
  message: 'The records could not be read.',
  recoveryAction: 'Try again.',
);

const String _compare = '/projects/project-1/duplicates/1';

const ValueKey<String> _override = ValueKey<String>(
  'duplicate-compare-override',
);

DuplicatePairView _pair() {
  return fakePair(
    '1',
    existing: 'Pump 12',
    incoming: 'Pump 12 (new)',
    differences: const <DuplicateDifference>[
      (fieldKey: 'serial', label: 'Serial', existing: 'A-1', incoming: 'A-2'),
      (
        fieldKey: 'condition',
        label: 'Condition',
        existing: 'Good',
        incoming: 'Faulty',
      ),
    ],
    incomingPhotos: const <RecordPhoto>[
      RecordPhoto(id: 'p1', sha256: 'sha-1', storagePath: 'photos/p1.jpg'),
      RecordPhoto(id: 'p2', sha256: 'sha-2', storagePath: 'photos/p2.jpg'),
    ],
  );
}

void main() {
  testWidgets(
    'the comparison puts both records side by side with their photos, photo '
    'counts and capture details, then only the fields that differ',
    (WidgetTester tester) async {
      final DuplicatePairView pair = _pair();
      await pumpQualityRoutes(
        tester,
        quality: FakeQualityRepository(pairs: <DuplicatePairView>[pair]),
        initial: _compare,
      );

      expect(find.text(Copy.duplicateCompareTitle), findsOneWidget);
      final Offset existing = tester.getTopLeft(
        find.byKey(const ValueKey<String>('duplicate-side-existing')),
      );
      final Offset incoming = tester.getTopLeft(
        find.byKey(const ValueKey<String>('duplicate-side-incoming')),
      );
      expect(existing.dy, incoming.dy);
      expect(existing.dx, lessThan(incoming.dx));
      expect(find.text('Pump 12'), findsOneWidget);
      expect(find.text('Pump 12 (new)'), findsOneWidget);
      expect(
        find.text(
          Copy.duplicateCaptureDetail(pair.existing.capturedAt, 'Ada', 'North'),
        ),
        findsOneWidget,
      );
      expect(find.text(Copy.photosCount(0)), findsOneWidget);
      expect(find.text(Copy.photosCount(2)), findsOneWidget);
      expect(find.byType(RecordThumb), findsNWidgets(2));
      expect(find.byType(AppListTile), findsNWidgets(2));
      expect(
        tester
            .widget<AppListTile>(
              find.byKey(const ValueKey<String>('duplicate-compare-serial')),
            )
            .subtitle,
        Copy.duplicateValueChange('A-1', 'A-2'),
      );
    },
  );

  testWidgets(
    'on a phone at twice the text size the comparison uses full-width sources and '
    'nothing overflows',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpQualityRoutes(
        tester,
        quality: FakeQualityRepository(pairs: <DuplicatePairView>[_pair()]),
        initial: _compare,
      );

      expect(tester.takeException(), isNull);
      final Rect existing = tester.getRect(
        find.byKey(const ValueKey<String>('duplicate-side-existing')),
      );
      final Rect incoming = tester.getRect(
        find.byKey(const ValueKey<String>('duplicate-side-incoming')),
      );
      expect(existing.left, incoming.left);
      expect(existing.width, incoming.width);
      expect(existing.bottom, lessThanOrEqualTo(incoming.top));
    },
  );

  for (final ScreenMatrix cell in ScreenMatrix.cells) {
    testWidgets(
      'comparison retains approval and readable sources ${cell.description}',
      (WidgetTester tester) async {
        final FakeQualityRepository quality = FakeQualityRepository(
          pairs: <DuplicatePairView>[_pair()],
        );
        await pumpQualityRoutes(
          tester,
          quality: quality,
          initial: _compare,
          cell: cell,
        );
        expect(quality.resolved, isEmpty);
        expect(ScreenProbe.layoutIssues(tester), isEmpty);
        final Finder action = find.byKey(_override);
        expect(
          await ScreenProbe.accessibilityIssues(
            tester,
            reachableTargets: <Finder>[action],
          ),
          isEmpty,
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey<String>('duplicate-compare-condition')),
        );
        await tester.pumpAndSettle();
        expect(ScreenProbe.layoutIssues(tester), isEmpty);
      },
    );
  }

  testWidgets('override is offered here and applies once confirmed', (
    WidgetTester tester,
  ) async {
    final FakeQualityRepository quality = FakeQualityRepository(
      pairs: <DuplicatePairView>[_pair()],
    );
    await pumpQualityRoutes(tester, quality: quality, initial: _compare);

    await tester.tap(find.byKey(_override));
    await tester.pumpAndSettle();
    expect(find.text(Copy.duplicateOverrideConfirmTitle), findsOneWidget);
    expect(quality.resolved, isEmpty);

    await tester.tap(find.widgetWithText(AppButton, Copy.duplicateOverride));
    await tester.pumpAndSettle();

    expect(quality.resolved, hasLength(1));
    expect(quality.resolved.single.$1, '1');
    expect(quality.resolved.single.$2.choice, DuplicateChoice.overrideExisting);
    expect(find.text(Copy.duplicatesTitle), findsOneWidget);
  });

  testWidgets('cancelling the override confirmation writes nothing', (
    WidgetTester tester,
  ) async {
    final FakeQualityRepository quality = FakeQualityRepository(
      pairs: <DuplicatePairView>[_pair()],
    );
    await pumpQualityRoutes(tester, quality: quality, initial: _compare);

    await tester.tap(find.byKey(_override));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, Copy.cancel));
    await tester.pumpAndSettle();

    expect(quality.resolved, isEmpty);
    expect(find.text(Copy.duplicateCompareTitle), findsOneWidget);
  });

  testWidgets(
    'a pair already resolved shows the empty state with the way back',
    (WidgetTester tester) async {
      await pumpQualityRoutes(
        tester,
        quality: FakeQualityRepository(),
        initial: _compare,
      );

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.byKey(_override), findsNothing);

      await tester.tap(
        find.widgetWithText(AppButton, Copy.duplicateBackToList),
      );
      await tester.pumpAndSettle();
      expect(find.text(Copy.duplicatesTitle), findsOneWidget);
    },
  );

  testWidgets('a failure shows the error state and retry reads again', (
    WidgetTester tester,
  ) async {
    final FakeQualityRepository quality = FakeQualityRepository(
      pairs: <DuplicatePairView>[_pair()],
      failure: _failed,
    );
    await pumpQualityRoutes(tester, quality: quality, initial: _compare);

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text(_failed.message), findsOneWidget);
    expect(find.byKey(_override), findsNothing);

    quality.failure = null;
    await tester.tap(find.widgetWithText(AppButton, Copy.tryAgain));
    await tester.pumpAndSettle();
    expect(find.text('Pump 12'), findsOneWidget);
    expect(find.byKey(_override), findsOneWidget);
  });
}
