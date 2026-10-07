import 'dart:async';

import 'package:tapture/core/audio/audio_recording.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/speech/finished_utterance.dart';
import 'package:tapture/core/speech/speech_text.dart';
import 'package:tapture/core/speech/transcript_outcome.dart';
import 'package:tapture/core/speech/transcript_segment.dart';
import 'package:tapture/core/speech/transcript_sink.dart';
import 'package:tapture/features/transcripts/domain/domain.dart';

/// In-memory [TranscriptRepository] for feature tests that must not open a
/// database (FE-STATE-10).
///
/// Keeps the store's rules that callers depend on: contiguous, idempotent
/// segments; edits refused while live; a reopened transcript restored on
/// finish. Every call is recorded in [calls] by method name, and a failure
/// set in [failures] under a method name is returned by that method
/// instead of writing.
final class FakeTranscriptRepository implements TranscriptRepository {
  final Map<String, TranscriptSummary> _summaries =
      <String, TranscriptSummary>{};
  final Map<String, List<TranscriptLine>> _lines =
      <String, List<TranscriptLine>>{};
  final Map<String, String?> _edits = <String, String?>{};
  final Map<String, TranscriptStatus> _reopened = <String, TranscriptStatus>{};
  final Set<String> _discarded = <String>{};
  final StreamController<void> _changes = StreamController<void>.broadcast();
  int _next = 0;

  /// Failures returned instead of writing, by method name.
  final Map<String, Failure> failures = <String, Failure>{};

  /// Every call, in order, by method name.
  final List<String> calls = <String>[];

  /// Utterances appended, by transcript id.
  final Map<String, List<FinishedUtterance>> utterances =
      <String, List<FinishedUtterance>>{};

  /// Record ids each attachment is filed on, for [watchRecord].
  final Map<String, Set<String>> recordAttachments = <String, Set<String>>{};

  /// The audio clips filed on each record, by record id, as
  /// [watchUntranscribedAudio] offers them.
  final Map<String, List<TranscriptStart>> recordAudio =
      <String, List<TranscriptStart>>{};

  /// Audio [fileStandaloneAudio] filed, by transcript id.
  final Map<String, AudioRecording> filedAudio = <String, AudioRecording>{};

  /// Stored summaries, including discarded ones.
  List<TranscriptSummary> get stored =>
      List<TranscriptSummary>.unmodifiable(_summaries.values);

  /// Ids [discard] removed.
  Set<String> get discarded => Set<String>.unmodifiable(_discarded);

  /// Stores [summary] as it is, with [lines] and [edit].
  void seed(
    TranscriptSummary summary, {
    List<TranscriptLine> lines = const <TranscriptLine>[],
    String? edit,
  }) {
    _summaries[summary.id] = summary;
    _lines[summary.id] = List<TranscriptLine>.of(lines);
    _edits[summary.id] = edit;
    _emit();
  }

  /// Releases the watch streams. Tests call this from `tearDown`.
  Future<void> dispose() => _changes.close();

  @override
  Future<Result<TranscriptSummary>> begin(TranscriptStart start) async {
    calls.add('begin');
    final Failure? failure = failures['begin'];
    if (failure != null) {
      return FailureResult<TranscriptSummary>(failure);
    }
    final String id = 'transcript-${++_next}';
    seed(
      TranscriptSummary(
        id: id,
        projectId: start.projectId,
        ownerKind: start.ownerKind,
        ownerId: start.ownerId,
        attachmentId: start.attachmentId,
        audioPath: start.audioPath,
        title: start.title,
        status: TranscriptStatus.live,
        startedAt: start.startedAt,
        languageTag: start.languageTag,
        modelId: start.modelId,
      ),
    );
    return Success<TranscriptSummary>(_summaries[id]!);
  }

