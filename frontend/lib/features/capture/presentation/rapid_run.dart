import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/capture/domain/capture_record_persistence.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/presentation/capture_controller.dart';
import 'package:tapture/features/processing/processing.dart';

/// The items one rapid-mode run has saved, per project, oldest first.
final rapidRunProvider = NotifierProvider.autoDispose
    .family<RapidRun, List<RapidCapture>, String>(RapidRun.new);

/// A rapid-mode run (task 012 step 20, spec section 27): each item is saved
/// raw in one tap and the next begins with the same context and template.
/// Nothing is analysed until Process all.
final class RapidRun extends Notifier<List<RapidCapture>> {
  /// Creates the run for [projectId].
  RapidRun(this.projectId);

  /// The project the run captures into; also its capture session key.
  final String projectId;

  @override
  List<RapidCapture> build() => const <RapidCapture>[];

  /// Saves the item being captured raw, then starts the next one. The
  /// record and its evidence are durable before the item is listed.
  Future<Result<String>> next() async {
    final CaptureRecordPersistence? records = ref.read(
      captureRecordWriterProvider,
    );
    if (records == null) {
      return FailureResult<String>(_noRecords);
    }
    final CaptureSession item = ref.read(captureControllerProvider(projectId));
    final Result<String> saved = await ref
        .read(captureControllerProvider(projectId).notifier)
        .saveRaw(records.persist);
    if (saved case Success<String>(:final String value) when ref.mounted) {
      state = <RapidCapture>[
        ...state,
        (
          recordId: value,
          photos: item.photos
              .where((PhotoDraft photo) => photo.derivedFrom == null)
              .length,
          caption: item.recordCaption.trim(),
        ),
      ];
    }
    return saved;
  }

  /// Queues every item of the run for processing; returns how many queued.
  /// An item that cannot be queued keeps its captured record.
  Future<Result<int>> processAll() async {
    final ProcessingRepository processing = ref.read(
      processingRepositoryProvider,
    );
    int queued = 0;
    for (final RapidCapture item in state) {
      final Result<String> job = await processing.enqueue(item.recordId);
      if (job case FailureResult<String>(:final failure)) {
        return FailureResult<int>(failure);
      }
      queued++;
    }
    return Success<int>(queued);
  }
}

/// One saved capture of a rapid-mode run: its record, how many photos it
/// holds, and its caption.
typedef RapidCapture = ({String recordId, int photos, String caption});

/// No record store: nothing can be saved on this device.
final StorageFailure _noRecords = StorageFailure(
  localizedMessage: Copy.messages.captureSaveFailed,
);
