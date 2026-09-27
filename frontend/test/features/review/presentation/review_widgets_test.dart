import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/processing/processing.dart'
    show ConfidenceBand;
import 'package:tapture/features/records/domain/record_photo.dart';
import 'package:tapture/features/review/review.dart';

import '../../../support/factories.dart';

const Failure _failed = StorageFailure(
  message: 'Review could not be read.',
  recoveryAction: 'Try again.',
);

void main() {
  testWidgets(
    'review at compact, medium and expanded, plus empty and failure',
    (WidgetTester tester) async {
      final record = aRecordEntry(
        name: 'Pump',
        fields: const <String, String>{'serial': ''},
      );
      for (final Size size in const <Size>[
        Size(400, 800),
        Size(800, 800),
        Size(1200, 800),
      ]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        await _pump(
          tester,
          ReviewScreen(record: record, template: aTemplate()),
        );
        expect(
          find.byKey(const ValueKey<String>('review-approve')),
          findsOneWidget,
        );
        expect(find.text('serial'), findsOneWidget);
        expect(
          find.byKey(const ValueKey<String>('review-confident-serial')),
          findsNothing,
        );
        if (size.width >= 1200) {
          expect(
            find.byKey(const ValueKey<String>('review-evidence-pane')),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey<String>('review-fields-pane')),
            findsOneWidget,
          );
        }
      }
      addTearDown(tester.view.resetPhysicalSize);
      await _pump(tester, const ReviewScreen());
      expect(find.byType(AppEmptyState), findsOneWidget);
      await _pump(tester, const ReviewScreen(failure: _failed));
      expect(find.byType(AppErrorState), findsOneWidget);
    },
  );

  testWidgets('raw or refined changes only the final side and is remembered', (
    WidgetTester tester,
  ) async {
    ValueSide side = ValueSide.refined;
    await _pump(
      tester,
      RawRefinedToggle(
        side: side,
        raw: 'captured',
        refined: 'refined',
        onChanged: (ValueSide next) => side = next,
      ),
    );
    expect(find.text('refined'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('review-use-raw')));
    await tester.pump();
    expect(side, ValueSide.raw);

    await _pump(
      tester,
      RawRefinedToggle(side: side, raw: 'captured', refined: 'refined'),
    );
    expect(find.text('captured'), findsOneWidget);

    await _pump(tester, const RawRefinedToggle(side: ValueSide.raw));
    expect(find.byType(AppEmptyState), findsOneWidget);
    await _pump(
      tester,
      const RawRefinedToggle(side: ValueSide.raw, failure: _failed),
    );
    expect(find.byType(AppErrorState), findsOneWidget);
  });

  testWidgets('each confidence band shows an icon and a number', (
    WidgetTester tester,
  ) async {
    for (final ConfidenceBand band in ConfidenceBand.values) {
      await _pump(tester, ConfidenceIndicator(band: band, score: 0.92));
      expect(find.byType(Icon), findsWidgets);
      expect(find.textContaining('92%'), findsOneWidget);
    }
    await _pump(tester, const ConfidenceIndicator());
    expect(find.byType(AppEmptyState), findsOneWidget);
    await _pump(tester, const ConfidenceIndicator(failure: _failed));
    expect(find.byType(AppErrorState), findsOneWidget);
  });

  testWidgets('a not-detected field offers typing and photographing', (
    WidgetTester tester,
  ) async {
    var typed = false;
    var photographed = false;
    await _pump(
      tester,
      NotDetectedRow(
        label: 'Serial',
        onType: () => typed = true,
        onPhotograph: () => photographed = true,
      ),
    );
    expect(find.textContaining('Serial'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('review-type-it')));
    await tester.tap(find.byKey(const ValueKey<String>('review-photograph')));
    expect(typed, isTrue);
    expect(photographed, isTrue);
    await _pump(tester, const NotDetectedRow());
    expect(find.byType(AppEmptyState), findsOneWidget);
    await _pump(tester, const NotDetectedRow(failure: _failed));
    expect(find.byType(AppErrorState), findsOneWidget);
  });

  testWidgets('evidence shows a region, a whole photo, or a transcript', (
    WidgetTester tester,
  ) async {
    const RecordPhoto photo = RecordPhoto(
      id: 'p1',
      sha256: 'abc',
      storagePath: 'photos/p1.jpg',
    );
    await _pump(
      tester,
      const EvidenceViewer(
        photo: photo,
        sourceLabel: 'Read from photo',
        regionJson: '{"x":0.1,"y":0.2,"width":0.3,"height":0.2}',
      ),
    );
    expect(
      find.byKey(const ValueKey<String>('evidence-region')),
      findsOneWidget,
    );
    expect(find.text('Read from photo'), findsOneWidget);

    await _pump(
      tester,
      const EvidenceViewer(photo: photo, sourceLabel: 'Photo'),
    );
    expect(
      find.byKey(const ValueKey<String>('evidence-photo')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('evidence-region')), findsNothing);

    await _pump(
      tester,
      const EvidenceViewer(snippet: 'spoken serial', sourceLabel: 'Transcript'),
    );
    expect(find.text('spoken serial'), findsOneWidget);

    await _pump(tester, const EvidenceViewer());
    expect(find.byType(AppEmptyState), findsOneWidget);
    await _pump(tester, const EvidenceViewer(failure: _failed));
    expect(find.byType(AppErrorState), findsOneWidget);
  });

  testWidgets('verify records the person and can cover confident fields', (
    WidgetTester tester,
  ) async {
    var single = false;
    var bulk = false;
    await _pump(
      tester,
      VerifyAction(
        fieldLabel: 'Serial',
        verifier: 'Ann',
        confidentCount: 2,
        onVerify: () => single = true,
        onVerifyConfident: () => bulk = true,
      ),
    );
    expect(find.text(Copy.reviewVerifiedBy('Ann')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('review-verify')));
    await tester.tap(
      find.byKey(const ValueKey<String>('review-verify-confident')),
    );
    expect(single, isTrue);
    expect(bulk, isTrue);
    await _pump(tester, const VerifyAction());
    expect(find.byType(AppEmptyState), findsOneWidget);
    await _pump(tester, const VerifyAction(failure: _failed));
    expect(find.byType(AppErrorState), findsOneWidget);
  });

  testWidgets('batch skip and back keep the typed draft', (
    WidgetTester tester,
  ) async {
    final Map<String, String> drafts = <String, String>{};
    var index = 0;
    Future<void> show() {
      return _pump(
        tester,
        BatchReviewScreen(
          recordIds: const <String>['r1', 'r2'],
          index: index,
          drafts: drafts,
          onDraft: (String text) => drafts[index == 0 ? 'r1' : 'r2'] = text,
          onSkip: () => index += 1,
          onBack: () => index -= 1,
        ),
      );
    }

    await show();
    await tester.enterText(find.byType(EditableText), 'half');
    expect(drafts['r1'], 'half');
    index = 1;
    await show();
    expect(find.text('r2'), findsOneWidget);
    index = 0;
    await show();
    expect(find.text('half'), findsOneWidget);

    index = 2;
    await show();
    expect(find.text(Copy.reviewQueueDone), findsOneWidget);
    await _pump(
      tester,
      const BatchReviewScreen(
        recordIds: <String>[],
        index: 0,
        drafts: <String, String>{},
      ),
    );
    expect(find.byType(AppEmptyState), findsOneWidget);
    await _pump(
      tester,
      const BatchReviewScreen(
        recordIds: <String>['r1'],
        index: 0,
        drafts: <String, String>{},
        failure: _failed,
      ),
    );
    expect(find.byType(AppErrorState), findsOneWidget);
  });

  testWidgets(
    're-analysis offers a verified field and writes only what was accepted',
    (WidgetTester tester) async {
      Map<String, String>? written;
      var declined = false;
      const List<ReanalyseProposal> proposals = <ReanalyseProposal>[
        (
          fieldKey: 'serial',
          label: 'Serial',
          current: 'A-1',
          proposed: 'A-2',
          offeredOnly: true,
        ),
        (
          fieldKey: 'note',
          label: 'Note',
          current: 'old',
          proposed: 'new',
          offeredOnly: false,
        ),
      ];
      await _pump(
        tester,
        ReanalyseAction(
          proposals: proposals,
          onApply: (Map<String, String> accepted) => written = accepted,
          onDeclineAll: () => declined = true,
        ),
      );
      expect(find.textContaining(Copy.reviewOfferedNotApplied), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('reanalyse-apply')));
      expect(written, isEmpty);

      await tester.tap(find.text('Note'));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey<String>('reanalyse-apply')));
      expect(written, <String, String>{'note': 'new'});
      expect(written!.containsKey('serial'), isFalse);

      await tester.tap(find.byKey(const ValueKey<String>('reanalyse-decline')));
      expect(declined, isTrue);

      await _pump(
        tester,
        const ReanalyseAction(proposals: <ReanalyseProposal>[]),
      );
      expect(find.byType(AppEmptyState), findsOneWidget);
      await _pump(
        tester,
        const ReanalyseAction(
          proposals: <ReanalyseProposal>[],
          failure: _failed,
        ),
      );
      expect(find.byType(AppErrorState), findsOneWidget);
    },
  );
}

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: Scaffold(body: SizedBox(width: 800, height: 1200, child: child)),
      ),
    ),
  );
}
