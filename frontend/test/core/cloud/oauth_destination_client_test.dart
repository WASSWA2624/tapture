import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/cloud/cloud_destination.dart';
import 'package:tapture/core/cloud/dropbox_destination.dart';
import 'package:tapture/core/cloud/google_drive_destination.dart';
import 'package:tapture/core/cloud/oauth_destination_client.dart';
import 'package:tapture/core/cloud/onedrive_destination.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

void main() {
  test('each provider asks only for the folder it can write', () {
    expect(
      GoogleDriveDestination.scope,
      'https://www.googleapis.com/auth/drive.file',
    );
    expect(GoogleDriveDestination.scope.contains('drive.readonly'), isFalse);
    expect(
      OnedriveDestination.scope,
      'Files.ReadWrite.AppFolder offline_access',
    );
    expect(OnedriveDestination.scope.contains('Files.Read.All'), isFalse);
    expect(OnedriveDestination.scope.contains('Files.ReadWrite '), isFalse);
    expect(DropboxDestination.scope, 'files.content.write');
    expect(DropboxDestination.scope.contains('files.metadata.read'), isFalse);
  });

  test(
    'a 401 refreshes once and retries, and a failed refresh keeps the destination',
    () async {
      final Map<String, String> access = <String, String>{'ref': 'old'};
      final Map<String, String> refresh = <String, String>{'ref': 'keep-me'};
      var refreshed = false;
      final OauthDestinationClient client = OauthDestinationClient(
        scheme: 'app',
        clientId: 'client',
        readAccess: (String ref) async => access[ref],
        writeAccess: (String ref, String token) async {
          access[ref] = token;
        },
        readRefresh: (String ref) async => refresh[ref],
        writeRefresh: (String ref, String token) async {
          refresh[ref] = token;
        },
        send: (CloudCall call) async {
          if (call.url == GoogleDriveDestination.oauth.token) {
            refreshed = true;
            return (
              status: 200,
              headers: const <String, String>{},
              body: utf8.encode(
                '{"access_token":"new","refresh_token":"next"}',
              ),
            );
          }
          if (call.headers['authorization'] == 'Bearer old') {
            return (
              status: 401,
              headers: const <String, String>{},
              body: const <int>[],
            );
          }
          return (
            status: 200,
            headers: const <String, String>{},
            body: utf8.encode('{"ok":true}'),
          );
        },
      );
      final Result<CloudReply> sent = await client.sendAuthorized(
        provider: GoogleDriveDestination.oauth,
        credentialRef: 'ref',
        call: (
          method: 'GET',
          url: Uri.parse('https://www.googleapis.com/drive/v3/files/probe'),
          headers: const <String, String>{},
          body: const <int>[],
        ),
      );
      expect(sent, isA<Success<CloudReply>>());
      expect(refreshed, isTrue);
      expect(access['ref'], 'new');

      access['ref'] = 'old';
      refresh['ref'] = 'keep-me';
      final OauthDestinationClient revoked = OauthDestinationClient(
        scheme: 'app',
        clientId: 'client',
        readAccess: (String ref) async => access[ref],
        writeAccess: (String ref, String token) async {
          access[ref] = token;
        },
        readRefresh: (String ref) async => refresh[ref],
        writeRefresh: (String _, String _) async {},
        send: (CloudCall call) async {
          if (call.url == GoogleDriveDestination.oauth.token) {
            return (
              status: 400,
              headers: const <String, String>{},
              body: const <int>[],
            );
          }
          return (
            status: 401,
            headers: const <String, String>{},
            body: const <int>[],
          );
        },
      );
      final Result<CloudReply> failed = await revoked.sendAuthorized(
        provider: GoogleDriveDestination.oauth,
        credentialRef: 'ref',
        call: (
          method: 'GET',
          url: Uri.parse('https://www.googleapis.com/drive/v3/files/probe'),
          headers: const <String, String>{},
          body: const <int>[],
        ),
      );
      expect(failed, isA<FailureResult<CloudReply>>());
      expect(
        (failed as FailureResult<CloudReply>).failure,
        isA<PermissionFailure>(),
      );
      expect(refresh['ref'], 'keep-me');
      expect(
        (failed.failure as PermissionFailure).message,
        contains('Sign in'),
      );
    },
  );
}