  @override
  Future<Result<void>> appendUtterance(
    String transcriptId,
    FinishedUtterance utterance,
  ) async {
    calls.add('appendUtterance');
    final Failure? refused =
        failures['appendUtterance'] ?? _notLive(transcriptId);
    if (refused != null) {
      return FailureResult<void>(refused);
    }
    final List<TranscriptLine> lines = List<TranscriptLine>.of(
      _lines[transcriptId]!,
    );
    for (final TranscriptSegment segment in utterance.segments) {
      if (segment.id == lines.length + 1) {
        lines.add(TranscriptLine.fromSegment(segment));
      } else if (segment.id < 1 ||
          segment.id > lines.length ||
          lines.firstWhere((TranscriptLine l) => l.seq == segment.id).text !=
              segment.text) {
        return const FailureResult<void>(StorageFailure());
      }
    }
    lines.sort((TranscriptLine a, TranscriptLine b) {
      final int byStart = a.start.compareTo(b.start);
      return byStart != 0 ? byStart : a.seq.compareTo(b.seq);
    });
    _lines[transcriptId] = lines;
    final TranscriptSummary summary = _summaries[transcriptId]!;
    final TranscriptGap range = TranscriptGap(
      start: _time(utterance.fromSample),
      end: _time(utterance.toSample),
    );
    final List<TranscriptGap> gaps = utterance.skipped
        ? <TranscriptGap>{...summary.gaps, range}.toList()
        : <TranscriptGap>[
            for (final TranscriptGap gap in summary.gaps)
              if (!_overlapsWhole(gap, range)) gap,
          ];
    final int covered = range.end.inMilliseconds;
    _summaries[transcriptId] = _copy(
      summary,
      gaps: gaps,
      coveredMs: covered > summary.coveredMs ? covered : summary.coveredMs,
      preview: _previewOf(transcriptId),
    );
    (utterances[transcriptId] ??= <FinishedUtterance>[]).add(utterance);
    _emit();
    return const Success<void>(null);
  }

  @override
  Future<Result<TranscriptSink>> sinkFor(String transcriptId) async {
    calls.add('sinkFor');
    final Failure? refused = failures['sinkFor'] ?? _notLive(transcriptId);
    if (refused != null) {
      return FailureResult<TranscriptSink>(refused);
    }
    return Success<TranscriptSink>(_FakeSink(this, transcriptId));
  }

  @override
  Future<Result<void>> linkAttachment(String id, String attachmentId) async {
    calls.add('linkAttachment');
    final Failure? refused = failures['linkAttachment'] ?? _missing(id);
    if (refused != null) {
      return FailureResult<void>(refused);
    }
    final TranscriptSummary summary = _summaries[id]!;
    final String? linked = summary.attachmentId;
    if (linked != null && linked != attachmentId) {
      return const FailureResult<void>(ValidationFailure());
    }
    _summaries[id] = _copy(summary, attachmentId: attachmentId);
    _emit();
    return const Success<void>(null);
  }

  @override
  Future<Result<TranscriptSummary>> complete(
    String id, {
    required Duration duration,
    required String languageTag,
    String? modelId,
  }) {
    calls.add('complete');
    return _finish(
      id,
      complete: true,
      duration: duration,
      languageTag: languageTag,
      modelId: modelId,
    );
  }

  @override
  Future<Result<TranscriptSummary>> markInterrupted(
    String id, {
    Duration? duration,
  }) {
    calls.add('markInterrupted');
    return _finish(id, complete: false, duration: duration);
  }

  @override
  Future<Result<String>> fileStandaloneAudio(
    String id,
    AudioRecording audio,
  ) async {
    calls.add('fileStandaloneAudio');
    final Failure? refused = failures['fileStandaloneAudio'] ?? _missing(id);
    if (refused != null) {
      return FailureResult<String>(refused);
    }
    final String attachmentId =
        _summaries[id]!.attachmentId ?? 'attachment-$id';
    filedAudio[id] = audio;
    _summaries[id] = _copy(_summaries[id]!, attachmentId: attachmentId);
    _emit();
    return Success<String>(attachmentId);
  }

  @override
  Future<Result<void>> discard(String id) async {
    calls.add('discard');
    final Failure? refused = failures['discard'] ?? _missing(id);
    if (refused != null) {
      return FailureResult<void>(refused);
    }
    _discarded.add(id);
    _emit();
    return const Success<void>(null);
  }

  @override
  Future<Result<TranscriptSummary>> rename(
    String id,
    String title, {
    String? operator,
  }) async {
    calls.add('rename');
    final Failure? refused = failures['rename'] ?? _missing(id);
    if (refused != null) {
      return FailureResult<TranscriptSummary>(refused);
    }
    _summaries[id] = _copy(_summaries[id]!, title: title);
    _emit();
    return Success<TranscriptSummary>(_summaries[id]!);
  }

  @override
  Future<Result<Transcript>> saveEdit(
    String id,
    String text, {
    String? operator,
  }) async {
    calls.add('saveEdit');
    return _edit('saveEdit', id, text);
  }

  @override
  Future<Result<Transcript>> clearEdit(String id, {String? operator}) async {
    calls.add('clearEdit');
    return _edit('clearEdit', id, null);
  }

