import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which destination the upload history lists: its id, or null for every
/// destination (task 021 step 6).
final class UploadHistoryController extends Notifier<String?> {
  @override
  String? build() => null;

  /// Lists only [destinationId]'s attempts; null or empty lists them all.
  void filterBy(String? destinationId) {
    state = destinationId == null || destinationId.isEmpty
        ? null
        : destinationId;
  }
}

/// The history page's filter.
final NotifierProvider<UploadHistoryController, String?>
uploadHistoryControllerProvider =
    NotifierProvider.autoDispose<UploadHistoryController, String?>(
      UploadHistoryController.new,
    );
