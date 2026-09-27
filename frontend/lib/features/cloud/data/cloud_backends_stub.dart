import 'package:tapture/core/cloud/cloud_destination.dart';
import 'package:tapture/core/cloud/destination_secrets.dart';

/// Web stand-in. The device builds the real registry.
Future<Map<DestinationKind, CloudDestination>> openCloudBackends(
  DestinationSecrets secrets,
) async {
  await secrets.read('');
  return <DestinationKind, CloudDestination>{};
}
