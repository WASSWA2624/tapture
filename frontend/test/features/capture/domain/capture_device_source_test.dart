import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/device/platform_facts.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/capture/data/capture_device_sources.dart';
import 'package:tapture/features/capture/domain/capture_device_source.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/templates/domain/domain.dart';

void main() {
  test(
    'the typed port closes events and refuses a late sample after disposal',
    () async {
      final Completer<PlatformFacts> facts = Completer<PlatformFacts>();
      int reads = 0;
      final CaptureDeviceSource source = CaptureDeviceSources(
        clock: FixedClock(DateTime.utc(2026, 10, 9)),
        readFacts: () {
          reads += 1;
          return facts.future;
        },
      );
      final List<String?> snapshots = <String?>[];
      final StreamSubscription<void> events = source.changes.listen((_) {
        snapshots.add(source.snapshot(_session));
      });
      final Future<void> closed = source.changes.drain<void>();
      source.bind(_session, _fields);
      expect(reads, 1);
      source.dispose();
      source.dispose();
      await closed;
      final int before = snapshots.length;
      facts.complete(const PlatformFacts.fake(addresses: <String>['10.0.0.1']));
      await facts.future;
      source.refresh();
      source.bind(_session, _fields);
      expect(reads, 1);
      expect(source.snapshot(_session), isNull);
      expect(snapshots, everyElement(isNull));
      expect(snapshots.length, before);
      await events.cancel();
    },
  );
}

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
