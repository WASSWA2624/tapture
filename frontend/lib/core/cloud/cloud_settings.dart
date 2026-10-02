import 'package:tapture/core/errors/result.dart';

import 'cloud_destination.dart';
import 'oauth_destination_client.dart';

/// What a backend needs besides credentials: the configured storage root a
/// relative device folder resolves under, and each consumer provider's
/// OAuth client id. Plain values, so a worker isolate can rebuild a backend
/// from them.
typedef CloudSettings = ({
  String rootPath,
  Map<DestinationKind, String> clientIds,
});

/// The shared authorisation client and the endpoints of one provider.
typedef CloudOauth = ({OauthDestinationClient client, OauthProvider provider});

/// Opens the platform browser at [authorize] and completes with the address
/// the provider redirected back to, which starts with [redirect].
typedef CloudSignIn = Future<Result<Uri>> Function(Uri authorize, Uri redirect);

/// OAuth client ids given at build time (`--dart-define`). A provider with
/// no id is never offered on the add form.
const Map<DestinationKind, String> cloudClientIds = <DestinationKind, String>{
  DestinationKind.googleDrive: String.fromEnvironment('GOOGLE_DRIVE_CLIENT_ID'),
  DestinationKind.oneDrive: String.fromEnvironment('ONEDRIVE_CLIENT_ID'),
  DestinationKind.dropbox: String.fromEnvironment('DROPBOX_CLIENT_ID'),
};

/// Google's registered web client ID for the Android native identity SDK.
const String googleServerClientId = String.fromEnvironment(
  'GOOGLE_DRIVE_SERVER_CLIENT_ID',
);

/// Explicit registered desktop loopback callbacks; absent values hide sign-in.
/// Google Desktop clients may use port 0 to request an ephemeral listener.
const Map<DestinationKind, String> cloudRedirectUris =
    <DestinationKind, String>{
      DestinationKind.googleDrive: String.fromEnvironment(
        'GOOGLE_DRIVE_REDIRECT_URI',
      ),
      DestinationKind.oneDrive: String.fromEnvironment('ONEDRIVE_REDIRECT_URI'),
      DestinationKind.dropbox: String.fromEnvironment('DROPBOX_REDIRECT_URI'),
    };
