import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:url_launcher/url_launcher.dart';

import 'cloud_oauth_redirect.dart';
import 'cloud_request_scope.dart';

int _liveListeners = 0;

/// Actual bound listeners, so tests verify socket ownership after completion.
@visibleForTesting
int get debugLiveCloudSignInListeners => _liveListeners;

/// One desktop authorization through an external browser and a local callback.
final class DesktopCloudSignIn {
  /// Production launches the system browser; tests supply only that OS seam.
  DesktopCloudSignIn({
    Future<bool> Function(Uri uri)? launch,
    Duration? timeout,
  }) : _launch = launch ?? _launchExternal,
       _timeout = timeout ?? AppConstants.cloudUpload.signInTimeout;

  final Future<bool> Function(Uri uri) _launch;
  final Duration _timeout;
  bool _active = false;

  /// Binds only the configured loopback IP, validates state, and always closes.
  Future<Result<Uri>> signIn(
    Uri authorize,
    Uri redirect, {
    CancellationToken? cancel,
  }) async {
    final CancellationToken? token = cancel ?? CloudRequestScope.current.cancel;
    if (token?.isCancelled ?? false) {
      return const FailureResult<Uri>(CancelledFailure());
    }
    final Map<String, List<String>> fields = authorize.queryParametersAll;
    final List<String>? states = fields['state'];
    if (_active ||
        !CloudOauthRedirect.isLoopback(redirect) ||
        authorize.scheme != 'https' ||
        authorize.userInfo.isNotEmpty ||
        authorize.hasFragment ||
        authorize.host.isEmpty ||
        states == null ||
        states.length != 1 ||
        states.single.isEmpty ||
        fields['redirect_uri']?.length != 1 ||
        fields['redirect_uri']?.single != redirect.toString() ||
        fields['response_type']?.length != 1 ||
        fields['response_type']?.single != 'code' ||
        fields['code_challenge_method']?.length != 1 ||
        fields['code_challenge_method']?.single != 'S256' ||
        fields['code_challenge']?.length != 1 ||
        fields['code_challenge']?.single.isEmpty != false) {
      return FailureResult<Uri>(_failed);
    }
    _active = true;
    HttpServer? server;
    StreamSubscription<HttpRequest>? requests;
    Timer? deadline;
    void Function()? detach;
    final Completer<Result<Uri>> answer = Completer<Result<Uri>>();
    void complete(Result<Uri> result) {
      if (!answer.isCompleted) {
        answer.complete(result);
      }
    }

    try {
      detach = token?.register(
        () => complete(const FailureResult<Uri>(CancelledFailure())),
      );
      deadline = Timer(_timeout, () => complete(FailureResult<Uri>(_failed)));
      final Future<HttpServer> binding = HttpServer.bind(
        InternetAddress(redirect.host),
        redirect.port,
        shared: false,
      );
      // If cancellation/timeout wins binding, its late socket is still owned.
      bool accepted = false;
      unawaited(
        binding.then<void>(
          (HttpServer late) async {
            if (!accepted && answer.isCompleted) {
              try {
                await late.close(force: true);
              } on Object {
                /* The unaccepted socket may already be closed. */
              }
            }
          },
          onError: (Object _) {
            complete(FailureResult<Uri>(_failed));
          },
        ),
      );
      final Object bound = await Future.any<Object>(<Future<Object>>[
        binding,
        answer.future,
      ]);
      if (bound is Result<Uri>) {
        return bound;
      }
      server = bound as HttpServer;
      accepted = true;
      _liveListeners++;
      if (answer.isCompleted) {
        return await answer.future;
      }
      server.idleTimeout = _timeout;
      final Uri actual = redirect.replace(port: server.port);
      final String host =
          '${actual.host.contains(':') ? '[${actual.host}]' : actual.host}:${server.port}';
      int received = 0;
      requests = server.listen((HttpRequest request) {
        if (++received > AppConstants.cloudUpload.signInMaxCallbacks) {
          complete(FailureResult<Uri>(_failed));
          unawaited(
            _reply(
              request,
              HttpStatus.tooManyRequests,
            ).catchError((Object _) {}),
          );
          return;
        }
        unawaited(_receive(request, actual, host, states.single, complete));
      }, onError: (Object _) => complete(FailureResult<Uri>(_failed)));
      final Uri browserUrl = authorize.replace(
        queryParameters: <String, String>{
          ...authorize.queryParameters,
          'redirect_uri': actual.toString(),
        },
      );
      // A stalled OS launcher cannot outlive the overall timeout/cancellation.
      unawaited(
        _launch(browserUrl).then<void>((bool launched) {
          if (!launched) {
            complete(FailureResult<Uri>(_failed));
          }
        }, onError: (Object _) => complete(FailureResult<Uri>(_failed))),
      );
      return await answer.future;
    } on Object {
      return token?.isCancelled ?? false
          ? const FailureResult<Uri>(CancelledFailure())
          : FailureResult<Uri>(_failed);
    } finally {
      deadline?.cancel();
      detach?.call();
      if (server != null) {
        await server.close(force: true);
        _liveListeners--;
      }
      await requests?.cancel();
      _active = false;
    }
  }

