import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/logging/logger.dart';

import 'env.dart';

/// The type this file is named for (FE-STR-06). The contract name is
/// [AppProviderObserver].
typedef ProviderObserver = AppProviderObserver;

/// Feeds provider failures and noisy rebuilds into [Logger] in development.
final class AppProviderObserver extends riverpod.ProviderObserver {
  /// Creates an observer that writes through [logger].
  AppProviderObserver(this.logger);

  /// The logger that receives provider events.
  final Logger logger;

  final Map<String, int> _rebuilds = <String, int>{};

  @override
  void providerDidFail(
    riverpod.ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    if (!Env.isDev) {
      return;
    }
    final String providerName = context.provider.name ?? 'unnamed';
    logger.error(
      'providers',
      'provider $providerName failed $stackTrace',
      error: error,
    );
  }

  @override
  void didUpdateProvider(
    riverpod.ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    if (!Env.isDev) {
      return;
    }
    final String providerName = context.provider.name ?? 'unnamed';
    final int count = (_rebuilds[providerName] ?? 0) + 1;
    _rebuilds[providerName] = count;
    if (count != AppConstants.logging.rebuildThreshold + 1) {
      return;
    }
    logger.warn('providers', 'provider $providerName rebuilt $count times');
  }
}
