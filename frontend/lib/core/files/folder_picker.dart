import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'folder_picker_stub.dart'
    if (dart.library.io) 'folder_picker_io.dart'
    if (dart.library.js_interop) 'folder_picker_web.dart'
    as platform;

/// Picks a directory for the storage root. The files channel and desktop
/// folder dialogs are reached only here (FE-STR-11). Tests use
/// [FolderPicker.fake].
abstract interface class FolderPicker {
  /// The platform picker. Web cannot hold an app-chosen documents folder.
  factory FolderPicker() => platform.platformFolderPicker();

  /// A folder intended for bounded native grant writes rather than a Dart root.
  factory FolderPicker.destination() =>
      platform.platformDestinationFolderPicker();

  /// A stand-in that returns [path], or [failure], or a cancel.
  const factory FolderPicker.fake({
    String? path,
    Failure? failure,
    bool canPick,
    bool cancel,
  }) = _FakeFolderPicker;

  /// Whether this platform can offer a folder picker.
  bool get canPick;

  /// A directory path, empty on cancel, or a failure.
  Future<Result<String?>> pick();
}

/// The process-wide [FolderPicker].
final Provider<FolderPicker> folderPickerProvider = Provider<FolderPicker>((_) {
  return FolderPicker();
});

/// The picker for a cloud/local destination, retaining platform access grants.
final Provider<FolderPicker> destinationFolderPickerProvider =
    Provider<FolderPicker>((_) => FolderPicker.destination());

final class _FakeFolderPicker implements FolderPicker {
  const _FakeFolderPicker({
    this.path,
    this.failure,
    this.canPick = true,
    this.cancel = false,
  });

  final String? path;
  final Failure? failure;
  final bool cancel;

  @override
  final bool canPick;

  @override
  Future<Result<String?>> pick() async {
    if (!canPick) {
      return FailureResult<String?>(
        ProviderFailure(
          localizedMessage: Copy.messages.settingsStorageRoot,
          localizedRecovery: Copy.messages.tryAgain,
        ),
      );
    }
    final Failure? failure = this.failure;
    if (failure != null) {
      return FailureResult<String?>(failure);
    }
    if (cancel) {
      return const FailureResult<String?>(CancelledFailure());
    }
    return Success<String?>(path);
  }
}
