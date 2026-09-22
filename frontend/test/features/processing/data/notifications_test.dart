import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/features/processing/data/notifications.dart';

void main() {
  test('one notification carries counts and the review route', () async {
    final List<({String title, String body, String route})> sent =
        <({String title, String body, String route})>[];
    var asked = 0;
    final Notifications notifications = Notifications(
      requestPermission: () async {
        asked++;
        return true;
      },
      show:
          ({
            required String title,
            required String body,
            required String route,
          }) async {
            sent.add((title: title, body: body, route: route));
          },
    );
    await notifications.reportBatch(succeeded: 4, failed: 1);
    expect(asked, 1);
    expect(sent, hasLength(1));
    expect(sent.single.body, Copy.processingNotificationBody(4, 1));
    expect(sent.single.route, Notifications.reviewRoute);
    expect(sent.single.body.contains('serial'), isFalse);
  });

  test('a refused permission sends nothing', () async {
    var shown = 0;
    final Notifications notifications = Notifications(
      requestPermission: () async => false,
      show:
          ({
            required String title,
            required String body,
            required String route,
          }) async {
            shown++;
          },
    );
    await notifications.reportBatch(succeeded: 1, failed: 0);
    expect(shown, 0);
  });
}
