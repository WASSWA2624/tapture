import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/records/domain/domain.dart';
import 'package:tapture/features/review/review.dart';
import 'package:tapture/features/settings/settings.dart' show SettingKeys;

import '../../../support/screen_fonts.dart';
import 'review_harness.dart';

const StorageFailure _unreadable = StorageFailure(
  message: 'Records could not be read.',
  recoveryAction: 'Try again.',
);

void main() {
  setUpAll(ScreenFonts.loadForApp);
  late ReviewHarness harness;

  setUp(() async {
    harness = ReviewHarness();
    await harness.seedTemplate();
  });

  /// A window tall enough to show the whole review without scrolling.
  void tall(WidgetTester tester) => sizeWindow(tester, const Size(800, 2400));

  Finder row(String key) => find.byKey(ValueKey<String>('review-field-$key'));

  testWidgets('filled two-sided review uses the selected reading layout', (
    WidgetTester tester,
  ) async {
    tall(tester);
    harness.seedRecord(photos: 1);
    await harness.pump(tester, ReviewHarness.recordReview('record-1'));
    expect(
      tester.widget<AppPage>(find.byType(AppPage)).layout,
      AppPageLayout.readingFirst,
    );
    final RawRefinedToggle choice = tester.widget<RawRefinedToggle>(
      find.descendant(
        of: row('rating'),
        matching: find.byType(RawRefinedToggle),
      ),
    );
    expect(choice.raw, 'two forty volts');
    expect(choice.refined, '240 V');
    expect(find.text('240 V'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('review-approve')),
      findsOneWidget,
    );
  });

  testWidgets('one-sided and missing reviews keep the sectioned layout', (
    WidgetTester tester,
  ) async {
    harness.seedRecord();
    final RecordEntry entry = harness.records.entryOf('record-1')!;
    harness.records.seedEntry(
      entry.copyWith(values: entry.values.take(2).toList()),
    );
    await harness.pump(tester, ReviewHarness.recordReview('record-1'));
    expect(
      tester.widget<AppPage>(find.byType(AppPage)).layout,
      AppPageLayout.sectioned,
    );
    await harness.pump(tester, ReviewHarness.recordReview('missing'));
    expect(
      tester.widget<AppPage>(find.byType(AppPage)).layout,
      AppPageLayout.sectioned,
    );
  });

  testWidgets(
    'the review shows labelled fields attention first at compact, medium and expanded widths',
    (WidgetTester tester) async {
      harness.seedRecord(photos: 1);
      for (final Size size in const <Size>[
        Size(400, 900),
        Size(800, 900),
        Size(1300, 900),
      ]) {
        sizeWindow(tester, size);
        await harness.pump(tester, ReviewHarness.recordReview('record-1'));

        expect(find.text(Copy.reviewNeedsAttention), findsOneWidget);
        expect(
          find.descendant(of: row('serial'), matching: find.text('Serial')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: row('serial'), matching: find.text('SN-1')),
          findsOneWidget,
        );
        expect(find.text('serial'), findsNothing, reason: 'labels, not keys');
        expect(
          find.descendant(
            of: row('note'),
            matching: find.text(Copy.reviewNotDetected),
          ),
          findsOneWidget,
        );
        expect(find.text(Copy.reviewConfidentGroup(1)), findsOneWidget);
        expect(
          find.byKey(const ValueKey<String>('review-confident-model')),
          findsNothing,
          reason: 'the confident group starts collapsed',
        );
        expect(
          find.byKey(const ValueKey<String>('review-approve')),
          findsOneWidget,
        );
        final bool expanded = size.width >= 1024;
        expect(
          find.byKey(const ValueKey<String>('review-evidence-pane')),
          expanded ? findsOneWidget : findsNothing,
        );
        expect(
          find.byKey(const ValueKey<String>('review-fields-pane')),
          expanded ? findsOneWidget : findsNothing,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('a record that is gone shows the empty state with a way back', (
    WidgetTester tester,
  ) async {
    await harness.pump(tester, ReviewHarness.recordReview('missing'));

    expect(find.byType(AppEmptyState), findsOneWidget);
    await tester.tap(find.text(Copy.reviewBackToRecords));
    await tester.pumpAndSettle();
    expect(find.text('records list'), findsOneWidget);
  });

  testWidgets('a record that cannot be read shows the failure with a retry', (
    WidgetTester tester,
  ) async {
    harness.seedRecord();
    harness.records.readFailure = _unreadable;
    await harness.pump(tester, ReviewHarness.recordReview('record-1'));

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text(_unreadable.message), findsOneWidget);
  });

  testWidgets(
    'the confident group opens and closes, and verifying it leaves every value unchanged',
    (WidgetTester tester) async {
      tall(tester);
      harness.seedRecord();
      await harness.pump(tester, ReviewHarness.recordReview('record-1'));

      await tester.tap(find.text(Copy.reviewConfidentGroup(1)));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('review-confident-model')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('review-verify-confident')),
      );
      await tester.pumpAndSettle();

      final RecordValue model = harness.records
          .entryOf('record-1')!
          .valueOf('model')!;
      expect(model.verified, isTrue);
      expect(model.display, 'CR-10');
      expect(find.text(Copy.reviewVerifiedCount(1)), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('review-confident-model')),
          // A tight slot may show the mark's icon alone; its label names
          // the verifier either way.
          matching: _verifiedBy('Test operator'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('review-verify-confident')),
        findsNothing,
        reason: 'nothing confident is left to verify',
      );

      await tester.tap(find.text(Copy.reviewConfidentGroup(1)));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('review-confident-model')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'verifying one field records who verified it without changing it',
    (WidgetTester tester) async {
      tall(tester);
      harness.seedRecord();
      await harness.pump(tester, ReviewHarness.recordReview('record-1'));

      await tester.tap(
        find.descendant(
          of: row('serial'),
          matching: find.byKey(const ValueKey<String>('review-verify')),
        ),
      );
      await tester.pumpAndSettle();

      final RecordValue serial = harness.records
          .entryOf('record-1')!
          .valueOf('serial')!;
      expect(serial.verified, isTrue);
      expect(serial.display, 'SN-1');
      expect(
        row('serial'),
        findsNothing,
        reason: 'a verified value is settled',
      );
      await tester.tap(find.text(Copy.reviewConfidentGroup(2)));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('review-confident-serial')),
          // A tight slot may show the mark's icon alone; its label names
          // the verifier either way.
          matching: _verifiedBy('Test operator'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'choosing the captured side changes only the final value, reverses, and the next field starts there',
    (WidgetTester tester) async {
      tall(tester);
      harness.seedRecord();
      await harness.pump(tester, ReviewHarness.recordReview('record-1'));
      expect(
        find.descendant(of: row('voltage'), matching: find.text('400')),
        findsOneWidget,
        reason: 'the refined side is the default start',
      );

      await tester.ensureVisible(find.text(Copy.reviewUseRaw).first);
      await tester.tap(find.text(Copy.reviewUseRaw).first);
      await tester.pumpAndSettle();

      RecordValue rating = harness.records
          .entryOf('record-1')!
          .valueOf('rating')!;
      expect(rating.approved, 'two forty volts');
      expect(rating.raw, 'two forty volts');
      expect(rating.refined, '240 V');
      expect(harness.settings.read(SettingKeys.reviewValueSide), 'raw');
      expect(
        find.descendant(
          of: row('voltage'),
          matching: find.text('four hundred'),
        ),
        findsOneWidget,
        reason: 'a later field starts on the remembered side',
      );

      await tester.tap(find.text(Copy.reviewUseRefined).first);
      await tester.pumpAndSettle();
      rating = harness.records.entryOf('record-1')!.valueOf('rating')!;
      expect(rating.approved, '240 V');
      expect(rating.raw, 'two forty volts');
    },
  );

  testWidgets('a not-detected field offers typing and photographing in place', (
    WidgetTester tester,
  ) async {
    tall(tester);
    harness.seedRecord();
    await harness.pump(tester, ReviewHarness.recordReview('record-1'));

    expect(
      find.byKey(const ValueKey<String>('review-type-it')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey<String>('review-photograph')));
    await tester.pumpAndSettle();
    expect(find.text('capture for the record'), findsOneWidget);
  });

  testWidgets(
    'a value with evidence is checkable in two taps, with its region on the photo',
    (WidgetTester tester) async {
      tall(tester);
      harness.seedRecord(photos: 1);
      harness.review.evidence['model'] = <ValueEvidence>[
        (
          kind: EvidenceKind.photo,
          photoId: 'record-1-photo-0',
          page: null,
          regionJson: '{"left":100,"top":200,"right":300,"bottom":260}',
          snippet: 'CR-10',
          photoWidth: 1000,
          photoHeight: 1000,
        ),
      ];
      await harness.pump(tester, ReviewHarness.recordReview('record-1'));

      await tester.tap(find.text(Copy.reviewConfidentGroup(1)));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey<String>('review-confident-model')),
          matching: find.byKey(const ValueKey<String>('review-show-evidence')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EvidenceViewer), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('evidence-photo')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('evidence-region')),
        findsOneWidget,
      );
      expect(find.text(Copy.reviewEvidencePhoto), findsOneWidget);
    },
  );

  testWidgets(
    'approval is blocked by an unresolved conflict and the block names the field',
    (WidgetTester tester) async {
      tall(tester);
      harness.seedRecord(flags: const <RecordFlag>{RecordFlag.hasConflict});
      harness.review.conflicts.add('serial');
      await harness.pump(tester, ReviewHarness.recordReview('record-1'));

      await tester.tap(find.byKey(const ValueKey<String>('review-approve')));
      await tester.pumpAndSettle();

      expect(find.text(Copy.conflictBlocksApproval('Serial')), findsOneWidget);
      expect(
        harness.records.entryOf('record-1')!.status,
        RecordStatus.needsReview,
      );
    },
  );

  testWidgets(
    'approving moves straight to the next record waiting, then back to the list',
    (WidgetTester tester) async {
      tall(tester);
      harness.seedRecord(id: 'record-1', capturedAt: DateTime.utc(2026, 9, 2));
      harness.seedRecord(id: 'record-2', capturedAt: DateTime.utc(2026, 9, 1));
      final GoRouter router = await harness.pump(
        tester,
        ReviewHarness.recordReview('record-1'),
      );

      await tester.tap(find.byKey(const ValueKey<String>('review-approve')));
      await tester.pumpAndSettle();
      expect(
        harness.records.entryOf('record-1')!.status,
        RecordStatus.approved,
      );
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        ReviewHarness.recordReview('record-2'),
      );
      expect(find.text('Pump record-2'), findsOneWidget);
      // The approval snack sits over the footer; clear it before the next tap.
      ScaffoldMessenger.of(
        tester.element(find.byType(ReviewScreen)),
      ).removeCurrentSnackBar();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('review-approve')));
      await tester.pumpAndSettle();
      expect(
        harness.records.entryOf('record-2')!.status,
        RecordStatus.approved,
      );
      expect(find.text('records list'), findsOneWidget);
    },
  );
}

/// The verified mark naming [verifier], whether its word or only its icon
/// shows.
Finder _verifiedBy(String verifier) => find.byWidgetPredicate(
  (Widget widget) =>
      widget is AppStatusPill &&
      widget.label == Copy.reviewVerifiedBy(verifier),
);
