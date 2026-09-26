import 'dart:async';

import 'package:tapture/features/processing/data/notifications.dart';

/// A notification platform that records what it would show.
///
/// [notifications] is the real [Notifications] over this platform, so a test
/// exercises the same permission and message rules the app does.
final class FakeNotifications {
  /// Creates the platform. [granted] answers the permission prompt; when
  /// [prompt] is set, the prompt waits on it instead.
  FakeNotifications({this.granted = true, this.prompt, this.failing = false});

  /// The answer to the permission prompt.
  bool granted;

  /// When set, the permission prompt resolves only when this completes.
  final Completer<bool>? prompt;

  /// When true, showing a notification throws, as a broken platform would.
  final bool failing;

  /// How many times permission was asked for.
  int permissionRequests = 0;

  /// Every notification shown, in order.
  final List<({String title, String body, String route})> shown =
      <({String title, String body, String route})>[];

  /// The sender over this platform.
  late final Notifications notifications = Notifications(
    requestPermission: () {
      permissionRequests++;
      return prompt?.future ?? Future<bool>.value(granted);
    },
    show:
        ({
          required String title,
          required String body,
          required String route,
        }) async {
          if (failing) {
            throw StateError('The notification platform is unavailable.');
          }
          shown.add((title: title, body: body, route: route));
        },
  );
}
