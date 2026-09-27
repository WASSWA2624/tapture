import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/cloud/cloud_destination.dart';
import 'package:tapture/core/cloud/dropbox_destination.dart';
import 'package:tapture/core/cloud/oauth_destination_client.dart';
import 'package:tapture/core/errors/result.dart';

void main() {
  test(
    'the upload carries the resume offset and does not list files',
    () async {
      final List<CloudCall> calls = <CloudCall>[];
      final DropboxDestination dropbox = DropboxDestination(
        client: OauthDestinationClient(
          send: (CloudCall call) async {
            calls.add(call);
            return (
              status: 200,
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
        await dropbox.send(
          (
            id: 'dest',
            kind: DestinationKind.dropbox,
            label: 'Box',
            folder: 'exports',
            credentialRef: 'ref',
            lastCheck: null,
          ),
          (
            length: 10,
            read: (int offset, int length) async {
              expect(offset, 4);
              return List<int>.filled(length, 9);
            },
          ),
          remoteName: 'pack.zip',
          offset: 4,
        ),
        isA<Success<Uri>>(),
      );
      expect(calls.single.url.toString(), contains('upload_session'));
      expect(calls.single.url.toString(), isNot(contains('list_folder')));
      final Object? arg = jsonDecode(calls.single.headers['dropbox-api-arg']!);
      expect(arg, isA<Map<Object?, Object?>>());
      expect('${(arg! as Map)['cursor']}', contains('4'));
      expect(calls.single.body, hasLength(6));
    },
  );
}