  @override
  Future<Result<void>> reopenForRemaining(String id) async {
    calls.add('reopenForRemaining');
    final Failure? refused = failures['reopenForRemaining'] ?? _missing(id);
    if (refused != null) {
      return FailureResult<void>(refused);
    }
    final TranscriptSummary summary = _summaries[id]!;
    if (summary.status != TranscriptStatus.live) {
      _reopened[id] = summary.status;
      _summaries[id] = _copy(summary, status: TranscriptStatus.live);
      _emit();
    }
    return const Success<void>(null);
  }

  @override
  Future<Result<Transcript?>> read(String id) async {
    calls.add('read');
    final Failure? failure = failures['read'];
    if (failure != null) {
      return FailureResult<Transcript?>(failure);
    }
    return Success<Transcript?>(_transcript(id));
  }

  @override
  Stream<Transcript?> watch(String id) {
    return _watch(() => _transcript(id));
  }

  @override
  Stream<List<TranscriptSummary>> watchProject(
    String? projectId, {
    String query = '',
    int limit = AppConstants.listPageSize,
  }) {
    final String needle = query.trim().toLowerCase();
    return _watch(() {
      return _listed((TranscriptSummary s) {
        if (projectId != null && s.projectId != projectId) {
          return false;
        }
        if (needle.isEmpty) {
          return true;
        }
        return s.title.toLowerCase().contains(needle) ||
            (_edits[s.id]?.toLowerCase().contains(needle) ?? false) ||
            _lines[s.id]!.any(
              (TranscriptLine l) => l.text.toLowerCase().contains(needle),
            );
      }).take(limit).toList();
    });
  }

  @override
  Stream<List<TranscriptSummary>> watchRecord(String recordId) {
    return _watch(() {
      return _listed((TranscriptSummary s) {
        final String? attachment = s.attachmentId;
        return attachment != null &&
            (recordAttachments[attachment]?.contains(recordId) ?? false);
      });
    });
  }

  @override
  Stream<List<TranscriptStart>> watchUntranscribedAudio(String recordId) {
    return _watch(() {
      final Set<String> heard = <String>{
        for (final TranscriptSummary s in _summaries.values)
          if (!_discarded.contains(s.id)) ?s.attachmentId,
      };
      return <TranscriptStart>[
        for (final TranscriptStart clip
            in recordAudio[recordId] ?? const <TranscriptStart>[])
          if (!heard.contains(clip.attachmentId)) clip,
      ];
    });
  }

  @override
  Stream<List<TranscriptSummary>> watchMeeting(String meetingId) {
    return _watch(() {
      return _listed(
        (TranscriptSummary s) =>
            s.ownerKind == TranscriptOwnerKind.meeting &&
            s.ownerId == meetingId,
      );
    });
  }

  @override
  Future<Result<TranscriptSummary?>> completedForAttachment(
    String attachmentId,
  ) async {
    calls.add('completedForAttachment');
    final Failure? failure = failures['completedForAttachment'];
    if (failure != null) {
      return FailureResult<TranscriptSummary?>(failure);
    }
    final List<TranscriptSummary> found = _listed(
      (TranscriptSummary s) =>
          s.attachmentId == attachmentId &&
          s.status == TranscriptStatus.complete,
    );
    return Success<TranscriptSummary?>(found.isEmpty ? null : found.first);
  }

  @override
  Future<Result<List<TranscriptSummary>>> stale() async {
    calls.add('stale');
    final Failure? failure = failures['stale'];
    if (failure != null) {
      return FailureResult<List<TranscriptSummary>>(failure);
    }
    return Success<List<TranscriptSummary>>(
      _listed((TranscriptSummary s) => s.status == TranscriptStatus.live),
    );
  }

  Future<Result<TranscriptSummary>> _finish(
    String id, {
    required bool complete,
    Duration? duration,
    String? languageTag,
    String? modelId,
    int? coveredMs,
  }) async {
    final String name = complete ? 'complete' : 'markInterrupted';
    final Failure? refused = failures[name] ?? _missing(id);
    if (refused != null) {
      return FailureResult<TranscriptSummary>(refused);
    }
    final TranscriptSummary summary = _summaries[id]!;
    final TranscriptStatus target = complete
        ? TranscriptStatus.complete
        : _reopened[id] ?? TranscriptStatus.interrupted;
    if (summary.status != TranscriptStatus.live) {
      return summary.status == target
          ? Success<TranscriptSummary>(summary)
          : const FailureResult<TranscriptSummary>(StorageFailure());
    }
    _reopened.remove(id);
    _summaries[id] = _copy(
      summary,
      status: target,
      duration: duration ?? summary.duration,
      languageTag: languageTag,
      modelId: modelId,
      coveredMs: coveredMs != null && coveredMs > summary.coveredMs
          ? coveredMs
          : null,
    );
    _emit();
    return Success<TranscriptSummary>(_summaries[id]!);
  }

