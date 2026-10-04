import 'package:tapture/core/audio/audio_recording.dart';
import 'package:tapture/core/errors/result.dart';

import '../domain/transcript_owner_kind.dart';
import 'transcript_mode.dart';

/// Where a surface's live transcript session records and files its audio.
///
/// Built only in a `*_providers.dart` or `*_controller.dart` file, never in
/// a widget (state_test): its callbacks reach repositories, which widgets
/// never call. The callbacks close over those repositories, never over a
/// `WidgetRef`, so filing finishes even after the surface is gone.
final class TranscriptSessionTarget {
  /// A session held under [sessionKey] for project [projectId], owned by
  /// [ownerKind] (and [ownerId] for a meeting).
  ///
  /// [audioPath] gives the storage-root-relative `.wav` the take publishes
  /// to. [beforeStart] runs before the transcript row is written, as the
  /// capture stages its pending audio. [fileAudio] files the published take
  /// and returns its attachment id, or null when it is not filed as one.
  /// [onDiscard] undoes [beforeStart] when the session is discarded or
  /// never opens the microphone. In [TranscriptMode.audioOnly] the audio is
  /// recorded without a transcript. With [keepAlive] the session outlives
  /// the page that started it until it is filed.
  const TranscriptSessionTarget({
    required this.sessionKey,
    required this.projectId,
    required this.ownerKind,
    required this.audioPath,
    required this.fileAudio,
    this.ownerId,
    this.beforeStart,
    this.onDiscard,
    this.mode = TranscriptMode.live,
    this.keepAlive = true,
  });

  /// The key the controller is held under (`LiveTranscriptKey`).
  final String sessionKey;

  /// The project the transcript belongs to.
  final String projectId;

  /// Who owns the transcript.
  final TranscriptOwnerKind ownerKind;

  /// The meeting id of a meeting transcript; null otherwise.
  final String? ownerId;

  /// The storage-root-relative path the take publishes to.
  final Future<Result<String>> Function() audioPath;

  /// Runs before the transcript row is written, or null.
  final Future<Result<void>> Function()? beforeStart;

  /// Files the published take and returns its attachment id, or null.
  final Future<Result<String?>> Function(AudioRecording audio) fileAudio;

  /// Undoes [beforeStart] when the session is discarded, or null.
  final Future<void> Function()? onDiscard;

  /// Whether the session transcribes or only records.
  final TranscriptMode mode;

  /// Whether the session outlives its page until it is filed.
  final bool keepAlive;
}
