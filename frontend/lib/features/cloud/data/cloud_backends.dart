import 'package:tapture/core/cloud/cloud_destination.dart';
import 'package:tapture/core/cloud/destination_secrets.dart';

import 'cloud_backends_stub.dart'
    if (dart.library.io) 'cloud_backends_io.dart'
    as impl;

/// Builds the destination registry for this platform.
Future<Map<DestinationKind, CloudDestination>> openCloudBackends(
  DestinationSecrets secrets,
) {
  return impl.openCloudBackends(secrets);
}
