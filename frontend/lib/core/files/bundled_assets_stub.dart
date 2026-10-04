import 'package:flutter/foundation.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/result.dart';

import 'bundled_assets.dart';

/// A browser keeps no asset as a file, so it reports none; the web engine
/// reads assets by URL instead.
BundledAssets openBundledAssets({
  TargetPlatform? targetPlatform,
  String? executable,
}) => const _NoFileAssets();

final class _NoFileAssets implements BundledAssets {
  const _NoFileAssets();

  @override
  Future<Result<String?>> pathOf(
    String assetKey, {
    required String sha256,
    required String extractTo,
    CancellationToken? cancel,
  }) async => const Success<String?>(null);
}
