import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/processing/processing.dart'
    show ProcessingRepository, processingRepositoryProvider;

/// Whether a record is being put back in the processing queue after its
/// photos changed. Auto-dispose: a record page that shows the progress is
/// its only reader (FE-STATE-09).
final recordPhotosEditorControllerProvider =
    NotifierProvider.autoDispose<RecordPhotosEditorController, bool>(
      RecordPhotosEditorController.new,
    );

/// Sends a record whose photos changed back to processing (task 014 step 5,
/// D14), so the photos added long after capture are read for values too.
///
/// The state is true while a request is running.
final class RecordPhotosEditorController extends Notifier<bool> {
  /// Creates the controller.
  RecordPhotosEditorController();

  /// Held so a request started from a page still reaches the queue when the
  /// page, and with it this controller, has gone, as a retry from the snack
  /// can.
  late ProcessingRepository _processing;

  @override
  bool build() {
    _processing = ref.watch(processingRepositoryProvider);
    return false;
  }

  /// Puts record [recordId] back in the processing queue: its job starts
  /// over and the record moves to queued. Returns the job id, or why the
  /// record could not be queued, for example because it is processing now.
  Future<Result<String>> processAgain(String recordId) async {
    final ProcessingRepository processing = _processing;
    if (ref.mounted) {
      state = true;
    }
    try {
      return await processing.requeue(recordId);
    } on Object catch (error) {
      return FailureResult<String>(Failure.from(error));
    } finally {
      if (ref.mounted) {
        state = false;
      }
    }
  }
}
