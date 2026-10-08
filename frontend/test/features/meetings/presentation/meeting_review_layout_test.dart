import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/copy/l10n/app_localizations.g.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/responsive/breakpoints.dart';
import 'package:tapture/features/meetings/domain/action_entry.dart';
import 'package:tapture/features/meetings/domain/attendee.dart';
import 'package:tapture/features/meetings/domain/decision.dart';
import 'package:tapture/features/meetings/domain/meeting.dart';
import 'package:tapture/features/meetings/presentation/meeting_review_screen.dart';

import '../../../support/screen_fonts.dart';
import '../../../support/screen_matrix.dart';

void main() {
  for (final ScreenMatrix cell in ScreenMatrix.cells) {
    testWidgets('review labels and multiline edits remain reachable at '
        '${cell.description}', (WidgetTester tester) async {
      int approvals = 0;
      await _pump(tester, cell, onApprove: () => approvals++);
      await _expectLayout(tester, cell);
      await tester.tap(_approve);
      await tester.pumpAndSettle();
      expect(approvals, 1);
    }, variant: TargetPlatformVariant.all());
  }

  for (final ScreenMatrix cell in ScreenMatrix.cells.where(
    (ScreenMatrix cell) => cell.size.width == 393 && cell.textScale == 2,
  )) {
    testWidgets('pseudo-locale review stays usable at ${cell.description}', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      try {
        await _pump(tester, cell, locale: const Locale('en', 'XA'));
        final LocalizedCopy localCopy = Copy.of(
          tester.element(find.byType(MeetingReviewScreen)),
        );
        expect(localCopy.meetingSummary, isNot(Copy.meetingSummary));
        final Finder summary = find.widgetWithText(
          AppSectionHeader,
          localCopy.meetingSummary,
        );
        expect(tester.getSemantics(summary).flagsCollection.isHeader, isTrue);
        await _expectLayout(tester, cell);
        expect(
          tester
              .widget<TextField>(_field('meeting-notes'))
              .decoration!
              .labelText,
          localCopy.meetingNotes,
        );
        expect(
          tester
              .widget<TextField>(_field('meeting-minutes'))
              .decoration!
              .labelText,
          localCopy.meetingMinutes,
        );
      } finally {
        semantics.dispose();
      }
    });
  }

  for (final (String, Brightness, bool) mode in <(String, Brightness, bool)>[
    ('light', Brightness.light, false),
    ('dark', Brightness.dark, false),
    ('outdoor', Brightness.light, true),
  ]) {
    for (final ({String name, Size size, double scale}) corner
        in <({String name, Size size, double scale})>[
          (name: 'compact', size: const Size(393, 852), scale: 1),
          (name: 'compact_text2', size: const Size(393, 852), scale: 2),
          (
            name: 'compact_landscape_text2',
            size: const Size(393, 320),
            scale: 2,
          ),
          (name: 'medium', size: const Size(800, 1280), scale: 1),
          (name: 'expanded', size: const Size(1200, 800), scale: 1),
          (name: 'expanded_text2', size: const Size(1200, 800), scale: 2),
        ]) {
      testWidgets('review golden ${corner.name} ${mode.$1}', (
        WidgetTester tester,
      ) async {
        await _pump(
          tester,
          ScreenMatrix(corner.size, corner.scale, mode.$2, mode.$3),
        );
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/meeting_review_${corner.name}_${mode.$1}.png',
          ),
        );
      }, skip: kIsWeb);
    }
  }
}

final Finder _approve = find.byKey(const ValueKey<String>('meeting-approve'));

Finder _field(String key) => find.descendant(
  of: find.byKey(ValueKey<String>(key)),
  matching: find.byType(TextField),
);

