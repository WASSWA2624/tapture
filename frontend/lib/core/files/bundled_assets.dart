import 'package:flutter/foundation.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/result.dart';

import 'bundled_assets_stub.dart'
    if (dart.library.io) 'bundled_assets_io.dart'
    as implementation;

/// How many leading hex characters of an asset's SHA-256 key an extracted
/// copy, so a changed asset is extracted afresh beside the stale one.
const int _shaPrefixLength = 12;

/// Where the Flutter asset [key] is readable as a file on [platform], or
/// null when that platform keeps no asset as a file.
///
/// Windows and Linux read `<exe folder>/data/flutter_assets/<key>` in place;
/// macOS and iOS read inside `App.framework`. Android keeps its assets in the
/// APK, so the file is an extracted copy at
/// `<extractTo>/<first 12 of sha256>-<file name>`. [executable] is the
/// running executable's absolute path and [extractTo] an absolute folder
/// under the private root. Pure, so every platform is tested anywhere.
String? bundledAssetPath({
  required TargetPlatform platform,
  required String executable,
  required String key,
  required String sha256,
  required String extractTo,
}) {
  final bool windows = platform == TargetPlatform.windows;
  final String separator = windows ? r'\' : '/';
  final String exeDir = _parentOf(executable, windows: windows);
  final String keyPath = key.split('/').join(separator);
  switch (platform) {
    case TargetPlatform.windows:
    case TargetPlatform.linux:
      return '$exeDir${separator}data${separator}flutter_assets'
          '$separator$keyPath';
    case TargetPlatform.macOS:
      return '${_parentOf(exeDir, windows: false)}/Frameworks/App.framework/'
          'Resources/flutter_assets/$keyPath';
    case TargetPlatform.iOS:
      return '$exeDir/Frameworks/App.framework/flutter_assets/$keyPath';
    case TargetPlatform.android:
      return '$extractTo/${bundledCopyName(key: key, sha256: sha256)}';
    case TargetPlatform.fuchsia:
      return null;
  }
}

/// The file name of an extracted copy of [key]: [sha256]'s first 12 hex
/// characters, a hyphen and the asset's own file name.
String bundledCopyName({required String key, required String sha256}) {
  final String prefix = sha256.length < _shaPrefixLength
      ? sha256
      : sha256.substring(0, _shaPrefixLength);
  return '$prefix-${key.split('/').last}';
}

String _parentOf(String path, {required bool windows}) {
  final int slash = windows
      ? path.lastIndexOf(RegExp(r'[\\/]'))
      : path.lastIndexOf('/');
  return slash <= 0 ? path : path.substring(0, slash);
}

/// Turns a bundled Flutter asset into a readable file without loading it
/// into memory (FE-PERF-07): never `rootBundle.load` for a large asset.
///
/// Desktop and Apple builds read the asset in place. Android streams it
/// once out of the APK through the files channel into a folder the caller
/// owns under the private root. A browser has no files and reports none.
abstract interface class BundledAssets {
  /// The assets of this build. [platform] and [executable] are test seams
  /// for the running platform and executable path.
  factory BundledAssets.platform({
    @visibleForTesting TargetPlatform? platform,
    @visibleForTesting String? executable,
  }) => implementation.openBundledAssets(
    targetPlatform: platform,
    executable: executable,
  );

  /// A stand-in that reports [paths] by asset key; a missing key is an
  /// asset this build does not contain.
  const factory BundledAssets.fake(Map<String, String?> paths) =
      _FakeBundledAssets;

  /// The readable path of the asset [assetKey] whose content has [sha256],
  /// or null when this build does not contain it, which is the case for a
  /// development build without models.
  ///
  /// On Android the first call extracts a copy into [extractTo], an
  /// absolute folder; later calls find it there. Extraction of the same copy
  /// is never run twice at once. A full disk or an input-output error is a
  /// `StorageFailure`; [cancel] is honoured before and after extraction.
  Future<Result<String?>> pathOf(
    String assetKey, {
    required String sha256,
    required String extractTo,
    CancellationToken? cancel,
  });
}

final class _FakeBundledAssets implements BundledAssets {
  const _FakeBundledAssets(this._paths);

  final Map<String, String?> _paths;

  @override
  Future<Result<String?>> pathOf(
    String assetKey, {
    required String sha256,
    required String extractTo,
    CancellationToken? cancel,
  }) async => Success<String?>(_paths[assetKey]);
}
