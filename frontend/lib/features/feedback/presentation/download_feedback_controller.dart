import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/concurrency/concurrency.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/download_service.dart';
import 'package:tapture/core/time/clock.dart';

import '../domain/feedback_archive.dart';
import '../domain/feedback_entry.dart';
import '../domain/feedback_filter.dart';
import '../domain/feedback_repository.dart';
import '../domain/feedback_workbook.dart';
import 'download_feedback_view.dart';
import 'feedback_providers.dart';

/// Filters and downloads matching feedback as a zip of the workbook and
/// its screenshots.
final class DownloadFeedbackController extends Notifier<DownloadFeedbackView> {
  /// Creates the controller.
  DownloadFeedbackController();

  CancellationToken? _cancel;

  @override
  DownloadFeedbackView build() {
    // Closing the screen abandons an encode still running.
    ref.onDispose(() {
      _cancel?.cancel();
    });
    return (
      filter: const FeedbackFilter(),
      moreFilters: false,
      visible: AppConstants.userFeedback.listPageSize,
      busy: false,
      error: null,
    );
  }

  /// Replaces the filter and resets the visible page.
  void setFilter(FeedbackFilter filter) {
    _set(
      filter: filter,
      visible: AppConstants.userFeedback.listPageSize,
      busy: false,
      error: null,
    );
  }

  /// Opens or folds the facets beyond search and type.
  void toggleMoreFilters() {
    _set(moreFilters: !state.moreFilters);
  }

  /// Shows another page of matching rows.
  void showMore() {
    _set(visible: state.visible + AppConstants.userFeedback.listPageSize);
  }

  /// Encodes the matching entries as a zip and hands the file to the operator.
  Future<Result<String?>> download(List<FeedbackEntry> matching) async {
    if (matching.isEmpty || state.filter.isRangeBackwards) {
      return const FailureResult<String?>(
        ValidationFailure(
          recoveryAction: 'Change or clear the filters, then try again.',
        ),
      );
    }
    // Read before the first await: the screen may close while this runs.
    final FeedbackRepository repository = ref.read(feedbackRepositoryProvider);
    final DownloadService downloads = ref.read(feedbackDownloadsProvider);
    final Clock clock = ref.read(feedbackClockProvider);
    final String generatedBy = ref.read(feedbackDeviceIdProvider);
    final FeedbackFilter filter = state.filter;
    _set(busy: true, error: null);
    _cancel?.cancel();
    final CancellationToken cancel = CancellationToken();
    _cancel = cancel;
    final Map<String, Uint8List> shots = <String, Uint8List>{};
    for (final FeedbackEntry entry in matching) {
      final Result<List<Uint8List>> read = await repository.screenshots(
        entry.id,
      );
      if (!ref.mounted) {
        return const FailureResult<String?>(CancelledFailure());
      }
      switch (read) {
        case FailureResult<List<Uint8List>>(:final Failure failure):
          _idle(failure.message);
          return FailureResult<String?>(failure);
        case Success<List<Uint8List>>(:final List<Uint8List> value):
          for (int index = 0; index < value.length; index++) {
            final Uint8List png = value[index];
            if (png.isEmpty) {
              continue;
            }
            final String key = index == 0
                ? entry.id
                : '${entry.id}#${index + 1}';
            shots[key] = png;
          }
      }
    }
    final FeedbackWorkbook workbook = FeedbackWorkbook(
      entries: matching,
      screenshots: shots,
      filter: filter,
      generatedAtUtc: clock.nowUtc(),
      utcOffset: clock.offset,
      timeZone: clock.nowUtc().toLocal().timeZoneName,
      generatedBy: generatedBy,
    );
    final FeedbackArchive pack = FeedbackArchive(workbook: workbook);
    final Result<Uint8List> encoded = await runIsolate(
      FeedbackArchive.encode,
      pack,
      cancel: cancel,
    );
    if (!ref.mounted) {
      return const FailureResult<String?>(CancelledFailure());
    }
    final Uint8List bytes;
    switch (encoded) {
      case Success<Uint8List>(:final Uint8List value):
        bytes = value;
      case FailureResult<Uint8List>(:final Failure failure):
        if (failure is CancelledFailure) {
          _idle(null);
          return FailureResult<String?>(failure);
        }
        bytes = FeedbackArchive.encode(pack);
    }
    final Result<String?> saved = await downloads.save(
      fileName: pack.fileName,
      bytes: bytes,
      mimeType: FeedbackArchive.mimeType,
    );
    switch (saved) {
      case Success<String?>():
        _idle(null);
      case FailureResult<String?>(:final Failure failure):
        _idle(failure.message);
    }
    return saved;
  }

  void _idle(String? error) {
    if (ref.mounted) {
      _set(busy: false, error: error);
    }
  }

  /// [state] with the given parts replaced. [error] is kept unless given.
  void _set({
    FeedbackFilter? filter,
    bool? moreFilters,
    int? visible,
    bool? busy,
    Object? error = _keep,
  }) {
    state = (
      filter: filter ?? state.filter,
      moreFilters: moreFilters ?? state.moreFilters,
      visible: visible ?? state.visible,
      busy: busy ?? state.busy,
      error: identical(error, _keep) ? state.error : error as String?,
    );
  }
}

/// Marks "leave the error as it is" in [DownloadFeedbackController._set].
const Object _keep = Object();

/// Filter and download state for [DownloadFeedbackScreen]. Disposed with
/// the screen, so every opening starts from no filter (FE-STATE-09).
final NotifierProvider<DownloadFeedbackController, DownloadFeedbackView>
downloadFeedbackControllerProvider =
    NotifierProvider.autoDispose<
      DownloadFeedbackController,
      DownloadFeedbackView
    >(DownloadFeedbackController.new);
