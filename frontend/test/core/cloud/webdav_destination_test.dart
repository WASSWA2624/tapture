import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/cloud/cloud_destination.dart';
import 'package:tapture/core/cloud/webdav_destination.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

void main() {
  const Destination destination = (
    id: 'dest',
    kind: DestinationKind.webdav,
    label: 'Dav',
    folder: 'inbox',
    credentialRef: 'ref',
    lastCheck: null,
  );

  test(
    'basic and bearer headers are sent, and a foreign redirect fails',
    () async {
      final List<String> authorizations = <String>[];
      final WebdavDestination basic = WebdavDestination(
        readSecret: (_) async => jsonEncode(<String, String>{
          'baseUrl': 'https://dav.example/files/',
          'username': 'ada',
          'password': 'secret',
        }),
        transport: (CloudCall call) async {
          authorizations.add(call.headers['authorization'] ?? '');
          return (
            status: 201,
            headers: const <String, String>{},
            body: const <int>[],
          );
        },
      );
      expect(await basic.check(destination), isA<Success<void>>());
      expect(
        authorizations.first,
        'Basic ${base64Encode(utf8.encode('ada:secret'))}',
      );

      final WebdavDestination bearer = WebdavDestination(
        readSecret: (_) async => jsonEncode(<String, String>{
          'baseUrl': 'https://dav.example/files/',
          'bearer': 'token-1',
        }),
        transport: (CloudCall call) async {
          authorizations.add(call.headers['authorization'] ?? '');
          return (
            status: 201,
            headers: const <String, String>{},
            body: const <int>[],
          );
        },
      );
      expect(
        await bearer.send(destination, (
          length: 1,
          read: (int _, int _) async => <int>[1],
        ), remoteName: 'a.txt'),
        isA<Success<Uri>>(),
      );
      expect(authorizations.last, 'Bearer token-1');

      final WebdavDestination redirected = WebdavDestination(
        readSecret: (_) async => jsonEncode(<String, String>{
          'baseUrl': 'https://dav.example/files/',
          'bearer': 'token-1',
        }),
        transport: (CloudCall _) async {
          return (
            status: 302,
            headers: const <String, String>{
              'location': 'https://evil.example/a.txt',
            },
            body: const <int>[],
          );
        },
      );
      final Result<Uri> moved = await redirected.send(destination, (
        length: 1,
        read: (int _, int _) async => <int>[1],
      ), remoteName: 'a.txt');
      expect(moved, isA<FailureResult<Uri>>());
      expect((moved as FailureResult<Uri>).failure, isA<ValidationFailure>());
    },
  );

  test('a missing collection is created before the put', () async {
    final List<String> methods = <String>[];
    final WebdavDestination dav = WebdavDestination(
      readSecret: (_) async => jsonEncode(<String, String>{
        'baseUrl': 'https://dav.example/files/',
        'bearer': 'token-1',
      }),
      transport: (CloudCall call) async {
        methods.add(call.method);
        if (methods.length == 1) {
          return (
            status: 404,
            headers: const <String, String>{},
            body: const <int>[],
          );
        }
        return (
          status: 201,
          headers: const <String, String>{},
          body: const <int>[],
        );
      },
    );
    expect(
      await dav.send(destination, (
        length: 1,
        read: (int _, int _) async => <int>[1],
      ), remoteName: 'a.txt'),
      isA<Success<Uri>>(),
    );
    expect(methods, <String>['PUT', 'MKCOL', 'PUT']);
  });
}
