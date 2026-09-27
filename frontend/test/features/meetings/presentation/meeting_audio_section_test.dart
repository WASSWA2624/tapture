import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/meetings/presentation/meeting_audio_section.dart';

import '../pump.dart';

void main() {
  testWidgets('recording shows elapsed time and free space', (
    WidgetTester tester,
  ) async {
    await pumpMeeting(
      tester,
      const MeetingAudioSection(
        recording: true,
        elapsed: Duration(minutes: 1, seconds: 5),
        remainingLabel: '2 GB',
      ),
    );
    expect(find.text(Copy.meetingElapsed('01:05')), findsOneWidget);
    expect(find.text(Copy.meetingRemaining('2 GB')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('audio-stop')), findsOneWidget);
  });

  testWidgets('an interruption keeps the partial file', (
    WidgetTester tester,
  ) async {
    await pumpMeeting(
      tester,
      const MeetingAudioSection(partialPath: 'audio/partial.m4a'),
    );
    expect(find.byKey(const ValueKey<String>('audio-partial')), findsOneWidget);
    expect(find.textContaining('audio/partial.m4a'), findsOneWidget);
  });

  testWidgets('empty and failure', (WidgetTester tester) async {
    await pumpMeeting(tester, const MeetingAudioSection());
    expect(find.byType(AppEmptyState), findsOneWidget);
    await pumpMeeting(
      tester,
      const MeetingAudioSection(failure: meetingFailed),
    );
    expect(find.byType(AppErrorState), findsOneWidget);
  });
}
