import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tapture/core/copy/copy.dart';

/// One local notification when a processing batch finishes.
///
/// Counts and a route only. No field values, no push, no remote service.
/// A refused permission returns without sending and without delaying work.
final class Notifications {
  /// Creates a sender. Tests pass functions so the plugin is never opened.
  Notifications({
    required this._requestPermission,
    required this._show,
  });

  /// The plugin-backed sender. Asks for permission on first use.
  factory Notifications.plugin() {
    final FlutterLocalNotificationsPlugin plugin =
        FlutterLocalNotificationsPlugin();
    var ready = false;
    return Notifications(
      requestPermission: () async {
        if (!ready) {
          await plugin.initialize(
            const InitializationSettings(
              android: AndroidInitializationSettings('@mipmap/ic_launcher'),
              iOS: DarwinInitializationSettings(),
            ),
          );
          ready = true;
        }
        final bool? android = await plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
        return android ?? true;
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
  /// Does nothing when permission is refused.
  Future<void> reportBatch({
    required int succeeded,
    required int failed,
  }) async {
    final bool allowed = await _requestPermission();
    if (!allowed) {
      return;
    }
    await _show(
      title: Copy.processingNotificationTitle,
      body: Copy.processingNotificationBody(succeeded, failed),
      route: reviewRoute,
    );
  }
}
