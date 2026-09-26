import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/features/processing/data/notifications.dart';

import '../../../support/fakes/fake_notifications.dart';

void main() {
  test('one notification carries counts and the review route', () async {
    final FakeNotifications platform = FakeNotifications();

    await platform.notifications.reportBatch(succeeded: 4, failed: 1);

    expect(platform.permissionRequests, 1);
    expect(platform.shown, hasLength(1));
    expect(platform.shown.single.title, Copy.processingNotificationTitle);
    expect(platform.shown.single.body, Copy.processingNotificationBody(4, 1));
    expect(platform.shown.single.route, Notifications.reviewRoute);
  });

  test('each batch sends exactly one notification', () async {
    final FakeNotifications platform = FakeNotifications();

    await platform.notifications.reportBatch(succeeded: 3, failed: 0);
    await platform.notifications.reportBatch(succeeded: 0, failed: 2);

    expect(platform.shown.map((s) => s.body), <String>[
      Copy.processingNotificationBody(3, 0),
      Copy.processingNotificationBody(0, 2),
    ]);
  });

  test('a tap opens the records list filtered to review', () {
    final Uri route = Uri.parse(Notifications.reviewRoute);

    expect(route.path, RoutePaths.records);
    expect(route.queryParameters, <String, String>{'filter': 'needsReview'});
  });

  test('the message holds counts only, never a value', () async {
    final FakeNotifications platform = FakeNotifications();

    await platform.notifications.reportBatch(succeeded: 12, failed: 3);

    final String shown =
        '${platform.shown.single.title} '
        '${platform.shown.single.body}';
    expect(RegExp(r'\d+').allMatches(shown).map((m) => m.group(0)), <String>[
      '12',
      '3',
    ]);
  });

  test('a refused permission sends nothing', () async {
    final FakeNotifications platform = FakeNotifications(granted: false);

    await platform.notifications.reportBatch(succeeded: 1, failed: 0);

    expect(platform.shown, isEmpty);
  });

  test('a platform that fails is not an error for the batch', () async {
    final FakeNotifications platform = FakeNotifications(failing: true);

    await expectLater(
      platform.notifications.reportBatch(succeeded: 1, failed: 0),
      completes,
    );
    expect(platform.shown, isEmpty);
  });
}
