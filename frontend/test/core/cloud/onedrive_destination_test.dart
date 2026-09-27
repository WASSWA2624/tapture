import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/cloud/cloud_destination.dart';
import 'package:tapture/core/cloud/oauth_destination_client.dart';
import 'package:tapture/core/cloud/onedrive_destination.dart';
import 'package:tapture/core/errors/result.dart';

void main() {
  test('uploads stay in the app folder', () async {
    final List<CloudCall> calls = <CloudCall>[];
    final OnedriveDestination drive = OnedriveDestination(
      client: OauthDestinationClient(
        send: (CloudCall call) async {
          calls.add(call);
          if (call.url.toString().contains('createUploadSession')) {
            return (
              status: 200,
              headers: const <String, String>{},
              body: utf8.encode('{"uploadUrl":"https://upload.example/one"}'),
            );
          }
          return (
            status: 201,
            headers: const <String, String>{},
            body: const <int>[],
          );
        },
        scheme: 'app',
        clientId: 'client',
        readAccess: (_) async => 'token',
        writeAccess: (String _, String _) async {},
        readRefresh: (_) async => 'refresh',
        writeRefresh: (String _, String _) async {},
      ),
    );
    expect(
      await drive.send(
        (
          id: 'dest',
          kind: DestinationKind.oneDrive,
          label: 'One',
          folder: 'minutes',
          credentialRef: 'ref',
          lastCheck: null,
        ),
        (
          length: 2,
          read: (int _, int length) async => List<int>.filled(length, 1),
        ),
        remoteName: 'notes.txt',
      ),
      isA<Success<Uri>>(),
    );
    expect(
      calls.first.url.toString(),
      contains('/drive/special/approot:/minutes/notes.txt'),
    );
    expect(calls.first.url.toString(), isNot(contains('/drive/root')));
    expect(calls.last.headers['content-range'], 'bytes 0-1/2');
  });
}
