import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/speech/speech_preferences.dart';
import 'package:tapture/core/speech/speech_readiness.dart';
import 'package:tapture/core/speech/speech_readiness_notifier.dart';
import 'package:tapture/core/speech/speech_selection.dart';
import 'package:tapture/core/widgets/app_chip.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/responsive/responsive_pair.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/projects/projects.dart'
    show Project, currentProjectProvider, projectByIdProvider;

import 'live_transcript_key.dart';
import 'live_transcript_panel.dart';
import 'live_transcript_status.dart';
import 'transcript_providers.dart';
import 'transcript_session_phase.dart';
import 'transcript_session_target.dart';

/// Records speech and writes it down on this device as it is spoken (spec
/// §30.4.5): a standalone transcript whose take is filed in the project
/// folder, `projects/<folder>/audio/<id>.wav`.
///
/// With no project open it asks for one; where no speech model can run it
/// says so and links to Language settings. Once the recording is saved the
/// transcript's page opens, read-only until the last words are written.
class TranscribeScreen extends ConsumerWidget {
  /// Records into [projectId], or into the open project when null.
  const TranscribeScreen({this.projectId, super.key});

  /// The project named by the route; null records into the open project.
  final String? projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);
    final String? project = projectId ?? ref.watch(currentProjectProvider);
    // A project that is not on this device is no project to record into.
    final bool missing =
        project == null ||
        switch (ref.watch(projectByIdProvider(project))) {
          AsyncData<Project?>(:final Project? value) => value == null,
          _ => false,
        };
    if (project == null || missing) {
      return AppPage(
        key: const ValueKey<String>('route-transcribe'),
        title: localCopy.transcribeTitle,
        body: AppEmptyState(
          icon: AppIcons.project,
          headline: localCopy.transcriptsNoProject,
          message: localCopy.transcriptsNoProjectMessage,
          actionLabel: localCopy.navProjects,
          onAction: () => context.go(RoutePaths.projects),
        ),
      );
    }
    final String sessionKey = LiveTranscriptKey.standalone(project);
    final LiveTranscriptStatus status = ref.watch(
      liveTranscriptControllerProvider(sessionKey),
    );
    ref.listen<LiveTranscriptStatus>(
      liveTranscriptControllerProvider(sessionKey),
      (LiveTranscriptStatus? previous, LiveTranscriptStatus next) {
        final String? saved = next.transcriptId;
        if (next.phase == TranscriptSessionPhase.saved &&
            previous?.phase != TranscriptSessionPhase.saved &&
            saved != null) {
          context.go(_detail(saved));
        }
      },
    );
    final SpeechReadiness readiness = ref.watch(speechReadinessProvider);
    final TranscriptSessionTarget? target = ref.watch(
      standaloneTranscriptTargetProvider(project),
    );
    // A session already running keeps its panel whatever the readiness.
    final bool idle = status.phase == TranscriptSessionPhase.idle;
    final Widget body;
    if (target == null || (idle && readiness.verdict == null)) {
      body = const AppSkeleton(shape: SkeletonShape.detail, count: 1);
    } else if (idle && !readiness.ready) {
      body = AppEmptyState(
        key: const ValueKey<String>('transcribe-unavailable'),
        icon: AppIcons.transcript,
        headline: localCopy.liveTranscriptUnavailable,
        message: localCopy.liveTranscriptUnavailableRecovery,
        actionLabel: localCopy.settingsLanguageTitle,
        onAction: () => context.go(RoutePaths.settingsLanguage),
      );
    } else {
      body = ResponsivePair(
        endFlex: 2,
        start: _SessionDetails(
          languageTag: ref.watch(speechLanguageProvider),
          selection: readiness.selection,
        ),
        end: LiveTranscriptPanel(
          target: target,
          startLabel: localCopy.liveTranscriptStart,
          onOpenTranscript: (String transcriptId) =>
              context.go(_detail(transcriptId)),
        ),
      );
    }
    return AppPage(
      key: const ValueKey<String>('route-transcribe'),
      title: localCopy.transcribeTitle,
      body: body,
    );
  }

  /// The page of saved transcript [transcriptId], in the branch this
  /// screen was opened from.
  String _detail(String transcriptId) {
    final String? named = projectId;
    return named == null
        ? RoutePaths.transcript(transcriptId)
        : RoutePaths.projectTranscript(named, transcriptId);
  }
}

/// What the recording will be heard as: the voice language and the speech
/// model chosen for this device.
class _SessionDetails extends StatelessWidget {
  const _SessionDetails({required this.languageTag, required this.selection});

  final String languageTag;
  final SpeechSelection? selection;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);
    final SpeechSelection? chosen = selection;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.x2),
      child: AppChipRow(
        chips: <AppChip>[
          AppChip(label: localCopy.transcriptLanguage(languageTag)),
          if (chosen != null)
            AppChip(label: localCopy.transcriptModel(chosen.model.id)),
        ],
      ),
    );
  }
}
