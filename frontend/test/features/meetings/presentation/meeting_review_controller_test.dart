import 'dart:ui' show AppExitResponse;
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/lifecycle/leave_guard.dart';
import 'package:tapture/core/lifecycle/lifecycle_observer.dart';
import 'package:tapture/features/meetings/meetings.dart'
    show meetingRepositoryProvider;
import 'package:tapture/features/meetings/presentation/meeting_review_controller.dart';

import '../fakes/fake_meeting_repository.dart';
import '../meeting_live_harness.dart';
import '../pump.dart';

void main() {
  late FakeMeetingRepository repository;
  late ProviderContainer container;
  late LeaveGuard leaveGuard;
  late MeetingReviewController controller;
  late LifecycleObserver lifecycle;

  setUp(() async {
    repository = FakeMeetingRepository()
      ..seed(aLiveMeeting(), notes: 'source', minutes: 'initial');
    leaveGuard = LeaveGuard.fake();
    lifecycle = LifecycleObserver.fake();
    container = ProviderContainer(
      overrides: [
        meetingRepositoryProvider.overrideWithValue(repository),
        leaveGuardProvider.overrideWithValue(leaveGuard),
        lifecycleObserverProvider.overrideWithValue(lifecycle),
      ],
    );
    container.listen(meetingReviewControllerProvider(liveMeetingId), (_, _) {});
    await container.read(meetingReviewControllerProvider(liveMeetingId).future);
    controller = container.read(
      meetingReviewControllerProvider(liveMeetingId).notifier,
    );
  });

  tearDown(() {
    container.dispose();
    lifecycle.dispose();
  });

  test(
    'serializes interleaved edits and reports saved only after storage',
    () async {
      final Completer<void> entered = Completer<void>();
      final Completer<void> release = Completer<void>();
      int inFlight = 0;
      int highest = 0;
      repository.beforeSave = () async {
        inFlight++;
        highest = inFlight > highest ? inFlight : highest;
        if (!entered.isCompleted) {
          entered.complete();
          await release.future;
        }
        inFlight--;
      };
      controller.editNotes('first');
      await entered.future;
      controller.editMinutes('minutes');
      controller.editNotes('latest');
      final MeetingReviewEdits pending = container
          .read(meetingReviewControllerProvider(liveMeetingId))
          .requireValue!;
      expect(pending.notes, 'latest');
      expect(pending.minutes, 'minutes');
      expect(pending.saved, isFalse);
      expect(leaveGuard.isHeld, isTrue);
      release.complete();
      expect(await controller.flush(), isTrue);
      expect(highest, 1);
      expect(repository.records[liveMeetingId]!.notes, 'latest');
      expect(repository.records[liveMeetingId]!.minutes, 'minutes');
      expect(repository.records[liveMeetingId]!.originalNotes, 'source');
      expect(leaveGuard.isHeld, isFalse);
      expect(
        container
            .read(meetingReviewControllerProvider(liveMeetingId))
            .requireValue!
            .saved,
        isTrue,
      );
    },
  );

  test(
    'failure retains both intents and retry reads the latest counterpart',
    () async {
      repository.saveFailure = meetingFailed;
      controller.editNotes('pending');
      expect(await controller.flush(), isFalse);
      expect(leaveGuard.isHeld, isTrue);
      expect(
        container
            .read(meetingReviewControllerProvider(liveMeetingId))
            .requireValue!
            .notes,
        'pending',
      );
      expect(repository.records[liveMeetingId]!.notes, 'source');
      repository.saveFailure = null;
      await repository.save(
        aLiveMeeting(),
        recordId: 'r1',
        notes: 'source',
        minutes: 'arrived asynchronously',
      );
      expect(await controller.flush(), isTrue);
      expect(repository.records[liveMeetingId]!.notes, 'pending');
      expect(
        repository.records[liveMeetingId]!.minutes,
        'arrived asynchronously',
      );
      expect(leaveGuard.isHeld, isFalse);
    },
  );
  test(
    'desktop exit refuses failed edits and background retries retained text',
    () async {
      repository.saveFailure = meetingFailed;
      controller.editMinutes('pending minutes');
      expect(await controller.flush(), isFalse);
      expect(await lifecycle.didRequestAppExit(), AppExitResponse.cancel);
      repository.saveFailure = null;
      await lifecycle.handle(AppLifecycleState.paused);
      expect(repository.records[liveMeetingId]!.minutes, 'pending minutes');
      expect(await lifecycle.didRequestAppExit(), AppExitResponse.exit);
      expect(leaveGuard.isHeld, isFalse);
    },
  );
}
