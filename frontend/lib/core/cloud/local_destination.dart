import 'dart:io';

import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'cloud_destination.dart';

/// A folder on this device or on removable storage.
///
/// Paths resolve under [rootPath], the storage root. Bytes are written to a
/// temporary name and renamed only when the copy finishes, so a cancel or a
/// failure leaves no partial file. This backend makes no network call.
final class LocalDestination implements CloudDestination {
  /// Creates the backend rooted at [rootPath].
  LocalDestination({required this.rootPath, int? partBytes})
    : _partBytes = partBytes ?? AppConstants.cloudUpload.partBytes;

  /// Storage root. Folder paths are resolved under this directory.
  final String rootPath;
  final int _partBytes;

  @override
  DestinationKind get kind => DestinationKind.localFolder;

  @override
  Future<Result<void>> check(Destination destination) async {
    final Result<File> target = _target(destination, '.tapture-check');
    if (target is FailureResult<File>) {
      return FailureResult<void>(target.failure);
    }
    final File file = (target as Success<File>).value;
    final File partial = File('${file.path}.partial');
    try {
      await file.parent.create(recursive: true);
      await partial.writeAsString('ok');
      if (file.existsSync()) {
        await file.delete();
      }
      await partial.rename(file.path);
      await file.delete();
      return const Success<void>(null);
    } on Object {
      await _deleteQuiet(partial);
      await _deleteQuiet(file);
      return const FailureResult<void>(
        PermissionFailure(
          message: 'That folder cannot be written.',
          recoveryAction: 'Choose the folder again.',
        ),
      );
    }
  }

  @override
  Future<Result<Uri>> send(
    Destination destination,
    CloudBytes file, {
    required String remoteName,
    int offset = 0,
    void Function(int sent, int total)? onProgress,
    CancellationToken? cancel,
  }) async {
    if (cancel?.isCancelled ?? false) {
      return const FailureResult<Uri>(CancelledFailure());
    }
    final Result<File> target = _target(destination, remoteName);
    if (target is FailureResult<File>) {
      return FailureResult<Uri>(target.failure);
    }
    final File finished = (target as Success<File>).value;
    final File partial = File('${finished.path}.partial');
    RandomAccessFile? handle;
    try {
      await finished.parent.create(recursive: true);
      handle = await partial.open(mode: FileMode.write);
      var cursor = offset.clamp(0, file.length);
      while (cursor < file.length) {
        if (cancel?.isCancelled ?? false) {
          await handle!.close();
          handle = null;
          await _deleteQuiet(partial);
          return const FailureResult<Uri>(CancelledFailure());
        }
        final int count = _partBytes < file.length - cursor
            ? _partBytes
            : file.length - cursor;
        final List<int> chunk = await file.read(cursor, count);
        await handle!.writeFrom(chunk);
        cursor += chunk.length;
      }
      await handle!.close();
      handle = null;
      if (finished.existsSync()) {
        await finished.delete();
      }
      await partial.rename(finished.path);
      onProgress?.call(file.length, file.length);
      return Success<Uri>(finished.uri);
    } on Object {
      await handle?.close();
      await _deleteQuiet(partial);
      return const FailureResult<Uri>(
        StorageFailure(
          message: 'The file could not be written to that folder.',
          recoveryAction: 'Free some space or choose the folder again.',
        ),
      );
    }
  }

  Result<File> _target(Destination destination, String name) {
    if (destination.folder.contains('..') ||
        name.contains('..') ||
        name.contains('/') ||
        name.contains(r'\')) {
      return const FailureResult<File>(
        ValidationFailure(
          message: 'That folder path is not usable.',
          recoveryAction: 'Choose the folder again.',
        ),
      );
    }
    final String root = _trim(rootPath);
    final String folder = destination.folder.isEmpty
        ? root
        : '$root${Platform.pathSeparator}${destination.folder}';
    if (folder != root &&
        !folder.startsWith('$root${Platform.pathSeparator}')) {
      return const FailureResult<File>(
        ValidationFailure(
          message: 'That folder is outside this device store.',
          recoveryAction: 'Choose a folder inside the store.',
        ),
      );
    }
    return Success<File>(File('$folder${Platform.pathSeparator}$name'));
  }

  String _trim(String value) {
    final String sep = Platform.pathSeparator;
    if (value.endsWith(sep) && value.length > sep.length) {
      return value.substring(0, value.length - sep.length);
    }
    return value;
  }

  Future<void> _deleteQuiet(File file) async {
    if (file.existsSync()) {
      await file.delete();
    }
  }
}