Future<void> _expectLayout(WidgetTester tester, ScreenMatrix cell) async {
  final LocalizedCopy localCopy = Copy.of(
    tester.element(find.byType(MeetingReviewScreen)),
  );
  expect(find.text(localCopy.meetingAttendanceCount(2)), findsOneWidget);
  expect(find.text(localCopy.meetingDecisionsCount(1)), findsOneWidget);
  expect(find.text(localCopy.meetingActionsCount(1)), findsOneWidget);
  expect(find.text(_transcript), findsOneWidget);
  expect(tester.takeException(), isNull);
  final Finder notes = _field('meeting-notes');
  final Finder minutes = _field('meeting-minutes');
  if (SizeClass.fromWidth(cell.size.width) == SizeClass.expanded) {
    expect(tester.getTopLeft(notes).dy, tester.getTopLeft(minutes).dy);
    expect(
      tester.getTopLeft(minutes).dx,
      greaterThan(tester.getTopRight(notes).dx),
    );
  } else {
    expect(
      tester.getTopLeft(minutes).dy,
      greaterThan(tester.getBottomLeft(notes).dy),
    );
  }
  for (final Finder field in <Finder>[notes, minutes]) {
    final TextField widget = tester.widget<TextField>(field);
    expect(widget.minLines, greaterThanOrEqualTo(4));
    expect(widget.maxLines, isNull);
    expect(widget.keyboardType, TextInputType.multiline);
    await Scrollable.ensureVisible(tester.element(field), alignment: 1);
    await tester.pumpAndSettle();
    final RenderEditable editable = tester
        .state<EditableTextState>(
          find.descendant(of: field, matching: find.byType(EditableText)),
        )
        .renderEditable;
    final Rect caret = editable
        .getLocalRectForCaret(
          TextPosition(offset: widget.controller!.text.length),
        )
        .shift(editable.localToGlobal(Offset.zero));
    final Rect body = tester.getRect(find.byType(SingleChildScrollView).first);
    expect(caret.top, greaterThanOrEqualTo(body.top - 1));
    expect(caret.bottom, lessThanOrEqualTo(body.bottom + 1));
    expect(tester.takeException(), isNull);
  }
  expect(
    tester.getSize(_approve).height,
    greaterThanOrEqualTo(Sizes.minTapTarget),
  );
  expect(_approve.hitTestable(), findsOneWidget);
}

const String _notes =
    'Opening remarks\nSite observations\nFollow-up points\nNotes end';
const String _minutes =
    'Plan adopted\nOwner confirmed\nFollow-up agreed\nMinutes end';
const String _transcript = 'The team agreed to review the site observations.';

Future<void> _pump(
  WidgetTester tester,
  ScreenMatrix cell, {
  Locale locale = const Locale('en'),
  VoidCallback? onApprove,
}) async {
  await tester.runAsync(ScreenFonts.load);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = cell.size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: ScreenFonts.theme(
          cell.outdoor
              ? buildOutdoorTheme(Brightness.light)
              : buildTheme(brightness: cell.brightness),
        ),
        builder: (BuildContext context, Widget? child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(cell.textScale)),
          child: child!,
        ),
        home: MeetingReviewScreen(
          meeting: Meeting(
            id: 'meeting-layout',
            projectId: 'project-layout',
            title: 'Site review',
            startedAt: DateTime.utc(2026, 10, 1),
            attendees: const <Attendee>[
              Attendee(id: 'a1', name: 'Ada'),
              Attendee(id: 'a2', name: 'Ben'),
              Attendee(id: 'a3', name: 'Cal', status: AttendanceStatus.apology),
            ],
            decisions: const <Decision>[
              Decision(id: 'd1', text: 'Review observations'),
            ],
            actions: <ActionEntry>[
              ActionEntry(
                id: 'c1',
                text: 'Share minutes',
                ownerId: 'a1',
                ownerName: 'Ada',
                due: DateTime.utc(2026, 10, 2),
              ),
            ],
          ),
          notes: _notes,
          minutes: _minutes,
          transcript: _transcript,
          requireActionDetails: true,
          onApprove: onApprove,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