  Future<void> _receive(
    HttpRequest request,
    Uri redirect,
    String expectedHost,
    String expectedState,
    void Function(Result<Uri>) complete,
  ) async {
    try {
      final Uri uri = request.uri;
      if (request.method != 'GET' ||
          uri.hasAuthority ||
          uri.hasFragment ||
          request.connectionInfo?.remoteAddress.isLoopback != true ||
          request.headers.value(HttpHeaders.hostHeader) != expectedHost ||
          uri.path != (redirect.path.isEmpty ? '/' : redirect.path) ||
          uri.query.length > AppConstants.cloudUpload.signInCallbackMaxBytes ||
          request.contentLength > 0) {
        await _reply(request, HttpStatus.forbidden);
        return;
      }
      final Map<String, List<String>> fields = uri.queryParametersAll;
      final List<String>? states = fields['state'];
      final List<String>? codes = fields['code'];
      final List<String>? errors = fields['error'];
      final bool valid =
          states?.length == 1 &&
          states!.single == expectedState &&
          ((codes?.length == 1 && codes!.single.isNotEmpty && errors == null) ||
              (errors?.length == 1 && codes == null));
      if (!valid) {
        await _reply(request, HttpStatus.forbidden);
        return;
      }
      await _reply(request, HttpStatus.ok);
      if (errors != null) {
        complete(
          errors.single == 'access_denied'
              ? const FailureResult<Uri>(CancelledFailure())
              : FailureResult<Uri>(_failed),
        );
      } else {
        complete(Success<Uri>(redirect.replace(query: uri.query)));
      }
    } on Object {
      // Malformed input cannot complete an authorization or echo provider data.
      try {
        await _reply(request, HttpStatus.forbidden);
      } on Object {
        /* The peer may already have closed. */
      }
    }
  }

  Future<void> _reply(HttpRequest request, int status) async {
    request.response
      ..statusCode = status
      ..headers.contentType = ContentType.text
      ..headers.set(HttpHeaders.cacheControlHeader, 'no-store')
      ..headers.set('Referrer-Policy', 'no-referrer')
      ..headers.set('X-Content-Type-Options', 'nosniff')
      ..headers.set(
        'Content-Security-Policy',
        "default-src 'none'; frame-ancestors 'none'",
      )
      ..contentLength = 0;
    await request.response.close();
  }

  static Future<bool> _launchExternal(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
}

final PermissionFailure _failed = PermissionFailure(
  localizedMessage: Copy.messages.failureCloudSignInCouldNotFinish,
  localizedRecovery: Copy.messages.failureTrySigningInAgain,
);
