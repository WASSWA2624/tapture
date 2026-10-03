import 'package:tapture/core/cloud/cloud_destination.dart';
import 'package:tapture/core/cloud/cloud_operation_policy.dart';
import 'package:tapture/core/cloud/cloud_settings.dart';
import 'package:tapture/core/cloud/destination_secrets.dart';

/// Web stand-in: a browser keeps no destination, so none is registered and
/// the destinations page says uploads are sent from a device.
Future<Map<DestinationKind, CloudDestination>> openCloudBackends(
  DestinationSecrets secrets, {
  required CloudSettings settings,
  CloudOperationPolicy policy = const CloudOperationPolicy.unrestricted(),
}) async {
  return <DestinationKind, CloudDestination>{};
}

/// Web stand-in: no provider sign-in is offered in a browser.
CloudOauth? openCloudOauth(
  DestinationKind kind,
  DestinationSecrets secrets, {
  required CloudSettings settings,
  Map<DestinationKind, String>? redirects,
}) {
  return null;
}
