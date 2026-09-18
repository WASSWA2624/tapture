import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/concurrency/concurrency.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/time/clock.dart';

import '../domain/feedback_archive.dart';
import '../domain/feedback_entry.dart';
import '../domain/feedback_filter.dart';
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
    ref.onDispose(() {
      _cancel?.cancel();
    });
    return (
      filter: const FeedbackFilter(),
      visible: AppConstants.userFeedback.listPageSize,
      busy: false,
      error: null,
    );
  }

  /// Replaces the filter and resets the visible page.
  void setFilter(FeedbackFilter filter) {
    state = (
      filter: filter,
      visible: AppConstants.userFeedback.listPageSize,
      busy: false,
      error: null,
    );
  }

  /// Shows another page of matching rows.
  void showMore() {
    state = (
      filter: state.filter,
      visible: state.visible + AppConstants.userFeedback.listPageSize,
      busy: state.busy,
      error: state.error,
    );
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
    state = (
      filter: state.filter,
      visible: state.visible,
      busy: true,
      error: null,
    );
    _cancel?.cancel();
    final CancellationToken cancel = CancellationToken();
    _cancel = cancel;
    final Map<String, Uint8List> shots = <String, Uint8List>{};
    for (final FeedbackEntry entry in matching) {
      final Result<Uint8List?> read = await ref
          .read(feedbackRepositoryProvider)
          .screenshot(entry.id);
      switch (read) {
        case FailureResult<Uint8List?>(:final Failure failure):
          _idle(failure.message);
          return FailureResult<String?>(failure);
        case Success<Uint8List?>(:final Uint8List? value):
          if (value != null && value.isNotEmpty) {
            shots[entry.id] = value;
          }
      }
    }
    final Clock clock = ref.read(feedbackClockProvider);
    final FeedbackWorkbook workbook = FeedbackWorkbook(
      entries: matching,
      screenshots: shots,
      filter: state.filter,
      generatedAtUtc: clock.nowUtc(),
      utcOffset: clock.offset,
      timeZone: clock.nowUtc().toLocal().timeZoneName,
      generatedBy: ref.read(feedbackDeviceIdProvider),
    );
    final FeedbackArchive pack = FeedbackArchive(workbook: workbook);
    final Result<Uint8List> encoded = await runIsolate(
      FeedbackArchive.encode,
      pack,
      cancel: cancel,
    );
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
    final Result<String?> saved = await ref
        .read(feedbackDownloadsProvider)
        .save(
          fileName: pack.fileName,
          bytes: bytes,
          mimeType: FeedbackArchive.mimeType,
        );
    switch (saved) {
      case Success<String?>():
        _idle(null);
        return saved;
      case FailureResult<String?>(:final Failure failure):
        _idle(failure.message);
        return saved;
    }
  }

  void _idle(String? error) {
    state = (
      filter: state.filter,
      visible: state.visible,
      busy: false,
      error: error,
    );
  }
}

/// Filter and download state for [DownloadFeedbackScreen].
final NotifierProvider<DownloadFeedbackController, DownloadFeedbackView>
downloadFeedbackControllerProvider =
    NotifierProvider<DownloadFeedbackController, DownloadFeedbackView>(
      DownloadFeedbackController.new,
    );
