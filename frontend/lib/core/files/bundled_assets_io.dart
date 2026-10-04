import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/blob_store.dart' show storeFailure;

import 'bundled_assets.dart';

/// The native files channel. On Android it streams an asset out of the APK.
const MethodChannel _filesChannel = MethodChannel('com.tapture.app/files');

/// The assets of this build on a device.
BundledAssets openBundledAssets({
  TargetPlatform? targetPlatform,
  String? executable,
}) => _IoBundledAssets(
  platform: targetPlatform ?? defaultTargetPlatform,
  executable: executable ?? Platform.resolvedExecutable,
);

final class _IoBundledAssets implements BundledAssets {
  _IoBundledAssets({required this._platform, required this._executable});

  final TargetPlatform _platform;
  final String _executable;

  /// Extractions in flight by target path, so one copy is never written
  /// twice at once.
  final Map<String, Future<Result<String?>>> _extracting =
      <String, Future<Result<String?>>>{};

  @override
  Future<Result<String?>> pathOf(
    String assetKey, {
    required String sha256,
    required String extractTo,
    CancellationToken? cancel,
  }) async {
    if (cancel?.isCancelled ?? false) {
      return const FailureResult<String?>(CancelledFailure());
    }
    final String? path = bundledAssetPath(
      platform: _platform,
      executable: _executable,
      key: assetKey,
      sha256: sha256,
      extractTo: extractTo,
    );
    if (path == null) {
      return const Success<String?>(null);
    }
    if (await File(path).exists()) {
      return Success<String?>(path);
    }
    if (_platform != TargetPlatform.android) {
      return const Success<String?>(null);
    }
    final Result<String?> extracted = await (_extracting[path] ??=
        _extract(assetKey, path).whenComplete(() {
          _extracting.remove(path);
        }));
    if (cancel?.isCancelled ?? false) {
      return const FailureResult<String?>(CancelledFailure());
    }
    return extracted;
  }

  /// Streams [assetKey] into [path] on the native side: `<path>.part`,
  /// fsync, rename. `missing` means the build lacks the asset.
  Future<Result<String?>> _extract(String assetKey, String path) async {
    try {
      await File(path).parent.create(recursive: true);
      await _filesChannel.invokeMethod<Object>(
        'extractFlutterAsset',
        <String, Object>{'asset': assetKey, 'path': path},
      );
      return Success<String?>(path);
    } on PlatformException catch (error) {
      if (error.code == 'missing') {
        return const Success<String?>(null);
      }
      return FailureResult<String?>(storeFailure());
    } on MissingPluginException {
      return const Success<String?>(null);
    } on FileSystemException {
      return FailureResult<String?>(storeFailure());
    }
  }
}