  Result<Transcript> _edit(String method, String id, String? text) {
    final Failure? refused = failures[method] ?? _missing(id);
    if (refused != null) {
      return FailureResult<Transcript>(refused);
    }
    if (_summaries[id]!.status == TranscriptStatus.live) {
      return const FailureResult<Transcript>(ValidationFailure());
    }
    final String raw = _transcript(id)!.rawText;
    final String? edit = text == raw ? null : text;
    _edits[id] = edit;
    _summaries[id] = _copy(
      _summaries[id]!,
      edited: edit != null,
      preview: _previewOf(id),
    );
    _emit();
    return Success<Transcript>(_transcript(id)!);
  }

  Transcript? _transcript(String id) {
    final TranscriptSummary? summary = _summaries[id];
    if (summary == null || _discarded.contains(id)) {
      return null;
    }
    return Transcript(
      summary: summary,
      lines: List<TranscriptLine>.unmodifiable(_lines[id]!),
      editedText: _edits[id],
    );
  }

  List<TranscriptSummary> _listed(bool Function(TranscriptSummary) keep) {
    return _summaries.values
        .where((TranscriptSummary s) => !_discarded.contains(s.id) && keep(s))
        .toList()
      ..sort((TranscriptSummary a, TranscriptSummary b) {
        final int byStart = b.startedAt.compareTo(a.startedAt);
        return byStart != 0 ? byStart : b.id.compareTo(a.id);
      });
  }

  Failure? _missing(String id) =>
      _summaries.containsKey(id) && !_discarded.contains(id)
      ? null
      : const StorageFailure();

  Failure? _notLive(String id) =>
      _missing(id) ??
      (_summaries[id]!.status == TranscriptStatus.live
          ? null
          : const StorageFailure());

  String _previewOf(String id) {
    final String text =
        _edits[id] ??
        SpeechText.join(_lines[id]!.map((TranscriptLine l) => l.text));
    final int chars = AppConstants.transcripts.previewChars;
    return text.length <= chars ? text : text.substring(0, chars);
  }

  Stream<T> _watch<T>(T Function() snapshot) async* {
    yield snapshot();
    await for (final void _ in _changes.stream) {
      yield snapshot();
    }
  }

  void _emit() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }
}

final class _FakeSink implements TranscriptSink {
  _FakeSink(this._repository, this._id);

  final FakeTranscriptRepository _repository;
  final String _id;

  @override
  Future<Result<void>> appendUtterance(FinishedUtterance utterance) {
    return _repository.appendUtterance(_id, utterance);
  }

  @override
  Future<Result<void>> finish(TranscriptOutcome outcome) async {
    _repository.calls.add('finish');
    final Result<TranscriptSummary> finished = await _repository._finish(
      _id,
      complete: outcome.complete,
      duration: outcome.captured,
      languageTag: outcome.languageTag,
      modelId: outcome.modelId,
      coveredMs: _time(outcome.coveredToSample).inMilliseconds,
    );
    return finished.map((_) {});
  }
}

Duration _time(int sample) => Duration(
  milliseconds:
      sample * Duration.millisecondsPerSecond ~/ AppConstants.audio.sampleRate,
);

bool _overlapsWhole(TranscriptGap gap, TranscriptGap filled) =>
    (filled.start >= gap.start && filled.end <= gap.end) ||
    (gap.start >= filled.start && gap.end <= filled.end);

TranscriptSummary _copy(
  TranscriptSummary s, {
  String? attachmentId,
  String? title,
  TranscriptStatus? status,
  Duration? duration,
  String? languageTag,
  String? modelId,
  int? coveredMs,
  List<TranscriptGap>? gaps,
  String? preview,
  bool? edited,
}) {
  return TranscriptSummary(
    id: s.id,
    projectId: s.projectId,
    ownerKind: s.ownerKind,
    ownerId: s.ownerId,
    attachmentId: attachmentId ?? s.attachmentId,
    audioPath: s.audioPath,
    title: title ?? s.title,
    status: status ?? s.status,
    startedAt: s.startedAt,
    endedAt: s.endedAt,
    duration: duration ?? s.duration,
    languageTag: languageTag ?? s.languageTag,
    modelId: modelId ?? s.modelId,
    coveredMs: coveredMs ?? s.coveredMs,
    gaps: gaps ?? s.gaps,
    preview: preview ?? s.preview,
    edited: edited ?? s.edited,
  );
}
