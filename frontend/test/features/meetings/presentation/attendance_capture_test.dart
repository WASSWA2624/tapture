import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/meetings/domain/attendance_reading.dart';
import 'package:tapture/features/meetings/presentation/attendance_capture.dart';

import '../pump.dart';

void main() {
  testWidgets(
    'a poor read keeps the photo and rows are not added until accepted',
    (WidgetTester tester) async {
      var accepted = false;
      await pumpMeeting(
        tester,
        AttendanceCapture(
          photoPath: 'sheet.jpg',
          onAccept: () => accepted = true,
        ),
      );
      expect(
        find.byKey(const ValueKey<String>('attendance-photo')),
        findsOneWidget,
      );
      expect(find.textContaining(Copy.meetingSheetKept), findsOneWidget);
      expect(accepted, isFalse);
      await tester.tap(find.byKey(const ValueKey<String>('attendance-accept')));
      await tester.pump();
      expect(accepted, isFalse);
    },
  );

  testWidgets('edited rows join only on accept', (WidgetTester tester) async {
    var accepted = false;
    await pumpMeeting(
      tester,
      AttendanceCapture(
        photoPath: 'sheet.jpg',
        readings: const <AttendanceReading>[
          AttendanceReading(name: 'Ada', nameConfidence: 0.91),
        ],
        onAccept: () => accepted = true,
      ),
    );
    expect(find.text('Ada'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey<String>('attendance-accept')));
    await tester.pump();
    expect(accepted, isTrue);
  });

  testWidgets('empty and failure', (WidgetTester tester) async {
    await pumpMeeting(tester, const AttendanceCapture());
    expect(find.byType(AppEmptyState), findsOneWidget);
    await pumpMeeting(tester, const AttendanceCapture(failure: meetingFailed));
    expect(find.byType(AppErrorState), findsOneWidget);
  });
}
