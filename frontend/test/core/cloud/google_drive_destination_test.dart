import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/cloud/cloud_destination.dart';
import 'package:tapture/core/cloud/google_drive_destination.dart';
import 'package:tapture/core/cloud/oauth_destination_client.dart';
import 'package:tapture/core/errors/result.dart';

void main() {
  test(
    'a resumed upload starts at the offset and does not list Drive',
    () async {
      final List<CloudCall> calls = <CloudCall>[];
      final GoogleDriveDestination drive = GoogleDriveDestination(
        client: _client((CloudCall call) async {
          calls.add(call);
          if (call.method == 'POST') {
            return (
              status: 200,
              headers: const <String, String>{
                'location': 'https://upload.example/session',
              },
              body: const <int>[],
            );
          }
          return (
            status: 200,
            headers: const <String, String>{},
            body: utf8.encode('{"id":"file-1"}'),
          );
        }),
      );
      final Result<Uri> sent = await drive.send(
        _destination,
        (
          length: 10,
          read: (int offset, int length) async {
            expect(offset, 4);
            expect(length, 6);
            return List<int>.filled(length, 3);
          },
        ),
        remoteName: 'sheet.xlsx',
        offset: 4,
      );
      expect(sent, isA<Success<Uri>>());
      expect(calls.first.url.toString(), contains('uploadType=resumable'));
      expect(calls.first.url.toString(), isNot(contains('files.list')));
      expect(utf8.decode(calls.first.body), contains('sheet.xlsx'));
      expect(calls.last.headers['content-range'], 'bytes 4-9/10');
      expect(calls.last.body, hasLength(6));
    },
  );
}

const Destination _destination = (
  id: 'dest',
  kind: DestinationKind.googleDrive,
  label: 'Drive',
  folder: 'folder-1',
  credentialRef: 'ref',
  lastCheck: null,
);

OauthDestinationClient _client(CloudSend send) {
  return OauthDestinationClient(
    send: send,
    scheme: 'app',
    clientId: 'client',
    readAccess: (_) async => 'token',
    writeAccess: (String _, String _) async {},
    readRefresh: (_) async => 'refresh',
    writeRefresh: (String _, String _) async {},
  );
}
