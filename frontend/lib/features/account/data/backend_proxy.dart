import 'dart:convert';

import 'package:tapture/core/ai/ai_media_reader.dart';
import 'package:tapture/core/ai/proxy_ai_service.dart';
import 'package:tapture/core/backend/backend_session.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/failure.dart';

import '../domain/role_gate.dart';

/// The default AI provider: the organisation's proxy, reached through this
/// device's [session], so a fresh install extracts with no key ever entered
/// on the device (§30.2, §73.1).
///
/// It is offered only while the cached grant is live, the organisation
/// reports a configured provider, and [mayUseProxy] allows the project; the
/// server authorises and bills every call again. [media] supplies the bytes
/// of photos and clips without sending their file names.
ProxyAiService backendProxy(
  BackendSession session,
  AiMediaReader media, {
  double? Function()? readMaxCost,
}) {
  return ProxyAiService(
    baseUrl: session.config.baseUrl,
    available: () => session.canUseBackend,
    projectAllowed: (String projectId) =>
        mayUseProxy(session.config, projectId),
    readBytes: media.read,
    readMaxCost: readMaxCost,
    send: ({required String path, required Map<String, Object?> json}) =>
        _sendProxy(session, path: path, json: json),
    sendCancellable:
        ({
          required String path,
          required Map<String, Object?> json,
          CancellationToken? cancellationToken,
        }) => _sendProxy(
          session,
          path: path,
          json: json,
          cancel: cancellationToken,
        ),
  );
}

Future<({int status, String body})> _sendProxy(
  BackendSession session, {
  required String path,
  required Map<String, Object?> json,
  CancellationToken? cancel,
}) async {
  var response = await session.send(
    method: 'POST',
    path: path,
    body: json,
    cancellationToken: cancel,
  );
  if (cancel?.isCancelled == true) throw const CancelledFailure();
  final Object? projectId = json['projectId'];
  if (response.status == 404 &&
      projectId is String &&
      await _register(session, projectId)) {
    if (cancel?.isCancelled == true) throw const CancelledFailure();
    response = await session.send(
      method: 'POST',
      path: path,
      body: json,
      cancellationToken: cancel,
    );
  }
  return (status: response.status, body: jsonEncode(response.body));
}

/// Registers [projectId] on the server when the signed-in role may create
/// projects, then refreshes the grant so the cached authority includes it.
///
/// Only the identifier travels: no name, record or template content. A 404
/// means the project is registered to people this account does not work
/// with, so the proxy stays unavailable for it and the caller's 404 stands.
Future<bool> _register(BackendSession session, String projectId) async {
  if (roleGateFor(session.config)?.allows(RoleCapability.manageProject) !=
      true) {
    return false;
  }
  final ({int status, Map<String, Object?> body}) registered = await session
      .send(
        method: 'POST',
        path: '/api/v1/projects',
        body: <String, Object?>{'id': projectId, 'name': projectId},
      );
  if (registered.status != 200 && registered.status != 201) {
    return false;
  }
  await session.refresh();
  return true;
}
