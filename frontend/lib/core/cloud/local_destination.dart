import 'dart:io';

import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'cloud_destination.dart';
import 'cloud_probe_name.dart';

/// A folder on this device or on removable storage.
///
/// A relative [Destination.folder] resolves under [rootPath], the configured
/// storage root. An absolute one is a folder the person picked — an SD card
/// or USB drive — whose access the platform picker granted and kept; it is
/// used as given. Bytes are written to a temporary name and renamed only
/// when the copy finishes, so a cancel or a failure leaves no partial file.
/// A resend always starts again from byte 0. This backend makes no network
/// call.
final class LocalDestination implements CloudDestination {
  /// Creates the backend rooted at [rootPath].
  LocalDestination({required this.rootPath, int? partBytes})
    : _partBytes = partBytes ?? AppConstants.cloudUpload.partBytes;

  /// Storage root. Relative folders resolve under this directory.
  final String rootPath;
  final int _partBytes;

  @override
  DestinationKind get kind => DestinationKind.localFolder;

  @override
  Future<Result<void>> check(Destination destination) async {
    final Result<File> target = _target(destination, CloudProbeName.create());
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
      return FailureResult<void>(
        PermissionFailure(
          localizedMessage: Copy.messages.failureThatFolderCannotBeWritten,
          localizedRecovery: Copy.messages.failureChooseTheFolderAgain,
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
    final File partial = File(
      '${finished.path}.${CloudProbeName.create()}.partial',
    );
    RandomAccessFile? handle;
    try {
      await finished.parent.create(recursive: true);
      final RandomAccessFile writer = await partial.open(mode: FileMode.write);
      handle = writer;
      var cursor = 0;
      while (cursor < file.length) {
        if (cancel?.isCancelled ?? false) {
          handle = null;
          await writer.close();
          await _deleteQuiet(partial);
          return const FailureResult<Uri>(CancelledFailure());
        }
        final int count = _partBytes < file.length - cursor
            ? _partBytes
            : file.length - cursor;
        final List<int> chunk = await file.read(cursor, count);
        if (chunk.length != count) {
          handle = null;
          await writer.close();
          await _deleteQuiet(partial);
          return FailureResult<Uri>(cloudReadFailure);
        }
        if (cancel?.isCancelled ?? false) {
          handle = null;
          await writer.close();
          await _deleteQuiet(partial);
          return const FailureResult<Uri>(CancelledFailure());
        }
        await writer.writeFrom(chunk);
        cursor += chunk.length;
        onProgress?.call(cursor, file.length);
      }
      handle = null;
      await writer.close();
      if (cancel?.isCancelled ?? false) {
        await _deleteQuiet(partial);
        return const FailureResult<Uri>(CancelledFailure());
      }
      await partial.rename(finished.path);
      onProgress?.call(file.length, file.length);
      return Success<Uri>(finished.uri);
    } on Object {
      await handle?.close();
      await _deleteQuiet(partial);
      return FailureResult<Uri>(
        StorageFailure(
          localizedMessage: Copy.messages.failureTheFileCouldNotBeWrittenTo,
          localizedRecovery:
              Copy.messages.failureFreeSomeSpaceOrChooseTheFolder,
        ),
      );
    }
  }

  Result<File> _target(Destination destination, String name) {
    final String folder = destination.folder.trim();
    if (folder.startsWith('content:') ||
        folder.startsWith('file:') ||
        folder.startsWith('/tree/')) {
      return FailureResult<File>(
        PermissionFailure(
          localizedMessage:
              Copy.messages.failureThisFolderRequiresASupportedSystemFolder,
          localizedRecovery:
              Copy.messages.failureChooseAnAccessibleFolderOrAnotherDestination,
        ),
      );
    }
    if (folder.split(RegExp(r'[\\/]')).contains('..') ||
        name.isEmpty ||
        name.contains('..') ||
        name.contains('/') ||
        name.contains(r'\')) {
      return FailureResult<File>(
        ValidationFailure(
          localizedMessage: Copy.messages.failureThatFolderPathIsNotUsable,
          localizedRecovery: Copy.messages.failureChooseTheFolderAgain,
        ),
      );
    }
    final String sep = Platform.pathSeparator;
    if (folder.isNotEmpty && Directory(folder).isAbsolute) {
      return Success<File>(File('${_trim(folder)}$sep$name'));
    }
    final String root = _trim(rootPath);
    if (root.isEmpty) {
      return FailureResult<File>(
        StorageFailure(
          localizedMessage: Copy.messages.failureTheTaptureFolderOnThisDeviceIs,
          localizedRecovery:
              Copy.messages.failureCheckTheStorageLocationInSettings,
        ),
      );
    }
    final String directory = folder.isEmpty ? root : '$root$sep$folder';
    return Success<File>(File('$directory$sep$name'));
  }

  String _trim(String value) {
    var trimmed = value;
    while (trimmed.length > 1 &&
        (trimmed.endsWith('/') || trimmed.endsWith(r'\'))) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  Future<void> _deleteQuiet(File file) async {
    if (file.existsSync()) {
      await file.delete();
    }
  }
}
