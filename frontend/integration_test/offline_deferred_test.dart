import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/export/export_record.dart';
import 'package:tapture/features/records/domain/record_entry.dart';
import 'package:tapture/features/records/domain/record_repository.dart';

import '../test/support/matchers.dart';
import 'support/harness.dart';

void main() {
  test(
    'forty offline saves stay durable and match an immediate export',
    () async {
      final TestApp deferred = await bootTestApp();
      final TestApp immediate = await bootTestApp();
      addTearDown(deferred.dispose);
      addTearDown(immediate.dispose);
      deferred.backend.markUnreachable();
      final List<RecordEntry> saved = <RecordEntry>[];
      for (var index = 0; index < 40; index++) {
        saved.add(
          await deferred.capture(
            fields: <String, String>{'serial': 'S-$index'},
          ),
        );
      }
      expect(deferred.outboundCallCount, 0);
      expect(saved, hasLength(40));
      expect(
        valueOf(
          await deferred.records.byId(saved.first.id),
        )?.valueOf('serial')?.raw,
        'S-0',
      );
      for (final RecordEntry entry in saved) {
        valueOf(
          await deferred.records.editValues(entry.id, <RecordValueEdit>[
            (fieldKey: 'serial', value: 'R-${entry.valueOf('serial')?.raw}'),
          ]),
        );
      }
      final RecordEntry? refined = valueOf(
        await deferred.records.byId(saved.first.id),
      );
      expect(refined?.valueOf('serial')?.raw, 'S-0');
      expect(refined?.valueOf('serial')?.display, 'R-S-0');

      final List<ExportRecord> immediateRows = <ExportRecord>[];
      for (var index = 0; index < 40; index++) {
        final RecordEntry captured = await immediate.capture(
          fields: <String, String>{'serial': 'S-$index'},
        );
        valueOf(
          await immediate.records.editValues(captured.id, <RecordValueEdit>[
            (fieldKey: 'serial', value: 'R-S-$index'),
          ]),
        );
        immediateRows.add(
          immediate.rowOf(valueOf(await immediate.records.byId(captured.id))!),
        );
      }
      final List<ExportRecord> deferredRows = <ExportRecord>[
        for (final RecordEntry entry in saved)
          deferred.rowOf(valueOf(await deferred.records.byId(entry.id))!),
      ];
      expect(deferred.csvFor(deferredRows), immediate.csvFor(immediateRows));
      expect(deferred.outboundCallCount, 0);
    },
  );
}
