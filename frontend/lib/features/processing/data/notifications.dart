import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tapture/core/copy/copy.dart';

/// One local notification when a processing batch finishes.
///
/// Counts and a route only. No field values, no push, no remote service.
/// A refused permission returns without sending and without delaying work.
final class Notifications {
  /// Creates a sender. Tests pass functions so the plugin is never opened.
  Notifications({required this._requestPermission, required this._show});

  /// A no-op boundary for tests and hosts without local notifications.
  factory Notifications.silent() {
    return Notifications(
      requestPermission: () async => false,
      show:
          ({
            required String title,
            required String body,
            required String route,
          }) async {},
    );
  }

  /// The plugin-backed sender. Asks for permission on first use.
  factory Notifications.plugin({void Function(String route)? onTap}) {
    final FlutterLocalNotificationsPlugin plugin =
        FlutterLocalNotificationsPlugin();
    var ready = false;
    bool? permissionGranted;
    return Notifications(
      requestPermission: () async {
        final bool? existing = permissionGranted;
        if (existing != null) {
          return existing;
        }
        if (!ready) {
          await plugin.initialize(
            const InitializationSettings(
              android: AndroidInitializationSettings('@mipmap/ic_launcher'),
              iOS: DarwinInitializationSettings(
                requestAlertPermission: false,
                requestSoundPermission: false,
                requestBadgePermission: false,
              ),
              macOS: DarwinInitializationSettings(
                requestAlertPermission: false,
                requestSoundPermission: false,
                requestBadgePermission: false,
              ),
            ),
            onDidReceiveNotificationResponse: (NotificationResponse response) {
              final String? route = response.payload;
              if (route != null && route.isNotEmpty) {
                onTap?.call(route);
              }
            },
          );
          ready = true;
        }
        final bool? android = await plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
        final bool? ios = await plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        final bool? macos = await plugin
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        permissionGranted = android ?? ios ?? macos ?? true;
        return permissionGranted!;
      },
      show:
          ({
            required String title,
            required String body,
            required String route,
          }) {
            return plugin.show(
              1,
              title,
              body,
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'processing',
                  'Processing',
                  channelDescription: 'When a processing batch finishes',
                ),
                iOS: DarwinNotificationDetails(),
              ),
              payload: route,
            );
          },
    );
  }

  /// Opens the review list. Counts only; never a field value.
  static const String reviewRoute = '/records?filter=needsReview';

  final Future<bool> Function() _requestPermission;
  final Future<void> Function({
    required String title,
    required String body,
    required String route,
  })
  _show;

  /// Sends one notification for a finished batch.
  ///
  /// Does nothing when permission is refused or the platform fails, and
  /// never throws.
  Future<void> reportBatch({
    required int succeeded,
    required int failed,
  }) async {
    try {
      final bool allowed = await _requestPermission();
      if (!allowed) {
        return;
      }
      await _show(
        title: Copy.processingNotificationTitle,
        body: Copy.processingNotificationBody(succeeded, failed),
        route: reviewRoute,
      );
    } on Object {
      // A notification is a courtesy. A platform that cannot show one
      // changes nothing about the batch it reports.
      return;
    }
  }
}
