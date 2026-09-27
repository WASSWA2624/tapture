import 'dart:io';

import 'package:tapture/core/cloud/cloud_destination.dart';
import 'package:tapture/core/cloud/destination_secrets.dart';
import 'package:tapture/core/cloud/dropbox_destination.dart';
import 'package:tapture/core/cloud/google_drive_destination.dart';
import 'package:tapture/core/cloud/local_destination.dart';
import 'package:tapture/core/cloud/oauth_destination_client.dart';
import 'package:tapture/core/cloud/onedrive_destination.dart';
import 'package:tapture/core/cloud/s3_destination.dart';
import 'package:tapture/core/cloud/webdav_destination.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/storage_root.dart';

import 'cloud_transport_io.dart';

/// Scheme registered in the Android manifest and the Apple URL types.
const String _scheme = 'tapture';

/// The six backends, resolved by kind. Credentials are read on each call.
Future<Map<DestinationKind, CloudDestination>> openCloudBackends(
  DestinationSecrets secrets,
) async {
  final Result<Directory> root = await StorageRoot().resolve();
  final String rootPath = root.fold(
    (_) => '',
    (Directory directory) => directory.path,
  );
  final OauthDestinationClient oauth = OauthDestinationClient(
    send: sendCloud,
    scheme: _scheme,
    clientId: _scheme,
    readAccess: (String ref) => _text(secrets.read(ref)),
    writeAccess: (String ref, String token) async {
      await secrets.put(ref, token);
    },
    readRefresh: (String ref) => _text(secrets.readRefresh(ref)),
    writeRefresh: (String ref, String token) async {
      await secrets.putRefresh(ref, token);
    },
  );
  Future<String?> readSecret(String ref) {
    return _text(secrets.read(ref));
  }
  return <DestinationKind, CloudDestination>{
    DestinationKind.s3: S3Destination(
      transport: sendCloud,
      readSecret: readSecret,
    ),
    DestinationKind.webdav: WebdavDestination(
      transport: sendCloud,
      readSecret: readSecret,
    ),
    DestinationKind.localFolder: LocalDestination(rootPath: rootPath),
    DestinationKind.googleDrive: GoogleDriveDestination(client: oauth),
    DestinationKind.oneDrive: OnedriveDestination(client: oauth),
    DestinationKind.dropbox: DropboxDestination(client: oauth),
  };
}

Future<String?> _text(Future<Result<String?>> result) async {
  final Result<String?> value = await result;
  return value.fold((_) => null, (String? stored) => stored);
}
