import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show KeepAliveLink;
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/lifecycle/leave_guard.dart';
import 'package:tapture/core/lifecycle/lifecycle_observer.dart';

import '../domain/meeting_repository.dart';
import '../meetings.dart' show meetingRepositoryProvider;

/// The current review text, including edits awaiting durable storage.
typedef MeetingReviewEdits = ({
  MeetingRecord record,
  String notes,
  String minutes,
  bool dirty,
  bool saving,
  bool saved,
  Failure? failure,
});

/// Serializes review edits and retains failed intents for an explicit retry.
final class MeetingReviewController extends AsyncNotifier<MeetingReviewEdits?> {
  /// Edits the stored meeting identified by [meetingId].
  MeetingReviewController(this.meetingId);

  /// Immutable route identity; changing the selected project cannot retarget it.
  final String meetingId;

  MeetingRecord? _record;
  String? _notes;
  String? _minutes;
  Future<bool>? _saving;
  KeepAliveLink? _keepAlive;
  late LeaveGuard _leaveGuard;

  @override
  Future<MeetingReviewEdits?> build() async {
    _leaveGuard = ref.read(leaveGuardProvider);
    final LifecycleObserver lifecycle = ref.read(lifecycleObserverProvider);
    lifecycle.addExitCheck(flush);
    lifecycle.addPauseFlush(_pauseFlush);
    ref.onDispose(() {
      _leaveGuard.release(this);
      lifecycle.removeExitCheck(flush);
      lifecycle.removePauseFlush(_pauseFlush);
    });
    _record = (await ref.read(meetingRepositoryProvider).read(meetingId))
        .getOrThrow();
    return _snapshot();
  }

  /// Queues working notes without replacing the source notes or minutes.
  void editNotes(String value) {
    _notes = value;
    _edited();
  }

  /// Queues refined minutes without changing the working or original notes.
  void editMinutes(String value) {
    _minutes = value;
    _edited();
  }

  void _edited() {
    _keepAlive ??= ref.keepAlive();
    _leaveGuard.hold(this);
    state = AsyncData<MeetingReviewEdits?>(_snapshot(saving: true));
    unawaited(flush());
  }

  /// Waits for all current intents; a failure leaves them in the editor.
  Future<bool> flush() =>
      _saving ??= _drain().whenComplete(() => _saving = null);

  Future<void> _pauseFlush() async {
    await flush();
  }

  Future<bool> _drain() async {
    final MeetingRepository repository = ref.read(meetingRepositoryProvider);
    try {
      while (_notes != null || _minutes != null) {
        state = AsyncData<MeetingReviewEdits?>(_snapshot(saving: true));
        final String? notes = _notes;
        final String? minutes = _minutes;
        final MeetingRecord? latest = (await repository.read(
          meetingId,
        )).getOrThrow();
        final String? recordId = latest?.meeting.recordId;
        if (latest == null || recordId == null) {
          throw const ValidationFailure();
        }
        _record = (await repository.save(
          latest.meeting,
          recordId: recordId,
          notes: notes ?? latest.notes,
          minutes: minutes ?? latest.minutes,
          transcript: latest.transcript,
        )).getOrThrow();
        if (_notes == notes) {
          _notes = null;
        }
        if (_minutes == minutes) {
          _minutes = null;
        }
        state = AsyncData<MeetingReviewEdits?>(_snapshot(saved: true));
      }
      _leaveGuard.release(this);
      _keepAlive?.close();
      _keepAlive = null;
      return true;
    } on Object catch (error) {
      state = AsyncData<MeetingReviewEdits?>(
        _snapshot(failure: Failure.from(error)),
      );
      return false;
    }
  }

  MeetingReviewEdits? _snapshot({
    bool saving = false,
    bool saved = false,
    Failure? failure,
  }) {
    final MeetingRecord? record = _record;
    if (record == null) {
      return null;
    }
    final bool dirty = _notes != null || _minutes != null;
    return (
      record: record,
      notes: _notes ?? record.notes,
      minutes: _minutes ?? record.minutes,
      dirty: dirty,
      saving: saving,
      saved: saved && !dirty,
      failure: failure,
    );
  }
}

/// One durable edit queue per meeting, retained while it has unsaved work.
final meetingReviewControllerProvider = AsyncNotifierProvider.autoDispose
    .family<MeetingReviewController, MeetingReviewEdits?, String>(
      MeetingReviewController.new,
      retry: (int _, Object _) => null,
    );
