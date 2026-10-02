import 'package:flutter/services.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'cloud_destination.dart';
import 'cloud_request_scope.dart';

const MethodChannel _channel = MethodChannel('com.tapture.app/cloud');

/// Uses a persisted native folder grant, with bounded writes and unpublished
/// cleanup. Plain filesystem paths keep the ordinary local destination.
final class ScopedFolderDestination implements CloudDestination {
  /// Composes platform grants with the existing filesystem [fallback].
  const ScopedFolderDestination({required this.fallback});

  /// Existing local path writer for app-owned and desktop folders.
  final CloudDestination fallback;

  @override
  DestinationKind get kind => DestinationKind.localFolder;

  bool _scoped(Destination destination) =>
      destination.folder.startsWith('content://') ||
      destination.folder.startsWith('tapture-folder:');

  @override
  Future<Result<void>> check(Destination destination) => !_scoped(destination)
      ? fallback.check(destination)
      : Result.captureAsync(() async {
          await _invoke<void>('folderProbe', <String, Object>{
            'folder': destination.folder,
          });
        });

  @override
  Future<Result<Uri>> send(
    Destination destination,
    CloudBytes file, {
    required String remoteName,
    int offset = 0,
    void Function(int sent, int total)? onProgress,
    CancellationToken? cancel,
  }) async {
    if (!_scoped(destination)) {
      return fallback.send(
        destination,
        file,
        remoteName: remoteName,
        offset: offset,
        onProgress: onProgress,
        cancel: cancel,
      );
    }
    String? session;
    var published = false;
    try {
      await _permit(cancel);
      if (remoteName.isEmpty ||
          remoteName.contains('/') ||
          remoteName.contains(r'\') ||
          remoteName == '.' ||
          remoteName == '..') {
        throw ValidationFailure(
          localizedMessage:
              Copy.messages.failureChooseAFilenameWithoutFolderSeparators,
        );
      }
      session = await _invoke<String>('folderBegin', <String, Object>{
        'folder': destination.folder,
        'name': remoteName,
      });
      if (session == null || session.isEmpty) {
        throw StorageFailure(
          localizedMessage: Copy.messages.failureTheFolderCouldNotOpenANew,
        );
      }
      var cursor = 0;
      while (cursor < file.length) {
        await _permit(cancel);
        final int length = (file.length - cursor).clamp(
          0,
          AppConstants.cloudUpload.streamBytes,
        );
        final List<int> bytes = await file.read(cursor, length);
        if (bytes.length != length) throw cloudReadFailure;
        await _permit(cancel);
        await _invoke<void>('folderAppend', <String, Object>{
          'session': session,
          'bytes': Uint8List.fromList(bytes),
        });
        cursor += length;
        _progress(onProgress, cursor, file.length);
      }
      await _permit(cancel);
      final String? target = await _invoke<String>(
        'folderFinish',
        <String, Object>{'session': session},
      );
      if (target == null) {
        throw StorageFailure(
          localizedMessage:
              Copy.messages.failureTheFolderCouldNotPublishTheFile,
        );
      }
      published = true;
      _progress(onProgress, file.length, file.length);
      return Success<Uri>(Uri.parse(target));
    } on Object catch (error) {
      return FailureResult<Uri>(
        cancel?.isCancelled == true
            ? const CancelledFailure()
            : Failure.from(error),
      );
    } finally {
      if (!published && session != null) {
        try {
          await _invoke<void>('folderAbort', <String, Object>{
            'session': session,
          });
        } on Object {
          /* A revoked grant may prevent cleanup; no final file was published. */
        }
      }
    }
  }

  Future<void> _permit(CancellationToken? cancel) async {
    if (cancel?.isCancelled == true) throw const CancelledFailure();
    await CloudRequestScope.current.authorize?.call();
    if (cancel?.isCancelled == true) throw const CancelledFailure();
  }

  Future<T?> _invoke<T>(String method, Map<String, Object> arguments) async {
    try {
      return await _channel
          .invokeMethod<T>(method, arguments)
          .timeout(AppConstants.cloudUpload.requestTimeout);
    } on PlatformException catch (error) {
      if (error.code == 'grant_lost') {
        throw PermissionFailure(
          localizedMessage: Copy.messages.failureAccessToTheChosenFolderWasLost,
          localizedRecovery: Copy.messages.failureChooseTheFolderAgain,
        );
      }
      throw StorageFailure(
        localizedMessage: Copy.messages.failureTheFileCouldNotBeWrittenTo,
        localizedRecovery:
            Copy.messages.failureChooseAnAccessibleFolderAndTryAgain,
      );
    }
  }

  void _progress(void Function(int, int)? observer, int sent, int total) {
    try {
      observer?.call(sent, total);
    } on Object {
      /* Observers cannot undo a completed native write. */
    }
  }
}
