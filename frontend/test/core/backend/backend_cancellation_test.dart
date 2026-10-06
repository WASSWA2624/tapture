import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/backend/backend_session.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/security/secure_storage.dart';
import 'package:tapture/core/time/clock.dart';

void main() {
  test(
    'cancelled authenticated call does not refresh or retain token listeners',
    () async {
      final DateTime now = DateTime.utc(2026, 10, 6);
      final Completer<({int status, Map<String, Object?> body})> response =
          Completer<({int status, Map<String, Object?> body})>();
      var calls = 0;
      final BackendSession session = BackendSession(
        storage: SecureStorage.fake(
          backing: <SecretKey, String>{
            SecretKey.backendSession: jsonEncode(<String, Object?>{
              'baseUrl': 'https://organisation.test',
              'accessToken': 'fixture-access',
              'refreshToken': 'fixture-refresh',
              'grantValidUntil': now
                  .add(const Duration(days: 1))
                  .toIso8601String(),
            }),
          },
        ),
        clock: FixedClock(now),
        deviceId: 'device',
        send:
            ({
              required String method,
              required String path,
              Map<String, Object?>? body,
              String? token,
            }) {
              calls++;
              return response.future;
            },
      );
      await session.restore();
      final CancellationToken cancel = CancellationToken();
      final Future<({int status, Map<String, Object?> body})> pending = session
          .send(
            method: 'POST',
            path: '/api/v1/ai/extract',
            cancellationToken: cancel,
          );
      final Future<void> assertion = expectLater(
        pending,
        throwsA(isA<CancelledFailure>()),
      );
      cancel.cancel();
      await assertion;
      response.complete((status: 401, body: <String, Object?>{}));
      expect(calls, 1);
      expect(cancel.debugListenerCount, 0);
      await session.dispose();
    },
  );
}
