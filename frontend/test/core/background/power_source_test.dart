import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/background/power_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel battery = MethodChannel(
    'dev.fluttercommunity.plus/battery',
  );
  const EventChannel charging = EventChannel(
    'dev.fluttercommunity.plus/charging',
  );

  TestDefaultBinaryMessenger messenger() {
    return TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  }

  /// The platform's state [now], then [changes]; an exception among them is
  /// a change the platform could not report.
  void platform({required Object? now, List<Object> changes = const []}) {
    messenger().setMockMethodCallHandler(battery, (MethodCall call) async {
      if (now is Exception) {
        throw PlatformException(code: 'unavailable');
      }
      return now;
    });
    messenger().setMockStreamHandler(
      charging,
      MockStreamHandler.inline(
        onListen: (Object? _, MockStreamHandlerEventSink events) {
          for (final Object change in changes) {
            if (change is Exception) {
              events.error(code: 'unavailable');
            } else {
              events.success(change);
            }
          }
          events.endOfStream();
        },
      ),
    );
  }

  tearDown(() {
    messenger().setMockMethodCallHandler(battery, null);
    messenger().setMockStreamHandler(charging, null);
  });

  // The plugin keeps one change stream per process, so a single test
  // covers the platform's changes.
  test('charging and full count, repeats drop, an error is off', () async {
    platform(
      now: 'discharging',
      changes: <Object>[
        'discharging',
        'charging',
        'full',
        'discharging',
        'charging',
        Exception('lost'),
      ],
    );

    expect(await PowerSource().watchCharging().toList(), <bool>[
      false,
      true,
      false,
      true,
      false,
    ]);
  });

  test('a platform that cannot say reads as not charging', () async {
    platform(now: Exception('no battery'));

    expect(await PowerSource().watchCharging().toList(), <bool>[false]);
  });

  test('the fake reports what it is given', () async {
    expect(
      await PowerSource.fake(
        charging: Stream<bool>.fromIterable(<bool>[true, false]),
      ).watchCharging().toList(),
      <bool>[true, false],
    );
  });
}
