import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/export/export_record.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/records/domain/record_entry.dart';

import '../test/support/matchers.dart';
import 'support/harness.dart';

void main() {
  test(
    'capture through approval exports the approved values from the database',
    () async {
      final TestApp app = await bootTestApp();
      addTearDown(app.dispose);
      final RecordEntry captured = await app.capture(
        fields: const <String, String>{'serial': 'M-1'},
      );
      final RecordEntry approved = await app.approve(captured.id);
      expect(approved.status, RecordStatus.approved);
      final RecordEntry? rebuilt = valueOf(await app.records.byId(approved.id));
      expect(rebuilt?.valueOf('serial')?.display, 'M-1');
      final String csv = app.csvFor(<ExportRecord>[app.rowOf(approved)]);
      expect(csv.contains('M-1'), isTrue);
      expect(app.outboundCallCount, 0);
    },
  );
}
