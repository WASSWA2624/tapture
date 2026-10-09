import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/device/platform_facts.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/capture/data/capture_device_sources.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/templates/domain/domain.dart';

void main() {
  for (final String platform in <String>[
    'android',
    'ios',
    'windows',
    'macos',
    'linux',
  ]) {
    test('$platform chooses the first lexical IPv4 before IPv6', () async {
      final CaptureDeviceSources source = CaptureDeviceSources(
        clock: FixedClock(_now),
        readFacts: () async => PlatformFacts.fake(
          platform: platform,
          addresses: const <String>[
            '2001:db8::1',
            '192.168.2.2',
            '10.2.0.9',
            '10.10.0.3',
          ],
        ),
      );
      addTearDown(source.dispose);
      await _bindRead(source);
      expect(source.snapshot(_session), '10.10.0.3');
    });
  }

  final Map<String, List<String>> unavailable = <String, List<String>>{
    'empty': <String>[],
    'malformed': <String>[
      'not-an-address',
      '1.2.3',
      '256.0.0.1',
      '01.2.3.4',
      '1::2::3',
      '1:2:3',
      ' 10.0.0.1',
    ],
    'unspecified': <String>['0.0.0.0', '::', '0:0:0:0:0:0:0:0'],
    'loopback': <String>['127.0.0.1', '127.2.3.4', '::1', '0:0:0:0:0:0:0:1'],
    'link-local': <String>['169.254.1.2', 'fe80::1', 'febf::1', 'fe80::1%en0'],
    'multicast': <String>['224.0.0.1', '239.1.2.3', 'ff02::1'],
    'reserved IPv4': <String>['255.255.255.255', '240.0.0.1'],
    'mapped ineligible IPv4': <String>[
      '::ffff:127.0.0.1',
      '::ffff:169.254.1.2',
      '::ffff:0.0.0.0',
      '::ffff:224.0.0.1',
    ],
  };
  for (final MapEntry<String, List<String>> entry in unavailable.entries) {
    test('${entry.key} never fabricates an address', () async {
      final CaptureDeviceSources source = CaptureDeviceSources(
        clock: FixedClock(_now),
        readFacts: () async => PlatformFacts.fake(addresses: entry.value),
      );
      addTearDown(source.dispose);
      await _bindRead(source);
      expect(source.snapshot(_session), isNull);
    });
  }

  test(
    'IPv6 lexical order and mapped IPv4 validation keep IPv6 ranking',
    () async {
      final CaptureDeviceSources source = CaptureDeviceSources(
        clock: FixedClock(_now),
        readFacts: () async => const PlatformFacts.fake(
          addresses: <String>['fd00::2', '2001:db8::2', '::ffff:10.0.0.2'],
        ),
      );
      addTearDown(source.dispose);
      await _bindRead(source);
      expect(source.snapshot(_session), '2001:db8::2');
    },
  );

  test(
    'a browser result cannot expose native-looking fake addresses',
    () async {
      final CaptureDeviceSources source = CaptureDeviceSources(
        clock: FixedClock(_now),
        readFacts: () async => const PlatformFacts.fake(
          platform: 'web',
          addresses: <String>['10.0.0.2'],
        ),
      );
      addTearDown(source.dispose);
      await _bindRead(source);
      expect(source.snapshot(_session), isNull);
    },
  );

  test('absent opaque non-text and committed configurations never read', () {
    int reads = 0;
    final CaptureDeviceSources source = CaptureDeviceSources(
      clock: FixedClock(_now),
      readFacts: () async {
        reads += 1;
        return const PlatformFacts.fake(addresses: <String>['10.0.0.2']);
      },
    );
    addTearDown(source.dispose);
    source.bind(_session, const <FieldDef>[]);
    source.refresh();
    source.bind(_session, const <FieldDef>[
      FieldDef(
        fieldKey: 'address',
        label: 'Address',
        type: FieldType.number,
        autoFill: AutoFill.localAddress,
      ),
    ]);
    source.bind(_session, const <FieldDef>[
      FieldDef(
        fieldKey: 'address',
        label: 'Address',
        type: FieldType.text,
        validation: <String, Object?>{
          '_tapture': <String, Object?>{'autoFill': 'UNKNOWN'},
        },
      ),
    ]);
    source.bind(_session.copyWith(recordId: 'saved'), _fields);
    source.bind(_session.copyWith(recordId: 'saved', editing: true), _fields);
    source.bind(_session.copyWith(templateVersion: 0), _fields);
    source.bind(_session.copyWith(templateId: ''), _fields);
    expect(reads, 0);
    expect(source.snapshot(_session), isNull);
  });

  test(
    'pending enumeration is unavailable and exact five-second age expires',
    () async {
      final Completer<PlatformFacts> facts = Completer<PlatformFacts>();
      final _MovingClock clock = _MovingClock(_now);
      final CaptureDeviceSources source = CaptureDeviceSources(
        clock: clock,
        readFacts: () => facts.future,
      );
      addTearDown(source.dispose);
      final Future<void> completed = source.changes.skip(2).first;
      source.bind(_session, _fields);
      expect(source.snapshot(_session), isNull);
      facts.complete(const PlatformFacts.fake(addresses: <String>['10.0.0.2']));
      await completed;
      expect(source.snapshot(_session), '10.0.0.2');
      clock.now = _now.add(AppConstants.capture.deviceReadingFreshness);
      expect(source.snapshot(_session), isNull);
      clock.now = _now.subtract(const Duration(seconds: 1));
      expect(source.snapshot(_session), isNull);
    },
  );

  test(
    'same owner binding preserves its reading while refresh invalidates it',
    () async {
      int reads = 0;
      final Completer<PlatformFacts> refresh = Completer<PlatformFacts>();
      final CaptureDeviceSources source = CaptureDeviceSources(
        clock: FixedClock(_now),
        readFacts: () {
          reads += 1;
          return reads == 1
              ? Future<PlatformFacts>.value(
                  const PlatformFacts.fake(addresses: <String>['10.0.0.2']),
                )
              : refresh.future;
        },
      );
      addTearDown(source.dispose);
      await _bindRead(source);
      source.bind(
        _session.copyWith(values: const <String, Object?>{'manual': 'kept'}),
        _fields,
      );
      expect(reads, 1);
      expect(source.snapshot(_session), '10.0.0.2');
      final Future<void> completed = source.changes.skip(1).first;
      source.refresh();
      expect(reads, 2);
      expect(source.snapshot(_session), isNull);
      refresh.completeError(StateError('unavailable'));
      await completed;
      expect(source.snapshot(_session), isNull);
    },
  );

  for (final String change in <String>[
    'session',
    'template',
    'version',
    'zero-version',
    'project',
    'commit',
    'opt-out',
  ]) {
    test(
      'late $change result cannot become the current draft reading',
      () async {
        final Completer<PlatformFacts> old = Completer<PlatformFacts>();
        final Completer<PlatformFacts> current = Completer<PlatformFacts>();
        int reads = 0;
        final CaptureDeviceSources source = CaptureDeviceSources(
          clock: FixedClock(_now),
          readFacts: () => ++reads == 1 ? old.future : current.future,
        );
        addTearDown(source.dispose);
        source.bind(_session, _fields);
        final CaptureSession next = switch (change) {
          'session' => _session.copyWith(id: 'next'),
          'template' => _session.copyWith(templateId: 'next-template'),
          'version' => _session.copyWith(templateVersion: 2),
          'zero-version' => _session.copyWith(templateVersion: 0),
          'project' => _session.copyWith(projectId: 'next-project'),
          'commit' => _session.copyWith(recordId: 'saved'),
          _ => _session,
        };
        final Future<void> discarded = old.future.then((_) {});
        source.bind(next, change == 'opt-out' ? const <FieldDef>[] : _fields);
        old.complete(const PlatformFacts.fake(addresses: <String>['10.0.0.1']));
        await discarded;
        expect(source.snapshot(_session), isNull);
        expect(source.snapshot(next), isNull);
        if (reads == 2) {
          final Future<void> completed = source.changes.firstWhere(
            (_) => source.snapshot(next) != null,
          );
          current.complete(
            const PlatformFacts.fake(addresses: <String>['10.0.0.2']),
          );
          await completed;
          expect(source.snapshot(next), '10.0.0.2');
          expect(source.snapshot(_session), isNull);
        }
      },
    );
  }
}

Future<void> _bindRead(CaptureDeviceSources source) async {
  final Future<void> completed = source.changes.skip(2).first;
  source.bind(_session, _fields);
  await completed;
}

final DateTime _now = DateTime.utc(2026, 10, 9, 12);
const CaptureSession _session = CaptureSession(
  id: 's1',
  projectId: 'p1',
  templateId: 't1',
  templateVersion: 1,
  contextSnapshot: <String, String>{},
);
const List<FieldDef> _fields = <FieldDef>[
  FieldDef(
    fieldKey: 'address',
    label: 'Address',
    type: FieldType.text,
    autoFill: AutoFill.localAddress,
  ),
];

final class _MovingClock implements Clock {
  _MovingClock(this.now);
  DateTime now;
  @override
  Duration get offset => Duration.zero;
  @override
  DateTime nowUtc() => now;
  @override
  DateTime today() => DateTime.utc(now.year, now.month, now.day);
}
