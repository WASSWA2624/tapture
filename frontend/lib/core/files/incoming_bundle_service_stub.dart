import 'package:tapture/core/errors/result.dart';

import 'incoming_bundle_service.dart';
import 'picked_document.dart';

/// Unsupported hosts do not invent an operating-system delivery mechanism.
IncomingBundleService platformIncomingBundleService() => const _EmptyIncoming();

/// No native channel is available in a browser.
IncomingBundleService channelIncomingBundleService() => const _EmptyIncoming();

final class _EmptyIncoming implements IncomingBundleService {
  const _EmptyIncoming();

  @override
  Stream<Result<PickedDocument>> watch() =>
      const Stream<Result<PickedDocument>>.empty();

  @override
  Future<void> dispose() async {}
}
