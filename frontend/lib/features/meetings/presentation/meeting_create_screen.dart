import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/context/context.dart';
import 'package:tapture/features/records/records.dart' show recordClockProvider;
import 'package:tapture/features/settings/settings.dart'
    show currentOperatorProvider;

import '../domain/meeting.dart';
import '../domain/meeting_repository.dart';
import '../meetings.dart' show meetingRepositoryProvider;

/// Starts a meeting from the clock, the context location and the profile.
///
/// The header is filled in. Starting it does not ask for those fields.
final class MeetingCreateScreen extends ConsumerWidget {
  /// Creates the start page. No [startedAt] and no [projectId] is empty.
  const MeetingCreateScreen({
    this.projectId,
    this.startedAt,
    this.location,
    this.secretary,
    this.failure,
    this.onStart,
    super.key,
  });

  /// Project the meeting is filed on. Set by the route.
  final String? projectId;

  /// Start instant. The route reads it from the clock.
  final DateTime? startedAt;

  /// Location from context.
  final String? location;

  /// Secretary from the operator profile.
  final String? secretary;

  /// Why the header could not be read.
  final Failure? failure;

  /// Called with the meeting the header describes. The route saves when
  /// this is null.
  final ValueChanged<Meeting>? onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Failure? failed = failure;
    if (failed != null) {
      return AppPage(
        title: Copy.meetingTitle,
        body: AppErrorState(failure: failed),
      );
    }
    final DateTime? given = startedAt;
    final String? project = projectId;
    if (given == null && project == null) {
      return const AppPage(
        title: Copy.meetingTitle,
        body: AppEmptyState(
          icon: AppIcons.records,
          headline: Copy.meetingEmptyHeadline,
          message: Copy.meetingEmptyMessage,
        ),
      );
    }
    if (given == null && project != null) {
      final AsyncValue<ContextState> contextState = ref.watch(
        projectContextProvider(project),
      );
      return contextState.when(
        loading: () =>
            const AppPage(title: Copy.meetingTitle, body: SizedBox.shrink()),
        error: (Object error, StackTrace _) => AppPage(
          title: Copy.meetingTitle,
          body: AppErrorState(failure: Failure.from(error)),
        ),
        data: (ContextState state) {
          final Clock clock = ref.watch(recordClockProvider);
          final String name = ref.watch(currentOperatorProvider)?.name ?? '';
          return _form(
            context,
            ref,
            started: clock.nowUtc(),
            place: location ?? _location(state),
            who: secretary ?? name,
          );
        },
      );
    }
    return _form(
      context,
      ref,
      started: given!,
      place: location ?? '',
      who: secretary ?? '',
    );
  }

  Widget _form(
    BuildContext context,
    WidgetRef ref, {
    required DateTime started,
    required String place,
    required String who,
  }) {
    final DateTime utc = started.toUtc();
    return AppPage(
      key: const ValueKey<String>('route-meeting-create'),
      title: Copy.meetingTitle,
      footer: AppButton(
        key: const ValueKey<String>('meeting-start'),
        label: Copy.meetingStart,
        expand: true,
        onPressed: () {
          final Meeting meeting = Meeting(
            id: '',
            projectId: projectId ?? '',
            title: Copy.meetingStartedTitle(utc),
            startedAt: utc,
            location: place,
            secretary: who,
          );
          final ValueChanged<Meeting>? start = onStart;
          if (start != null) {
            start(meeting);
            return;
          }
          unawaited(_save(context, ref, meeting));
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(_date(utc), key: const ValueKey<String>('meeting-date')),
          Text(_time(utc), key: const ValueKey<String>('meeting-time')),
          Text(place, key: const ValueKey<String>('meeting-location')),
          Text(who, key: const ValueKey<String>('meeting-secretary')),
        ],
      ),
    );
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    Meeting meeting,
  ) async {
    final String? project = projectId;
    if (project == null) {
      return;
    }
    final Clock clock = ref.read(recordClockProvider);
    final String recordId = UuidV7Service(clock).newId();
    final Result<MeetingRecord> saved = await ref
        .read(meetingRepositoryProvider)
        .save(meeting, recordId: recordId);
    if (!context.mounted) {
      return;
    }
    switch (saved) {
      case Success<MeetingRecord>(:final MeetingRecord value):
        context.go(
          RoutePaths.projectMeetingReview(project, value.meeting.id),
          extra: value.meeting,
        );
      case FailureResult<MeetingRecord>(:final Failure failure):
        showAppSnack(context, failure.message, tone: SnackTone.error);
    }
  }

  static String _date(DateTime utc) {
    final String month = utc.month.toString().padLeft(2, '0');
    final String day = utc.day.toString().padLeft(2, '0');
    return '${utc.year}-$month-$day';
  }

  static String _time(DateTime utc) {
    final String hour = utc.hour.toString().padLeft(2, '0');
    final String minute = utc.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String _location(ContextState state) {
    for (final MapEntry<String, String> entry in state.values.entries) {
      final String key = entry.key.toLowerCase();
      if (key.contains('location') ||
          key.contains('site') ||
          key.contains('venue')) {
        return entry.value.trim();
      }
    }
    return '';
  }
}
